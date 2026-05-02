"""
Live webcam test of the trained alphabet classifier — no Flask, no Flutter.
Imports the same modules the server uses, runs them on webcam frames,
overlays the prediction on the video feed.

Run from the server/ directory:
    python test_webcam.py

Press 'q' to quit. Press 'h' to toggle heuristic vs trained classifier.
"""
import cv2

from preprocessing.pipeline import PreProcessingPipeline
from preprocessing.histogram_eq import CLAHEProcessor
from preprocessing.noise_filter import GaussianFilter
from extraction.landmark_extractor import LandmarkExtractor
from classification.heuristic import HeuristicClassifier
from classification.tflite_classifier import TFLiteAlphabetClassifier


def main():
    # Same pipeline the server builds
    preprocessor = PreProcessingPipeline(steps=[
        CLAHEProcessor(clip_limit=2.0, tile_grid=(8, 8)),
        GaussianFilter(kernel_size=5),
    ])
    extractor = LandmarkExtractor(
        static_image_mode=False,
        max_num_hands=1,
        min_detection_confidence=0.7,
        min_tracking_confidence=0.7,
    )
    trained = TFLiteAlphabetClassifier(
        model_path="models/alphabet_model.tflite",
        label_encoder_path="models/label_encoder.pkl",
        confidence_threshold=0.6,
    )
    heuristic = HeuristicClassifier()

    use_trained = True
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Could not open webcam (device 0). Try device 1 if you have multiple cameras.")
        return

    print("Webcam opened. Press 'q' to quit, 'h' to toggle classifier.")

    while True:
        ok, frame = cap.read()
        if not ok:
            break

        frame = cv2.flip(frame, 1)  # mirror so it feels natural

        processed = preprocessor.process(frame)
        hands = extractor.extract(processed)

        label = "no hand"
        if hands:
            classifier = trained if use_trained else heuristic
            label = classifier.classify(hands[0])

        which = "trained" if use_trained else "heuristic"
        cv2.putText(frame, f"{which}: {label}", (20, 40),
                    cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 0), 2)
        cv2.putText(frame, "q=quit  h=toggle classifier", (20, 70),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200, 200, 200), 1)

        cv2.imshow("CommuniSign — alphabet classifier test", frame)

        key = cv2.waitKey(1) & 0xFF
        if key == ord("q"):
            break
        if key == ord("h"):
            use_trained = not use_trained
            print(f"Switched to {'trained' if use_trained else 'heuristic'}")

    cap.release()
    cv2.destroyAllWindows()
    extractor.close()


if __name__ == "__main__":
    main()
