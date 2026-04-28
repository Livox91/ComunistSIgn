"""
Phrase matcher — maps 3-letter gesture sequences to full phrases.
Extracted from the original server.py — logic is identical.
"""
from typing import List, Optional


class PhraseMatcher:
    def __init__(self):
        self.phrases = {
            "CBA": "Hello, how are you",
            "IAF": "I am fine",
            "KHA": "This is mobile computing class",
            "BEK": "Goodbye",
            "THX": "Thank you",
            "PLZ": "Please",
            "HLP": "Help me",
            "YES": "I agree",
            "NOO": "I disagree",
        }

    def match(self, gesture_sequence: List[str]) -> Optional[str]:
        """
        Check the last 5 gestures for any 3-letter phrase match.
        Returns the matched phrase string or None.
        """
        sequence_str = "".join(gesture_sequence)

        if len(sequence_str) >= 3:
            for i in range(min(5, len(sequence_str) - 2)):
                three_chars = sequence_str[-(i + 3):][:3]
                if three_chars in self.phrases:
                    return self.phrases[three_chars]

        return None
