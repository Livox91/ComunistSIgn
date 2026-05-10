"""
Gray-world white balance preprocessor.

DIP concept: The gray-world assumption states that the average colour of a
natural scene is achromatic (neutral grey).  Each BGR channel is scaled so
its mean equals the overall mean luminance, removing colour casts caused by
artificial lighting (yellow incandescent, blue LED, etc.).

Applied first in the pipeline so all downstream steps work on colour-neutral data.
"""
import cv2
import numpy as np
from preprocessing.base import PreProcessor


class WhiteBalanceProcessor(PreProcessor):
    def process(self, frame: np.ndarray) -> np.ndarray:
        result = frame.astype(np.float32)
        means = result.mean(axis=(0, 1))
        overall = means.mean()
        scales = overall / (means + 1e-6)
        scales = np.clip(scales, 0.5, 2.0)
        result *= scales
        return np.clip(result, 0, 255).astype(np.uint8)
