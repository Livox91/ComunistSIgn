"""
Temporal gesture buffer with debouncing.
Extracted from the original server.py — logic is identical.
"""
from collections import deque
import time


class GestureBuffer:
    def __init__(self, max_size: int = 15, max_age: float = 5.0, debounce_threshold: int = 3):
        self.buffer = deque(maxlen=max_size)
        self.timestamps = deque(maxlen=max_size)
        self.max_age = max_age
        self.debounce_threshold = debounce_threshold
        self.last_gesture = None
        self.last_gesture_count = 0

    def add(self, gesture: str):
        current_time = time.time()

        # Debouncing: If same gesture detected multiple times, only add once
        if gesture == self.last_gesture:
            self.last_gesture_count += 1
            if self.last_gesture_count < self.debounce_threshold:
                return
        else:
            self.last_gesture = gesture
            self.last_gesture_count = 1

        # Add new gesture
        self.buffer.append(gesture)
        self.timestamps.append(current_time)

        # Clean old gestures
        while self.timestamps and (current_time - self.timestamps[0]) > self.max_age:
            self.buffer.popleft()
            self.timestamps.popleft()

    def get_sequence(self):
        return list(self.buffer)

    def clear(self):
        self.buffer.clear()
        self.timestamps.clear()
        self.last_gesture = None
        self.last_gesture_count = 0
