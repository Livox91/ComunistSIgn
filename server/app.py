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
from extraction.holistic_extractor import HolisticExtractor
from extraction.normalizer import LandmarkNormalizer
from extraction.body_frame_normalizer import BodyFrameNormalizer
from classification.heuristic import HeuristicClassifier
from classification.tflite_classifier import TFLiteAlphabetClassifier
from classification.lstm_classifier import LSTMPhraseClassifier
from classification.motion_classifier import MotionClassifier
from postprocessing.buffer import GestureBuffer
from postprocessing.sequence_buffer import SequenceFeatureBuffer
from postprocessing.phrase_matcher import PhraseMatcher
from emotion.emotion_detector import EmotionDetector
from routes import register_routes


def create_app(config: Config = None) -> Flask:
    app = Flask(__name__)
    cfg = config or Config()
    app.cfg = cfg  # routes read config values from here

    # --- Preprocessing pipeline: CLAHE → Gaussian blur ---
    app.preprocessor = PreProcessingPipeline(steps=[
        CLAHEProcessor(clip_limit=cfg.CLAHE_CLIP_LIMIT, tile_grid=cfg.CLAHE_TILE_GRID),
        GaussianFilter(kernel_size=cfg.GAUSSIAN_KERNEL),
    ])

    # --- Landmark extraction ---
    # If phrase classification is enabled we use Holistic (hands + face + pose).
    # Otherwise we stick with the lighter Hands-only extractor.
    if cfg.USE_PHRASE_CLASSIFIER:
        app.landmark_extractor = HolisticExtractor(
            static_image_mode=cfg.STATIC_IMAGE_MODE,
            model_complexity=cfg.HOLISTIC_MODEL_COMPLEXITY,
            smooth_landmarks=cfg.HOLISTIC_SMOOTH_LANDMARKS,
            min_detection_confidence=cfg.MIN_DETECTION_CONFIDENCE,
            min_tracking_confidence=cfg.MIN_TRACKING_CONFIDENCE,
        )
        app.uses_holistic = True
        print("[app] Using HolisticExtractor (hands + face + pose)")
    else:
        app.landmark_extractor = LandmarkExtractor(
            static_image_mode=cfg.STATIC_IMAGE_MODE,
            max_num_hands=cfg.MAX_NUM_HANDS,
            min_detection_confidence=cfg.MIN_DETECTION_CONFIDENCE,
            min_tracking_confidence=cfg.MIN_TRACKING_CONFIDENCE,
        )
        app.uses_holistic = False
        print("[app] Using LandmarkExtractor (hands only — phrase classifier disabled)")

    # --- Landmark normalization ---
    app.normalizer = LandmarkNormalizer()
    app.body_frame_normalizer = BodyFrameNormalizer()

    # --- Alphabet classifier (TFLite, with heuristic as toggleable fallback) ---
    if cfg.USE_TRAINED_CLASSIFIER:
        try:
            app.classifier = TFLiteAlphabetClassifier(
                model_path=cfg.ALPHABET_MODEL_PATH,
                label_encoder_path=cfg.ALPHABET_LABEL_ENCODER_PATH,
                confidence_threshold=cfg.CONFIDENCE_THRESHOLD,
            )
            print(f"[app] Loaded alphabet classifier from {cfg.ALPHABET_MODEL_PATH}")
        except FileNotFoundError as e:
            print(f"[app] WARNING: {e} — falling back to HeuristicClassifier")
            app.classifier = HeuristicClassifier()
    else:
        app.classifier = HeuristicClassifier()
        print("[app] Using HeuristicClassifier (USE_TRAINED_CLASSIFIER=False)")

    # --- Phrase classifier (LSTM) ---
    app.phrase_classifier = None
    app.sequence_buffer = None
    if cfg.USE_PHRASE_CLASSIFIER:
        try:
            app.phrase_classifier = LSTMPhraseClassifier(
                model_path=cfg.PHRASE_MODEL_PATH,
                label_encoder_path=cfg.PHRASE_LABEL_ENCODER_PATH,
                target_len=cfg.PHRASE_TARGET_LEN,
                feature_dim=cfg.PHRASE_FEATURE_DIM,
            )
            app.sequence_buffer = SequenceFeatureBuffer(
                target_len=cfg.PHRASE_TARGET_LEN,
                feature_dim=cfg.PHRASE_FEATURE_DIM,
            )
            print(f"[app] Loaded phrase classifier from {cfg.PHRASE_MODEL_PATH}")
        except FileNotFoundError as e:
            print(f"[app] WARNING: {e} — phrase recognition disabled")

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
