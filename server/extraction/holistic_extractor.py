"""
MediaPipe Holistic wrapper.

Replaces the Hands-only extractor with a single pass that returns hands + face + pose.
Slightly slower per-frame than Hands alone (~50–80 ms vs ~20 ms) but the LSTM phrase
model needs face and pose anchors to disambiguate signs that share hand shapes.

For backwards-compat with the alphabet path, the returned `HolisticFrame.hands` field
is a list of hand-landmark dicts in the same shape the old `LandmarkExtractor` returned.
"""
from dataclasses import dataclass
from typing import Dict, List, Optional

import cv2
import mediapipe as mp
import numpy as np


@dataclass
class HolisticFrame:
    """One frame's worth of MediaPipe Holistic output."""

    hands: List[List[Dict]]            # 1 or 2 hands; each is 21 landmark dicts
    face: Optional[List[Dict]]         # 468 landmark dicts or None
    pose: Optional[List[Dict]]         # 33 landmark dicts or None
    primary_hand_type: Optional[str]   # 'right_hand' or 'left_hand' (which hand is hands[0])


class HolisticExtractor:
    """Wraps MediaPipe Holistic. Returns hands + face + pose from a BGR frame."""

    def __init__(
        self,
        static_image_mode: bool = False,
        model_complexity: int = 1,
        smooth_landmarks: bool = True,
        min_detection_confidence: float = 0.5,
        min_tracking_confidence: float = 0.5,
    ):
        self.mp_holistic = mp.solutions.holistic
        self.holistic = self.mp_holistic.Holistic(
            static_image_mode=static_image_mode,
            model_complexity=model_complexity,
            smooth_landmarks=smooth_landmarks,
            enable_segmentation=False,
            refine_face_landmarks=False,
            min_detection_confidence=min_detection_confidence,
            min_tracking_confidence=min_tracking_confidence,
        )

    def extract(self, bgr_frame: np.ndarray) -> Optional[HolisticFrame]:
        rgb = cv2.cvtColor(bgr_frame, cv2.COLOR_BGR2RGB)
        results = self.holistic.process(rgb)

        hands: List[List[Dict]] = []
        primary_hand_type: Optional[str] = None

        # Prefer right hand as the primary if both are detected — matches the training-time bias
        if results.right_hand_landmarks is not None:
            hands.append(self._to_dict_list(results.right_hand_landmarks))
            primary_hand_type = "right_hand"
        if results.left_hand_landmarks is not None:
            lh = self._to_dict_list(results.left_hand_landmarks)
            hands.append(lh)
            if primary_hand_type is None:
                primary_hand_type = "left_hand"

        if not hands:
            return None

        face = self._to_dict_list(results.face_landmarks) if results.face_landmarks else None
        pose = self._to_dict_list(results.pose_landmarks) if results.pose_landmarks else None

        return HolisticFrame(
            hands=hands,
            face=face,
            pose=pose,
            primary_hand_type=primary_hand_type,
        )

    @staticmethod
    def _to_dict_list(landmark_list) -> List[Dict]:
        return [{"x": lm.x, "y": lm.y, "z": lm.z} for lm in landmark_list.landmark]

    def close(self):
        self.holistic.close()
