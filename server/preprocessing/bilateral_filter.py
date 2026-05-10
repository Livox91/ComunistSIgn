"""
Bilateral filter preprocessor.

DIP concept: Unlike Gaussian blur which smooths uniformly, the bilateral filter
is an edge-preserving smoothing operation.  It weights neighbours by both
spatial distance and intensity similarity, keeping finger boundaries sharp
while suppressing sensor noise and compression artefacts.
"""
import cv2
import numpy as np
from preprocessing.base import PreProcessor


class BilateralFilterProcessor(PreProcessor):
    def __init__(self, d: int = 9, sigma_color: float = 75, sigma_space: float = 75):
        self.d = d
        self.sigma_color = sigma_color
        self.sigma_space = sigma_space

    def process(self, frame: np.ndarray) -> np.ndarray:
        return cv2.bilateralFilter(frame, self.d, self.sigma_color, self.sigma_space)
