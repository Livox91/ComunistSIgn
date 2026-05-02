"""
LSTM-based ASL phrase classifier.

Loads the trained phrase model + label encoder, takes a fixed-length feature
sequence (target_len × feature_dim), and returns top-k predictions with probabilities.
"""
import pickle
from pathlib import Path
from typing import Dict, List, Tuple

import numpy as np
import tensorflow as tf


class LSTMPhraseClassifier:
    """Wraps the phrase TFLite model. Returns top-k (label, probability) tuples."""

    def __init__(
        self,
        model_path: str,
        label_encoder_path: str,
        target_len: int = 30,
        feature_dim: int = 85,
    ):
        model_path = Path(model_path)
        label_encoder_path = Path(label_encoder_path)
        if not model_path.exists():
            raise FileNotFoundError(f"LSTM model not found: {model_path}")
        if not label_encoder_path.exists():
            raise FileNotFoundError(f"Phrase label encoder not found: {label_encoder_path}")

        self.target_len = target_len
        self.feature_dim = feature_dim

        self.interpreter = tf.lite.Interpreter(model_path=str(model_path))
        # The exported graph has a flexible batch dim; pin it so LSTM cell allocations
        # are correct on the first call.
        in_idx = self.interpreter.get_input_details()[0]["index"]
        self.interpreter.resize_tensor_input(in_idx, [1, target_len, feature_dim])
        self.interpreter.allocate_tensors()
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()

        with open(label_encoder_path, "rb") as f:
            enc = pickle.load(f)
        self.idx_to_label: Dict[int, str] = enc["idx_to_label"]

    def classify_top_k(self, sequence: np.ndarray, k: int = 3) -> List[Tuple[str, float]]:
        """
        Args:
            sequence: float32 array of shape (target_len, feature_dim).
            k: how many top predictions to return.

        Returns:
            List of (label, probability), sorted high → low.
        """
        if sequence.shape != (self.target_len, self.feature_dim):
            raise ValueError(
                f"Expected sequence shape ({self.target_len}, {self.feature_dim}), "
                f"got {sequence.shape}"
            )
        x = sequence.astype(np.float32).reshape(1, self.target_len, self.feature_dim)
        self.interpreter.set_tensor(self.input_details[0]["index"], x)
        self.interpreter.invoke()
        probs = self.interpreter.get_tensor(self.output_details[0]["index"])[0]
        top_idx = np.argsort(probs)[::-1][:k]
        return [(self.idx_to_label[int(i)], float(probs[int(i)])) for i in top_idx]
