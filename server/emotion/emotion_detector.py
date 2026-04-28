"""
Facial emotion detection using FER + MTCNN.
Extracted from the original server.py — logic is identical.
"""
import cv2
import numpy as np
from fer import FER
from typing import Dict, Optional, Tuple


class EmotionDetector:
    def __init__(self, use_mtcnn: bool = True):
        self.detector = FER(mtcnn=use_mtcnn)

    def detect(self, bgr_frame: np.ndarray) -> Optional[Dict]:
        """
        Detect emotions in a BGR frame.

        Returns a dict with:
          - 'emotion': dominant emotion name
          - 'confidence': float 0-1
          - 'all_emotions': dict of all emotion probabilities
        Or None if no face was detected.
        """
        emotions = self.detector.detect_emotions(bgr_frame)

        if not emotions:
            return None

        dominant = self.detector.top_emotion(bgr_frame)

        if dominant:
            emotion_name, confidence = dominant
            return {
                "emotion": emotion_name,
                "confidence": float(confidence),
                "all_emotions": emotions[0]["emotions"] if emotions else {},
            }

        return None
