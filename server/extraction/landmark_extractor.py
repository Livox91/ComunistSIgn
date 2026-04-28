import mediapipe as mp
import cv2
import numpy as np
from typing import List, Dict, Optional


class LandmarkExtractor:
    """Wraps MediaPipe Hands to extract 21 hand landmarks from a BGR image."""

    def __init__(
        self,
        static_image_mode: bool = False,
        max_num_hands: int = 2,
        min_detection_confidence: float = 0.7,
        min_tracking_confidence: float = 0.7,
    ):
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(
            static_image_mode=static_image_mode,
            max_num_hands=max_num_hands,
            min_detection_confidence=min_detection_confidence,
            min_tracking_confidence=min_tracking_confidence,
        )

    def extract(self, bgr_frame: np.ndarray) -> Optional[List[List[Dict]]]:
        """
        Returns a list of hands, where each hand is a list of 21 landmark dicts
        with keys 'x', 'y', 'z'.  Returns None if no hands detected.
        """
        rgb_frame = cv2.cvtColor(bgr_frame, cv2.COLOR_BGR2RGB)
        results = self.hands.process(rgb_frame)

        if not results.multi_hand_landmarks:
            return None

        all_hands = []
        for hand_landmarks in results.multi_hand_landmarks:
            landmarks = [
                {"x": lm.x, "y": lm.y, "z": lm.z}
                for lm in hand_landmarks.landmark
            ]
            all_hands.append(landmarks)

        return all_hands

    def close(self):
        self.hands.close()
