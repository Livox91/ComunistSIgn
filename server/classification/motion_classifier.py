"""
Motion-based gesture classifier for J and Z.

DIP concept: Optical flow / motion estimation — tracking the displacement
of feature points (landmark positions) across consecutive frames to detect
temporal patterns. This is a classical DIP technique for motion analysis,
applied here to landmark trajectories rather than raw pixel patches.

J = pinky extended, all others curled, tracing a downward arc.
Z = index finger extended, tracing a zigzag (right → left-down → right).
"""
import numpy as np
from collections import deque
from typing import Optional, List, Dict


class MotionClassifier:
    """
    Detects J and Z by tracking the index fingertip (landmark 8)
    and pinky fingertip (landmark 20) across consecutive frames
    using simplified optical flow on landmark positions.
    """

    def __init__(self, history_size: int = 15, min_frames: int = 8):
        self.history_size = history_size
        self.min_frames = min_frames  # minimum frames to attempt classification
        self.index_history = deque(maxlen=history_size)  # landmark 8 positions
        self.pinky_history = deque(maxlen=history_size)  # landmark 20 positions
        self.finger_states_history = deque(maxlen=history_size)  # which fingers are up

    def update(self, landmarks: List[Dict], finger_states: Dict[str, bool]):
        """Call every frame with current landmarks and finger extension states."""
        self.index_history.append((landmarks[8]['x'], landmarks[8]['y']))
        self.pinky_history.append((landmarks[20]['x'], landmarks[20]['y']))
        self.finger_states_history.append(finger_states)

    def classify(self) -> Optional[str]:
        """Returns 'J', 'Z', or None if no motion letter detected."""
        if len(self.index_history) < self.min_frames:
            return None

        j = self._check_j()
        if j:
            self.clear()
            return "J"

        z = self._check_z()
        if z:
            self.clear()
            return "Z"

        return None

    def clear(self):
        self.index_history.clear()
        self.pinky_history.clear()
        self.finger_states_history.clear()

    def _check_j(self) -> bool:
        """J = pinky-only hand tracing a downward arc."""
        points = list(self.pinky_history)
        states = list(self.finger_states_history)

        # Verify pinky was extended and others curled for most of the sequence
        pinky_only_count = sum(
            1 for s in states
            if s.get('pinky', False)
            and not s.get('index', False)
            and not s.get('middle', False)
            and not s.get('ring', False)
        )
        if pinky_only_count < len(states) * 0.6:
            return False

        # Compute displacement vectors between consecutive frames
        dx = [points[i + 1][0] - points[i][0] for i in range(len(points) - 1)]
        dy = [points[i + 1][1] - points[i][1] for i in range(len(points) - 1)]

        total_dy = sum(dy)
        total_dx = sum(dx)

        # J motion: net downward (positive y in image coords) with some lateral curve
        if total_dy > 0.08 and abs(total_dx) > 0.03:
            return True

        return False

    def _check_z(self) -> bool:
        """Z = index finger tracing a zigzag (right, diag-left-down, right)."""
        points = list(self.index_history)
        states = list(self.finger_states_history)

        # Verify index was extended for most of the sequence
        index_up_count = sum(1 for s in states if s.get('index', False))
        if index_up_count < len(states) * 0.6:
            return False

        # Split trajectory into 3 roughly equal segments
        n = len(points)
        seg_len = n // 3
        if seg_len < 2:
            return False

        seg1 = points[:seg_len]
        seg2 = points[seg_len:2 * seg_len]
        seg3 = points[2 * seg_len:]

        def segment_direction(seg):
            dx = seg[-1][0] - seg[0][0]
            dy = seg[-1][1] - seg[0][1]
            return dx, dy

        dx1, dy1 = segment_direction(seg1)
        dx2, dy2 = segment_direction(seg2)
        dx3, dy3 = segment_direction(seg3)

        # Segment 1: rightward (dx > 0)
        # Segment 2: leftward and downward (dx < 0, dy > 0)
        # Segment 3: rightward (dx > 0)
        if dx1 > 0.03 and dx2 < -0.03 and dy2 > 0.03 and dx3 > 0.03:
            return True

        return False
