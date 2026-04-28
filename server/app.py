"""
Flask app factory with dependency injection.
All components are assembled here and attached to the app object.
"""
from flask import Flask

from config import Config
from preprocessing.pipeline import PreProcessingPipeline
from extraction.landmark_extractor import LandmarkExtractor
from extraction.normalizer import LandmarkNormalizer
from classification.heuristic import HeuristicClassifier
from postprocessing.buffer import GestureBuffer
from postprocessing.phrase_matcher import PhraseMatcher
from emotion.emotion_detector import EmotionDetector
from routes import register_routes


def create_app(config: Config = None) -> Flask:
    app = Flask(__name__)
    cfg = config or Config()

    # --- Preprocessing pipeline (empty for now — Phase 1 adds CLAHE + Gaussian) ---
    app.preprocessor = PreProcessingPipeline(steps=[])

    # --- Landmark extraction ---
    app.landmark_extractor = LandmarkExtractor(
        static_image_mode=cfg.STATIC_IMAGE_MODE,
        max_num_hands=cfg.MAX_NUM_HANDS,
        min_detection_confidence=cfg.MIN_DETECTION_CONFIDENCE,
        min_tracking_confidence=cfg.MIN_TRACKING_CONFIDENCE,
    )

    # --- Landmark normalization ---
    app.normalizer = LandmarkNormalizer()

    # --- Classifier (heuristic for now — Phase 5 swaps to TFLite) ---
    app.classifier = HeuristicClassifier()

    # --- Postprocessing ---
    app.gesture_buffer = GestureBuffer(
        max_size=cfg.BUFFER_MAX_SIZE,
        max_age=cfg.BUFFER_MAX_AGE,
        debounce_threshold=cfg.DEBOUNCE_THRESHOLD,
    )
    app.phrase_matcher = PhraseMatcher()

    # --- Emotion detection ---
    app.emotion_detector = EmotionDetector(use_mtcnn=True)

    # --- Routes ---
    register_routes(app)

    return app


if __name__ == "__main__":
    cfg = Config()
    app = create_app(cfg)
    app.run(
        host=cfg.HOST,
        port=cfg.PORT,
        debug=cfg.DEBUG,
        threaded=True,
    )
