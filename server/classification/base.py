from abc import ABC, abstractmethod
import numpy as np
from typing import List, Dict


class GestureClassifier(ABC):
    @abstractmethod
    def classify(self, landmarks) -> str:
        """
        Takes landmarks (raw dicts for heuristic, or a flat numpy array for ML)
        and returns a gesture label string.
        """
        pass
