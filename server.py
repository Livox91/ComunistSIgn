import mediapipe as mp
import cv2
import numpy as np
from flask import Flask, request, jsonify
from fer import FER


app = Flask(__name__)

# Initialize MediaPipe Hands and Face Mesh
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False, max_num_hands=1, min_detection_confidence=0.7, min_tracking_confidence=0.7
)
mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(
    static_image_mode=False, max_num_faces=1, min_detection_confidence=0.7
)

# Function to classify gestures
def classify_gesture(landmarks):
    # Define finger indices for tip and base joints
    thumb_tip = landmarks[4]
    thumb_base = landmarks[2]
    index_tip = landmarks[8]
    index_base = landmarks[6]
    middle_tip = landmarks[12]
    middle_base = landmarks[10]
    ring_tip = landmarks[16]
    ring_base = landmarks[14]
    pinky_tip = landmarks[20]
    pinky_base = landmarks[18]

    # Helper function to determine if a finger is extended
    def is_finger_extended(tip, base, palm_y):
        return tip['y'] < base['y'] and abs(tip['y'] - palm_y) > 0.015

    # Calculate palm base (average of wrist and base of middle finger)
    palm_y = (landmarks[0]['y'] + landmarks[9]['y']) / 2

    # Determine the state of each finger
    thumb_extended = is_finger_extended(thumb_tip, thumb_base, palm_y)
    index_extended = is_finger_extended(index_tip, index_base, palm_y)
    middle_extended = is_finger_extended(middle_tip, middle_base, palm_y)
    ring_extended = is_finger_extended(ring_tip, ring_base, palm_y)
    pinky_extended = is_finger_extended(pinky_tip, pinky_base, palm_y)

    # Check for gestures
    if thumb_extended and not (index_extended or middle_extended or ring_extended or pinky_extended):
        return "Thumbs Up"
    if index_extended and middle_extended and not (ring_extended or pinky_extended):
        if not thumb_extended:
            return "Peace Sign"
        else:
            return "2"
    if index_extended and not (middle_extended or ring_extended or pinky_extended):
        return "1"
    if index_extended and middle_extended and ring_extended and not pinky_extended:
        return "3"
    if index_extended and middle_extended and ring_extended and pinky_extended:
        return "4"
    if thumb_extended and index_extended and middle_extended and ring_extended and pinky_extended:
        return "5"

    # Default case
    return "Unknown Gesture"

@app.route('/process', methods=['POST'])
def process_frame():
    file = request.files['image']
    img = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    results = hands.process(img_rgb)

    if results.multi_hand_landmarks:
        landmarks = []
        for hand_landmarks in results.multi_hand_landmarks:
            for lm in hand_landmarks.landmark:
                landmarks.append({'x': lm.x, 'y': lm.y, 'z': lm.z})
        
        gesture = classify_gesture(landmarks)
        return jsonify({'gesture': gesture})

    return jsonify({'error': 'No hands detected'})

@app.route('/process/emotion', methods=['POST'])
def process_emotion():
    file = request.files['image']
    img = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)

    if img is None:
        return jsonify({'error': 'Invalid image'}), 400

    # FER Emotion Detection
    detector = FER(mtcnn=True)  # Using MTCNN for face detection
    emotions = detector.detect_emotions(img)

    if not emotions:
        return jsonify({'error': 'No face detected'}), 400

    # Assuming single face in the image
    dominant_emotion = detector.top_emotion(img)

    return jsonify({'emotion': dominant_emotion[0], 'confidence': dominant_emotion[1]})

if __name__ == '__main__':
    app.run(debug=True)
