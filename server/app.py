"""
Flask app factory with dependency injection.
All components are assembled here and attached to the app object.
"""
from flask import Flask

from config import Config
from preprocessing.pipeline import PreProcessingPipeline
from preprocessing.histogram_eq import CLAHEProcessor
from preprocessing.noise_filter import GaussianFilter
from extraction.landmark_extractor import LandmarkExtractor
from extraction.normalizer import LandmarkNormalizer
from classification.heuristic import HeuristicClassifier
from classification.tflite_classifier import TFLiteAlphabetClassifier
from classification.motion_classifier import MotionClassifier
from postprocessing.buffer import GestureBuffer
from postprocessing.phrase_matcher import PhraseMatcher
from emotion.emotion_detector import EmotionDetector
from routes import register_routes


def create_app(config: Config = None) -> Flask:
    app = Flask(__name__)
    cfg = config or Config()

    # --- Preprocessing pipeline: CLAHE → Gaussian blur ---
    app.preprocessor = PreProcessingPipeline(steps=[
        CLAHEProcessor(clip_limit=cfg.CLAHE_CLIP_LIMIT, tile_grid=cfg.CLAHE_TILE_GRID),
        GaussianFilter(kernel_size=cfg.GAUSSIAN_KERNEL),
    ])

    # --- Landmark extraction ---
    app.landmark_extractor = LandmarkExtractor(
        static_image_mode=cfg.STATIC_IMAGE_MODE,
        max_num_hands=cfg.MAX_NUM_HANDS,
        min_detection_confidence=cfg.MIN_DETECTION_CONFIDENCE,
        min_tracking_confidence=cfg.MIN_TRACKING_CONFIDENCE,
    )

    # --- Landmark normalization ---
    app.normalizer = LandmarkNormalizer()

    # --- Classifier: trained TFLite MLP, with heuristic as toggleable fallback ---
    if cfg.USE_TRAINED_CLASSIFIER:
        try:
            app.classifier = TFLiteAlphabetClassifier(
                model_path=cfg.ALPHABET_MODEL_PATH,
                label_encoder_path=cfg.ALPHABET_LABEL_ENCODER_PATH,
                confidence_threshold=cfg.CONFIDENCE_THRESHOLD,
            )
            print(f"[app] Loaded TFLite classifier from {cfg.ALPHABET_MODEL_PATH}")
        except FileNotFoundError as e:
            print(f"[app] WARNING: {e} — falling back to HeuristicClassifier")
            app.classifier = HeuristicClassifier()
    else:
        app.classifier = HeuristicClassifier()
        print("[app] Using HeuristicClassifier (USE_TRAINED_CLASSIFIER=False)")

    # --- Motion classifier for J/Z (runs alongside static classifier) ---
    app.motion_classifier = MotionClassifier(history_size=15, min_frames=8)

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
