"""
Gaussian blur preprocessor.

DIP concept: Gaussian filtering is a linear smoothing operation that
convolves the image with a Gaussian kernel to suppress high-frequency
noise (sensor noise, compression artifacts). This reduces false
detections in MediaPipe's landmark estimator.
"""
import cv2
import numpy as np
from preprocessing.base import PreProcessor


class GaussianFilter(PreProcessor):
    def __init__(self, kernel_size: int = 5):
        if kernel_size % 2 == 0:
            kernel_size += 1
        self.kernel_size = kernel_size

    def process(self, frame: np.ndarray) -> np.ndarray:
        return cv2.GaussianBlur(frame, (self.kernel_size, self.kernel_size), 0)
