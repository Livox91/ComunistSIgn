"""
Rolling buffer of per-frame feature vectors for LSTM inference.

The LSTM expects a fixed (target_len, feature_dim) tensor. We keep a deque of the
most recent feature vectors and stack them on demand.
"""
from collections import deque
from typing import Optional

import numpy as np


class SequenceFeatureBuffer:
    """Fixed-size FIFO of feature vectors. Ready when full."""

    def __init__(self, target_len: int = 30, feature_dim: int = 85):
        self.target_len = target_len
        self.feature_dim = feature_dim
        self._buf = deque(maxlen=target_len)

    def push(self, features: Optional[np.ndarray]) -> None:
        if features is None:
            return
        if features.shape != (self.feature_dim,):
            return
        self._buf.append(features.astype(np.float32))

    def is_ready(self) -> bool:
        return len(self._buf) == self.target_len

    def get_window(self) -> Optional[np.ndarray]:
        if not self.is_ready():
            return None
        return np.stack(list(self._buf), axis=0)  # (target_len, feature_dim)

    def clear(self) -> None:
        self._buf.clear()

    def __len__(self) -> int:
        return len(self._buf)
