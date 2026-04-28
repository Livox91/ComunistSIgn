import numpy as np
from typing import List, Dict, Optional


class LandmarkNormalizer:
    """
    Normalizes raw MediaPipe landmarks:
      1. Translate so wrist (landmark 0) is at origin
      2. Scale so max distance from wrist = 1.0
      3. Optionally append per-landmark velocity (delta from previous frame)
    """

    def __init__(self):
        self._prev_coords: Optional[np.ndarray] = None

    def normalize(self, landmarks: List[Dict], include_velocity: bool = False) -> np.ndarray:
        """
        Returns:
          - (63,)  if include_velocity=False  — position only
          - (126,) if include_velocity=True   — position (63) + velocity (63)
        """
        wrist = np.array([landmarks[0]["x"], landmarks[0]["y"], landmarks[0]["z"]])
        coords = np.array([[lm["x"], lm["y"], lm["z"]] for lm in landmarks])
        coords -= wrist
        max_dist = np.max(np.linalg.norm(coords, axis=1))
        if max_dist > 0:
            coords /= max_dist

        position = coords.flatten()  # (63,)

        if not include_velocity:
            self._prev_coords = coords
            return position

        if self._prev_coords is not None:
            velocity = (coords - self._prev_coords).flatten()
        else:
            velocity = np.zeros(63)

        self._prev_coords = coords
        return np.concatenate([position, velocity])  # (126,)

    def reset(self):
        """Call when switching users or starting a new session."""
        self._prev_coords = None
