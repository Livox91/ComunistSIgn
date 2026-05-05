"""
Rolling buffer of per-frame feature vectors for LSTM inference.

Accepts 85-d base features from BodyFrameNormalizer and appends 42-d velocity
(Δx, Δy for all 21 hand landmarks) to produce 127-d stored vectors, matching
the training-time feature layout:
    [0:85)   base body-frame features (hand shape + wrist + face + elbows)
    [85:127) hand landmark velocity (21 × Δx,Δy from previous frame)

The LSTM expects a fixed (target_len, 127) tensor. get_window() pre-pads shorter
sequences with zeros so the LSTM always receives the full window.
"""
from collections import deque
from typing import Optional

import numpy as np

# x,y component indices within the 63-d hand shape block (21 lm × 3 coords).
_HAND_XY_IDX = np.array([i * 3 + j for i in range(21) for j in range(2)])  # (42,)

BASE_FEATURE_DIM = 85
VELOCITY_DIM = len(_HAND_XY_IDX)   # 42
STORED_FEATURE_DIM = BASE_FEATURE_DIM + VELOCITY_DIM  # 127


class SequenceFeatureBuffer:
    """Fixed-size FIFO that stores (base + velocity) feature vectors.

    push() accepts 85-d base features, appends 42-d velocity, and stores 127-d.
    Ready once min_frames have been collected. get_window() pre-pads shorter
    sequences with zeros so the LSTM always receives (target_len, 127).
    """

    def __init__(self, target_len: int = 45, feature_dim: int = STORED_FEATURE_DIM,
                 min_frames: int = 12):
        self.target_len = target_len
        self.feature_dim = feature_dim
        self.min_frames = min(min_frames, target_len)
        self._buf: deque = deque(maxlen=target_len)
        self._prev_hand_xy: Optional[np.ndarray] = None

    def push(self, features: Optional[np.ndarray]) -> None:
        """Accept an 85-d base feature vector, compute velocity, store 127-d."""
        if features is None:
            return
        if features.shape != (BASE_FEATURE_DIM,):
            return
        features = features.astype(np.float32)

        curr_hand_xy = features[_HAND_XY_IDX]
        velocity = (curr_hand_xy - self._prev_hand_xy
                    if self._prev_hand_xy is not None
                    else np.zeros(VELOCITY_DIM, dtype=np.float32))
        self._prev_hand_xy = curr_hand_xy

        self._buf.append(np.concatenate([features, velocity]))

    def is_ready(self) -> bool:
        return len(self._buf) >= self.min_frames

    def get_window(self) -> Optional[np.ndarray]:
        if not self.is_ready():
            return None
        frames = list(self._buf)
        n = len(frames)
        if n >= self.target_len:
            return np.stack(frames, axis=0)
        padded = np.zeros((self.target_len, self.feature_dim), dtype=np.float32)
        padded[self.target_len - n:] = np.stack(frames, axis=0)
        return padded

    def clear(self) -> None:
        self._buf.clear()
        self._prev_hand_xy = None

    def __len__(self) -> int:
        return len(self._buf)
