"""
CLAHE (Contrast Limited Adaptive Histogram Equalization) preprocessor.

DIP concept: Histogram equalization normalises the brightness distribution
of an image, improving contrast in underexposed or unevenly-lit frames.
CLAHE applies this locally (per tile) to avoid over-amplifying noise.

Applied to the L channel of LAB colour space so colour information is
preserved — important because MediaPipe's hand detector uses colour cues.
"""
import cv2
import numpy as np
from preprocessing.base import PreProcessor


class CLAHEProcessor(PreProcessor):
    def __init__(self, clip_limit: float = 2.0, tile_grid: tuple = (8, 8)):
        self.clahe = cv2.createCLAHE(clipLimit=clip_limit, tileGridSize=tile_grid)

    def process(self, frame: np.ndarray) -> np.ndarray:
        # Convert to LAB, apply CLAHE to L channel, convert back
        lab = cv2.cvtColor(frame, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        l = self.clahe.apply(l)
        lab = cv2.merge([l, a, b])
        return cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)
