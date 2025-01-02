import mediapipe as mp
import cv2
import numpy as np
from flask import Flask, request, jsonify
from fer import FER
from collections import deque
import time

app = Flask(__name__)

# Initialize MediaPipe Hands and Face Mesh
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    min_detection_confidence=0.7,
    min_tracking_confidence=0.7
)

# Initialize FER
emotion_detector = FER(mtcnn=True)

def classify_gesture(landmarks):
    """Enhanced gesture classification for complete ASL alphabet"""
    
    def is_finger_curled(tip_idx, pip_idx, mcp_idx):
        angle = calculate_angle(landmarks[tip_idx], landmarks[pip_idx], landmarks[mcp_idx])
        return angle < 110
    
    def is_finger_extended(tip_idx, pip_idx):
        return landmarks[tip_idx]['y'] < landmarks[pip_idx]['y'] - 0.05
    
    def fingers_distance(tip1_idx, tip2_idx):
        return distance(landmarks[tip1_idx], landmarks[tip2_idx])
    
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
    if (is_finger_extended(8, 6) and  # Index up
        all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in 
            [(12,10,9), (16,14,13), (20,18,17)]) and  # Others curled
        landmarks[4]['x'] > landmarks[5]['x'] and  # Thumb position
        landmarks[4]['y'] > landmarks[8]['y']):  # Thumb below index
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
    
    # J - Moving I downward (needs motion tracking)
    
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
    if (landmarks[4]['y'] > landmarks[3]['y'] and  # Thumb tucked
        all(landmarks[tip]['y'] > landmarks[base]['y']  # Three fingers folded
            for base, tip in [(6, 8), (10, 12), (14, 16)]) and
        landmarks[20]['y'] > landmarks[18]['y']):  # Pinky folded
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
    if (landmarks[8]['y'] > landmarks[6]['y'] and  # Index pointing down
        all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in 
            [(12,10,9), (16,14,13), (20,18,17)]) and  # Others curled
        thumb_is_out() and  # Thumb extended
        landmarks[4]['x'] < landmarks[5]['x']):  # Thumb away from palm
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
    if ((landmarks[8]['y'] > landmarks[6]['y'] and  # Index knuckle bent
         landmarks[6]['y'] > landmarks[5]['y']) and
        all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in 
            [(12,10,9), (16,14,13), (20,18,17)]) and  # Others curled
        landmarks[4]['x'] > landmarks[5]['x'] and  # Thumb placement
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
    if ((landmarks[8]['y'] > landmarks[7]['y'] and  # Index hooked
         landmarks[7]['y'] < landmarks[6]['y']) and
        all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in 
            [(12,10,9), (16,14,13), (20,18,17)])):  # Others curled
        return "X"
    
    # Y - Horns
    if (thumb_is_out() and is_finger_extended(20, 18) and
        all(is_finger_curled(tip, pip, mcp) for tip, pip, mcp in 
            [(8,6,5), (12,10,9), (16,14,13)])):
        return "Y"
    
    return "Unknown"

# Rest of your existing code remains the same...

def match_phrase(gesture_sequence):
    """
    Enhanced phrase matching with more flexible sequence detection.
    Includes partial matching and more robust sequence handling.
    """
    phrases = {
        "CBA": "Hello, how are you",
        "IAF": "I am fine",
        "KHA": "This is mobile computing class",
        "BEK": "Goodbye",
        "THX": "Thank you",
        "PLZ": "Please",
        "HLP": "Help me",
        "YES": "I agree",
        "NOO": "I disagree"
    }
    
    # Convert gesture sequence to string
    sequence_str = "".join(gesture_sequence)
    
    # Look for matches in the last 5 gestures (increased window)
    if len(sequence_str) >= 3:
        # Check last 5 positions for any matching sequence
        for i in range(min(5, len(sequence_str) - 2)):
            three_chars = sequence_str[-(i + 3):][:3]
            if three_chars in phrases:
                return phrases[three_chars]
    
    return None

class GestureBuffer:
    def __init__(self, max_size=15, max_age=5.0):  # Increased buffer size and age
        self.buffer = deque(maxlen=max_size)
        self.timestamps = deque(maxlen=max_size)
        self.max_age = max_age
        self.last_gesture = None
        self.last_gesture_count = 0

    def add(self, gesture):
        current_time = time.time()
        
        # Debouncing: If same gesture detected multiple times, only add once
        if gesture == self.last_gesture:
            self.last_gesture_count += 1
            if self.last_gesture_count < 3:  # Only add if count is low
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

gesture_buffer = GestureBuffer()

def calculate_angle(point1, point2, point3):
    """Calculate angle between three points"""
    vector1 = np.array([point1['x'] - point2['x'], point1['y'] - point2['y']])
    vector2 = np.array([point3['x'] - point2['x'], point3['y'] - point2['y']])
    
    cosine = np.dot(vector1, vector2) / (np.linalg.norm(vector1) * np.linalg.norm(vector2))
    angle = np.arccos(np.clip(cosine, -1.0, 1.0))
    return np.degrees(angle)

def distance(point1, point2):
    """Calculate Euclidean distance between two points"""
    return np.sqrt((point1['x'] - point2['x'])**2 + (point1['y'] - point2['y'])**2)

@app.route('/process', methods=['POST'])
def process_frame():
    try:
        file = request.files['image']
        img = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)
        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        
        results = hands.process(img_rgb)
        
        if not results.multi_hand_landmarks:
            return jsonify({'gesture': 'No hands detected'})
        
        detected_gestures = []
        for hand_landmarks in results.multi_hand_landmarks:
            landmarks = [{'x': lm.x, 'y': lm.y, 'z': lm.z} 
                        for lm in hand_landmarks.landmark]
            
            gesture = classify_gesture(landmarks)
            if gesture != "Unknown":
                detected_gestures.append(gesture)
                gesture_buffer.add(gesture)
        
        # Get current sequence and try to match phrase
        current_sequence = gesture_buffer.get_sequence()
        matched_phrase = match_phrase(current_sequence) if current_sequence else None
        
        # Enhanced response with debugging info
        response = {
            'gestures': detected_gestures,
            'sequence': current_sequence,
            'sequence_string': ''.join(current_sequence),
            'buffer_size': len(current_sequence)
        }
        
        if matched_phrase:
            response['phrase'] = matched_phrase
            gesture_buffer.clear()  # Clear buffer after successful match
            
        return jsonify(response)
        
    except Exception as e:
        return jsonify({'Detecting....'}), 500

@app.route('/process/emotion', methods=['POST'])
def process_emotion():
    try:
        file = request.files['image']
        img = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)
        
        if img is None:
            return jsonify({'error': 'Invalid image'}), 400
            
        # Detect emotions using FER
        emotions = emotion_detector.detect_emotions(img)
        
        if not emotions:
            return jsonify({'error': 'No face detected'}), 400
            
        # Get the dominant emotion
        dominant_emotion = emotion_detector.top_emotion(img)
        
        if dominant_emotion:
            emotion_name, confidence = dominant_emotion
            return jsonify({
                'emotion': emotion_name,
                'confidence': float(confidence),
                'all_emotions': emotions[0]['emotions'] if emotions else {}
            })
        else:
            return jsonify({'error': 'Could not determine emotion'}), 400
            
    except Exception as e:
        return jsonify({'Detecting....'}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)