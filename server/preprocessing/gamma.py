"""
Adaptive gamma correction preprocessor.

DIP concept: Gamma correction is a power-law transform (I_out = I_in ^ gamma)
that adjusts perceived brightness.  Gamma is computed from the frame's mean
luminance so dark frames are brightened and bright frames are left alone.
"""
import cv2
import numpy as np
from preprocessing.base import PreProcessor


class AdaptiveGammaCorrection(PreProcessor):
    def __init__(self, target_mean: float = 128.0):
        self.target_mean = target_mean

    def process(self, frame: np.ndarray) -> np.ndarray:
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        mean = float(gray.mean())
        if mean < 1.0:
            return frame
        gamma = np.log(self.target_mean / 255.0) / np.log(mean / 255.0 + 1e-6)
        gamma = float(np.clip(gamma, 0.4, 2.5))
        lut = (np.power(np.arange(256) / 255.0, gamma) * 255).astype(np.uint8)
        return cv2.LUT(frame, lut)
