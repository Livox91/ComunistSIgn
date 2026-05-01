"""
TFLite-based ASL alphabet classifier.
Drop-in replacement for HeuristicClassifier — same `classify(landmarks)` signature,
takes raw MediaPipe landmark dicts and returns a letter (or 'Unknown' if low confidence).
"""
import pickle
from pathlib import Path
from typing import Dict, List

import numpy as np
import tensorflow as tf

from classification.base import GestureClassifier


class TFLiteAlphabetClassifier(GestureClassifier):
    """
    Loads the trained alphabet TFLite model and its label encoder.
    Accepts raw landmark dicts (compat with the existing heuristic call site)
    and returns a letter A-Z, SPACE, or DELETE — or 'Unknown' below threshold.
    """

    def __init__(self, model_path: str, label_encoder_path: str, confidence_threshold: float = 0.6):
        model_path = Path(model_path)
        label_encoder_path = Path(label_encoder_path)
        if not model_path.exists():
            raise FileNotFoundError(f"TFLite model not found: {model_path}")
        if not label_encoder_path.exists():
            raise FileNotFoundError(f"Label encoder not found: {label_encoder_path}")

        self.interpreter = tf.lite.Interpreter(model_path=str(model_path))
        self.interpreter.allocate_tensors()
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()

        with open(label_encoder_path, "rb") as f:
            enc = pickle.load(f)
        self.idx_to_label: Dict[int, str] = enc["idx_to_label"]

        self.confidence_threshold = confidence_threshold

    def classify(self, landmarks: List[Dict]) -> str:
        """Raw landmark dicts → letter or 'Unknown'."""
        features = self._normalize(landmarks)
        return self._predict(features)

    @staticmethod
    def _normalize(landmarks: List[Dict]) -> np.ndarray:
        """Wrist-relative + unit-scaled, matching training-time preprocessing."""
        coords = np.array([[lm["x"], lm["y"], lm["z"]] for lm in landmarks], dtype=np.float32)
        wrist = coords[0].copy()
        coords -= wrist
        max_d = np.linalg.norm(coords, axis=1).max()
        if max_d > 0:
            coords /= max_d
        return coords.flatten()  # (63,)

    def _predict(self, features: np.ndarray) -> str:
        x = features.astype(np.float32).reshape(1, -1)
        self.interpreter.set_tensor(self.input_details[0]["index"], x)
        self.interpreter.invoke()
        probs = self.interpreter.get_tensor(self.output_details[0]["index"])[0]
        idx = int(np.argmax(probs))
        confidence = float(probs[idx])
        if confidence < self.confidence_threshold:
            return "Unknown"
        return self.idx_to_label[idx]
