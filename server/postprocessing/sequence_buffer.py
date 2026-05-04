"""
Rolling buffer of per-frame feature vectors for LSTM inference.

The LSTM expects a fixed (target_len, feature_dim) tensor. We keep a deque of the
most recent feature vectors and stack them on demand.
"""
from collections import deque
from typing import Optional

import numpy as np


class SequenceFeatureBuffer:
    """Fixed-size FIFO of feature vectors.

    Ready once min_frames have been collected. get_window() pads shorter
    sequences with zeros so the LSTM always receives (target_len, feature_dim).
    """

    def __init__(self, target_len: int = 30, feature_dim: int = 85, min_frames: int = 10):
        self.target_len = target_len
        self.feature_dim = feature_dim
        self.min_frames = min(min_frames, target_len)
        self._buf = deque(maxlen=target_len)

    def push(self, features: Optional[np.ndarray]) -> None:
        if features is None:
            return
        if features.shape != (self.feature_dim,):
            return
        self._buf.append(features.astype(np.float32))

    def is_ready(self) -> bool:
        return len(self._buf) >= self.min_frames

    def get_window(self) -> Optional[np.ndarray]:
        if not self.is_ready():
            return None
        frames = list(self._buf)
        n = len(frames)
        if n >= self.target_len:
            return np.stack(frames, axis=0)                     # (target_len, feature_dim)
        # Pad with zeros at the start (pre-padding keeps recent frames at the end)
        padded = np.zeros((self.target_len, self.feature_dim), dtype=np.float32)
        padded[self.target_len - n:] = np.stack(frames, axis=0)
        return padded

    def clear(self) -> None:
        self._buf.clear()

    def __len__(self) -> int:
        return len(self._buf)
