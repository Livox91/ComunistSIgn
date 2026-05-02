"""
Live webcam test of both classifiers — alphabet (per-frame) and phrase (LSTM, sequence).
Imports the same modules the server uses. No Flask, no Flutter.

Run from the server/ directory:
    python test_webcam.py

Keys:
    q  — quit
    h  — toggle alphabet classifier (trained MLP / heuristic)
    c  — clear the LSTM sequence buffer (start fresh phrase capture)
"""
import cv2

from preprocessing.pipeline import PreProcessingPipeline
from preprocessing.histogram_eq import CLAHEProcessor
from preprocessing.noise_filter import GaussianFilter
from extraction.holistic_extractor import HolisticExtractor
from extraction.body_frame_normalizer import BodyFrameNormalizer
from postprocessing.sequence_buffer import SequenceFeatureBuffer
from classification.heuristic import HeuristicClassifier
from classification.tflite_classifier import TFLiteAlphabetClassifier
from classification.lstm_classifier import LSTMPhraseClassifier


TARGET_LEN = 30
FEATURE_DIM = 85
TOP_K = 3
MIN_CONFIDENCE = 0.30


def main():
    # Pipeline (same as the server)
    preprocessor = PreProcessingPipeline(steps=[
        CLAHEProcessor(clip_limit=2.0, tile_grid=(8, 8)),
        GaussianFilter(kernel_size=5),
    ])
    extractor = HolisticExtractor(
        static_image_mode=False,
        model_complexity=1,
        smooth_landmarks=True,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
    )
    body_normalizer = BodyFrameNormalizer()
    seq_buf = SequenceFeatureBuffer(target_len=TARGET_LEN, feature_dim=FEATURE_DIM)

    trained = TFLiteAlphabetClassifier(
        model_path="models/alphabet_model.tflite",
        label_encoder_path="models/label_encoder.pkl",
        confidence_threshold=0.6,
    )
    heuristic = HeuristicClassifier()
    phrase_clf = LSTMPhraseClassifier(
        model_path="models/phrases_model.tflite",
        label_encoder_path="models/phrases_label_encoder.pkl",
        target_len=TARGET_LEN,
        feature_dim=FEATURE_DIM,
    )

    use_trained = True
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Could not open webcam (device 0).")
        return

    print("Webcam opened. q=quit  h=toggle alphabet classifier  c=clear phrase buffer")

    last_phrase_predictions = []

    while True:
        ok, frame = cap.read()
        if not ok:
            break
        frame = cv2.flip(frame, 1)  # mirror for natural feel

        processed = preprocessor.process(frame)
        result = extractor.extract(processed)

        letter = "no hand"
        if result is not None and result.hands:
            classifier = trained if use_trained else heuristic
            letter = classifier.classify(result.hands[0])

            # Build LSTM features and push to the sequence buffer
            if result.primary_hand_type is not None:
                feats = body_normalizer.normalize(
                    hand_landmarks=result.hands[0],
                    face_landmarks=result.face,
                    pose_landmarks=result.pose,
                    hand_type=result.primary_hand_type,
                )
                seq_buf.push(feats)

                if seq_buf.is_ready():
                    window = seq_buf.get_window()
                    preds = phrase_clf.classify_top_k(window, k=TOP_K)
                    last_phrase_predictions = [
                        (lab, prob) for lab, prob in preds if prob >= MIN_CONFIDENCE
                    ]

        # HUD
        which = "trained" if use_trained else "heuristic"
        cv2.putText(frame, f"{which}: {letter}", (20, 40),
                    cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 0), 2)

        # Phrase buffer fill
        fill = f"phrase buf: {len(seq_buf)}/{TARGET_LEN}"
        cv2.putText(frame, fill, (20, 75),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200, 200, 0), 1)

        # Top-3 phrase predictions
        y = 105
        for lab, prob in last_phrase_predictions:
            cv2.putText(frame, f"{lab}  {prob:.2f}", (20, y),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 200, 255), 2)
            y += 28

        cv2.putText(frame, "q=quit  h=toggle alphabet  c=clear phrase buf",
                    (20, frame.shape[0] - 15),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (200, 200, 200), 1)

        cv2.imshow("CommuniSign — alphabet + phrase test", frame)

        key = cv2.waitKey(1) & 0xFF
        if key == ord("q"):
            break
        if key == ord("h"):
            use_trained = not use_trained
            print(f"Switched to {'trained' if use_trained else 'heuristic'}")
        if key == ord("c"):
            seq_buf.clear()
            last_phrase_predictions = []
            print("Phrase buffer cleared.")

    cap.release()
    cv2.destroyAllWindows()
    extractor.close()


if __name__ == "__main__":
    main()
