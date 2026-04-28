"""
Flask route handlers.
Kept separate from app.py so the app factory stays clean.
"""
import cv2
import numpy as np
from flask import request, jsonify


def register_routes(app):
    """Register all route handlers on the Flask app."""

    @app.route("/process", methods=["POST"])
    def process_frame():
        try:
            file = request.files["image"]
            img = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)

            # Step 1: DIP preprocessing (currently a pass-through — Phase 1 adds CLAHE + Gaussian)
            img = app.preprocessor.process(img)

            # Step 2: Landmark extraction
            all_hands = app.landmark_extractor.extract(img)

            if all_hands is None:
                return jsonify({"gesture": "No hands detected"})

            # Step 3: Classify each hand
            detected_gestures = []
            for landmarks in all_hands:
                gesture = app.classifier.classify(landmarks)
                if gesture != "Unknown":
                    detected_gestures.append(gesture)
                    app.gesture_buffer.add(gesture)

            # Step 4: Phrase matching
            current_sequence = app.gesture_buffer.get_sequence()
            matched_phrase = app.phrase_matcher.match(current_sequence) if current_sequence else None

            response = {
                "gestures": detected_gestures,
                "sequence": current_sequence,
                "sequence_string": "".join(current_sequence),
                "buffer_size": len(current_sequence),
            }

            if matched_phrase:
                response["phrase"] = matched_phrase
                app.gesture_buffer.clear()

            return jsonify(response)

        except Exception as e:
            return jsonify({"status": "Detecting...."}), 200

    @app.route("/process/emotion", methods=["POST"])
    def process_emotion():
        try:
            file = request.files["image"]
            img = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)

            if img is None:
                return jsonify({"error": "Invalid image"}), 400

            result = app.emotion_detector.detect(img)

            if result:
                return jsonify(result)
            else:
                return jsonify({"error": "No face detected"}), 400

        except Exception as e:
            return jsonify({"status": "Detecting...."}), 200
