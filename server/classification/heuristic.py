"""
Heuristic (rule-based) ASL gesture classifier.
Extracted from the original server.py — logic is identical, just wrapped in a class.
"""
import numpy as np
from typing import List, Dict
from classification.base import GestureClassifier


def _calculate_angle(point1: Dict, point2: Dict, point3: Dict) -> float:
    """Calculate angle between three points."""
    vector1 = np.array([point1['x'] - point2['x'], point1['y'] - point2['y']])
    vector2 = np.array([point3['x'] - point2['x'], point3['y'] - point2['y']])

    cosine = np.dot(vector1, vector2) / (np.linalg.norm(vector1) * np.linalg.norm(vector2))
    angle = np.arccos(np.clip(cosine, -1.0, 1.0))
    return np.degrees(angle)


def _distance(point1: Dict, point2: Dict) -> float:
    """Calculate Euclidean distance between two points."""
    return np.sqrt((point1['x'] - point2['x'])**2 + (point1['y'] - point2['y'])**2)


class HeuristicClassifier(GestureClassifier):
    """
    Rule-based ASL alphabet classifier using geometric features
    computed from MediaPipe hand landmarks.
    """

    def classify(self, landmarks: List[Dict]) -> str:
        """
        Takes a list of 21 landmark dicts (raw MediaPipe output)
        and returns a letter A-Y or 'Unknown'.
        """
        return _classify_gesture(landmarks)


