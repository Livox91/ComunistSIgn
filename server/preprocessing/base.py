from abc import ABC, abstractmethod
import numpy as np


class PreProcessor(ABC):
    @abstractmethod
    def process(self, frame: np.ndarray) -> np.ndarray:
        """Takes a BGR frame, returns a processed BGR frame."""
        pass
