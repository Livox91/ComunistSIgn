"""
Flask route handlers.
Kept separate from app.py so the app factory stays clean.
"""
import cv2
import numpy as np
from flask import jsonify, request


def register_routes(app):
    """Register all route handlers on the Flask app."""

    cfg = app.cfg

    def _get_finger_states(landmarks):
        """Quick check of which fingers are extended based on tip vs PIP y-position."""

        def extended(tip, pip):
            return landmarks[tip]["y"] < landmarks[pip]["y"] - 0.05

        return {
            "index": extended(8, 6),
            "middle": extended(12, 10),
            "ring": extended(16, 14),
            "pinky": extended(20, 18),
        }

    def _extract_for_alphabet(img):
        """
        Returns (hands, holistic_frame_or_none).
        - hands: list of hand-landmark dicts (compatible with legacy iteration)
        - holistic_frame: HolisticFrame instance if Holistic is in use, else None
        """
        result = app.landmark_extractor.extract(img)
        if result is None:
            return None, None
        if app.uses_holistic:
            return result.hands, result
        # Legacy LandmarkExtractor returns a list of hands directly
        return result, None

    @app.route("/process", methods=["POST"])
    def process_frame():
        try:
            file = request.files["image"]
            img = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)

            # Step 1: DIP preprocessing (CLAHE → Gaussian blur)
            img = app.preprocessor.process(img)

            # Step 2: Landmark extraction (Hands or Holistic)
            hands, holistic_frame = _extract_for_alphabet(img)

            if hands is None:
                # Even with no hand, push a "missing" feature window so the buffer
                # ages out cleanly. Currently we just skip — buffer keeps last good frames.
                return jsonify({"gesture": "No hands detected"})

            # Step 3: Per-hand alphabet classification
            detected_gestures = []
            for landmarks in hands:
                finger_states = _get_finger_states(landmarks)
                app.motion_classifier.update(landmarks, finger_states)

                # Try motion-based detection first (J/Z)
                motion_gesture = app.motion_classifier.classify()
                if motion_gesture:
                    detected_gestures.append(motion_gesture)
                    app.gesture_buffer.add(motion_gesture)
                    continue

                gesture = app.classifier.classify(landmarks)
                if gesture in ("Unknown", "NOTHING"):
                    continue
                detected_gestures.append(gesture)
                # SPACE / DELETE are UI commands handled by Flutter — keep them
                # out of the gesture buffer used for phrase string matching.
                if gesture not in ("SPACE", "DELETE"):
                    app.gesture_buffer.add(gesture)

            # Step 4: Phrase recognition (LSTM, only when Holistic is in use)
            phrase_predictions = None
            if (
                app.phrase_classifier is not None
                and holistic_frame is not None
                and holistic_frame.primary_hand_type is not None
            ):
                # holistic_frame.hands[0] is the primary hand by construction
                features = app.body_frame_normalizer.normalize(
                    hand_landmarks=holistic_frame.hands[0],
                    face_landmarks=holistic_frame.face,
                    pose_landmarks=holistic_frame.pose,
                    hand_type=holistic_frame.primary_hand_type,
                )
                if features is not None:
                    app.sequence_buffer.push(features)
                    if app.sequence_buffer.is_ready():
                        window = app.sequence_buffer.get_window()
                        top_k = app.phrase_classifier.classify_top_k(
                            window, k=cfg.PHRASE_TOP_K
                        )
                        filtered = [
                            {"label": lab, "confidence": round(prob, 4)}
                            for lab, prob in top_k
                            if prob >= cfg.PHRASE_MIN_CONFIDENCE
                        ]
                        if filtered:
                            phrase_predictions = filtered

            # Step 5: Legacy phrase-string matcher (kept as a fallback)
            current_sequence = app.gesture_buffer.get_sequence()
            matched_phrase = (
                app.phrase_matcher.match(current_sequence) if current_sequence else None
            )

            response = {
                "gestures": detected_gestures,
                "sequence": current_sequence,
                "sequence_string": "".join(current_sequence),
                "buffer_size": len(current_sequence),
            }
            if phrase_predictions:
                response["phrase_predictions"] = phrase_predictions
            if matched_phrase:
                response["phrase"] = matched_phrase
                app.gesture_buffer.clear()

            return jsonify(response)

        except Exception:
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

        except Exception:
            return jsonify({"status": "Detecting...."}), 200