def _classify_gesture(landmarks: List[Dict]) -> str:
    """Enhanced gesture classification for complete ASL alphabet"""

    def is_finger_curled(tip_idx, pip_idx, mcp_idx):
        angle = _calculate_angle(landmarks[tip_idx], landmarks[pip_idx], landmarks[mcp_idx])
        return angle < 110

    def is_finger_extended(tip_idx, pip_idx):
        return landmarks[tip_idx]['y'] < landmarks[pip_idx]['y'] - 0.05

    def fingers_distance(tip1_idx, tip2_idx):
        return _distance(landmarks[tip1_idx], landmarks[tip2_idx])

    def thumb_is_out(thumb_tip_idx=4, thumb_ip_idx=3, thumb_mcp_idx=2):
        return not is_finger_curled(thumb_tip_idx, thumb_ip_idx, thumb_mcp_idx)

    def thumb_across_palm():
        return (landmarks[4]['x'] < landmarks[5]['x'] and
                landmarks[4]['x'] > landmarks[17]['x'])

    def fingers_together(tip1_idx, tip2_idx):
        return fingers_distance(tip1_idx, tip2_idx) < 0.05

    def thumb_between_fingers():
        return (landmarks[4]['x'] > landmarks[5]['x'] and
                landmarks[4]['x'] < landmarks[17]['x'])

    # A - Fist with thumb to side
    if (all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in
           [(8,6,5), (12,10,9), (16,14,13), (20,18,17)]) and
        thumb_is_out()):
        return "A"

    # B - Fingers straight up, thumb across
    if (all(is_finger_extended(tip, pip) for tip, pip in
           [(8,6), (12,10), (16,14), (20,18)]) and
        thumb_across_palm()):
        return "B"

    # C - Curved hand
    if (all(not is_finger_curled(tip, pip, mcp) and not is_finger_extended(tip, pip)
            for tip, pip, mcp in [(8,6,5), (12,10,9), (16,14,13), (20,18,17)]) and
        0.1 < fingers_distance(4, 8) < 0.3):
        return "C"

    # D - Modified for better detection
    if (is_finger_extended(8, 6) and
        all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in
            [(12,10,9), (16,14,13), (20,18,17)]) and
        landmarks[4]['x'] > landmarks[5]['x'] and
        landmarks[4]['y'] > landmarks[8]['y']):
        return "D"

    # E - All fingers curled
    if all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in
           [(8,6,5), (12,10,9), (16,14,13), (20,18,17), (4,3,2)]):
        return "E"

    # F - Index and thumb touching, others extended
    if (fingers_distance(4, 8) < 0.05 and
        all(is_finger_extended(tip, pip) for tip, pip in
            [(12,10), (16,14), (20,18)])):
        return "F"

    # G - Index pointing to side
    if (is_finger_extended(8, 6) and thumb_is_out() and
        all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in
            [(12,10,9), (16,14,13), (20,18,17)])):
        return "G"

    # H - Index and middle side by side
    if (is_finger_extended(8, 6) and is_finger_extended(12, 10) and
        fingers_distance(8, 12) < 0.1 and
        all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in
            [(16,14,13), (20,18,17)])):
        return "H"

    # I - Pinky only
    if (is_finger_extended(20, 18) and
        all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in
            [(8,6,5), (12,10,9), (16,14,13)])):
        return "I"

    # J - Moving I downward (needs motion tracking — skipped in heuristic)

    # K - Index and middle V with thumb
    if (is_finger_extended(8, 6) and is_finger_extended(12, 10) and
        fingers_distance(8, 12) > 0.1 and thumb_is_out()):
        return "K"

    # L - L shape
    if (is_finger_extended(8, 6) and thumb_is_out() and
        all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in
            [(12,10,9), (16,14,13), (20,18,17)])):
        return "L"

    # M - Modified for better detection
    if (landmarks[4]['y'] > landmarks[3]['y'] and
        all(landmarks[tip]['y'] > landmarks[base]['y']
            for base, tip in [(6, 8), (10, 12), (14, 16)]) and
        landmarks[20]['y'] > landmarks[18]['y']):
        return "M"

    # N - Two fingers over thumb
    if (all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in
           [(8,6,5), (12,10,9)]) and
        all(is_finger_extended(tip, pip) for tip, pip in
            [(16,14), (20,18)])):
        return "N"

    # O - Circle shape
    if (all(fingers_distance(4, tip) < 0.1 for tip in [8, 12, 16, 20])):
        return "O"

    # P - Modified for better detection
    if (landmarks[8]['y'] > landmarks[6]['y'] and
        all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in
            [(12,10,9), (16,14,13), (20,18,17)]) and
        thumb_is_out() and
        landmarks[4]['x'] < landmarks[5]['x']):
        return "P"

    # Q - Down pointing G
    if (fingers_distance(4, 8) < 0.05 and
        all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in
            [(12,10,9), (16,14,13), (20,18,17)])):
        return "Q"

    # R - Crossed fingers
    if (is_finger_extended(8, 6) and is_finger_extended(12, 10) and
        fingers_distance(8, 12) < 0.05):
        return "R"

    # S - Modified for better detection
    if (all(landmarks[tip]['y'] > landmarks[base]['y']
            for base, tip in [(6, 8), (10, 12), (14, 16), (18, 20)]) and
        thumb_across_palm()):
        return "S"

    # T - Modified for better detection
    if ((landmarks[8]['y'] > landmarks[6]['y'] and
         landmarks[6]['y'] > landmarks[5]['y']) and
        all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in
            [(12,10,9), (16,14,13), (20,18,17)]) and
        landmarks[4]['x'] > landmarks[5]['x'] and
        landmarks[4]['x'] < landmarks[9]['x']):
        return "T"

    # U - Two fingers up together
    if (is_finger_extended(8, 6) and is_finger_extended(12, 10) and
        fingers_together(8, 12)):
        return "U"

    # V - Peace sign
    if (is_finger_extended(8, 6) and is_finger_extended(12, 10) and
        not fingers_together(8, 12)):
        return "V"

    # W - Three fingers up
    if (all(is_finger_extended(tip, pip) for tip, pip in
            [(8,6), (12,10), (16,14)]) and
        not is_finger_extended(20, 18)):
        return "W"

    # X - Modified for better detection
    if ((landmarks[8]['y'] > landmarks[7]['y'] and
         landmarks[7]['y'] < landmarks[6]['y']) and
        all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in
            [(12,10,9), (16,14,13), (20,18,17)])):
        return "X"

    # Y - Horns
    if (thumb_is_out() and is_finger_extended(20, 18) and
        all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in
            [(8,6,5), (12,10,9), (16,14,13)])):
        return "Y"

    return "Unknown"
