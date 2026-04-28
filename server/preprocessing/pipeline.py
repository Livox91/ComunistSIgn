import numpy as np
from typing import List
from preprocessing.base import PreProcessor


class PreProcessingPipeline(PreProcessor):
    """Chains multiple PreProcessor steps. Runs them in order on each frame."""

    def __init__(self, steps: List[PreProcessor] = None):
        self.steps = steps or []

    def process(self, frame: np.ndarray) -> np.ndarray:
        for step in self.steps:
            frame = step.process(frame)
        return frame
