"""
All configurable values for the server.
Change values here instead of scattering magic numbers throughout the codebase.
"""


class Config:
    # Flask
    HOST = "0.0.0.0"
    PORT = 5000
    DEBUG = True

    # MediaPipe Hands
    # True = treat each frame independently (required for discrete JPEG uploads from phone)
    # False = tracking mode (only suitable for a continuous video stream)
    STATIC_IMAGE_MODE = True
    MAX_NUM_HANDS = 2
    MIN_DETECTION_CONFIDENCE = 0.7
    MIN_TRACKING_CONFIDENCE = 0.7

    # Preprocessing
    GAMMA_TARGET_MEAN = 128.0       # adaptive gamma target luminance (0-255)
    CLAHE_CLIP_LIMIT = 2.0
    CLAHE_TILE_GRID = (8, 8)
    BILATERAL_D = 9                 # bilateral filter neighbourhood diameter
    BILATERAL_SIGMA_COLOR = 75      # colour similarity range
    BILATERAL_SIGMA_SPACE = 75      # spatial range

    # GestureBuffer
    BUFFER_MAX_SIZE = 15
    BUFFER_MAX_AGE = 5.0
    DEBOUNCE_THRESHOLD = 3

    # Classification — alphabet
    CONFIDENCE_THRESHOLD = 0.6
    USE_TRAINED_CLASSIFIER = True  # False to fall back to the rule-based heuristic
    ALPHABET_MODEL_PATH = "models/alphabet_model.tflite"
    ALPHABET_LABEL_ENCODER_PATH = "models/label_encoder.pkl"

    # Classification — phrases (LSTM)
    USE_PHRASE_CLASSIFIER = True
    PHRASE_MODEL_PATH = "models/phrases_model.tflite"
    PHRASE_LABEL_ENCODER_PATH = "models/phrases_label_encoder.pkl"
    PHRASE_TARGET_LEN = 45          # retrained with longer sequences
    PHRASE_FEATURE_DIM = 127        # 85 base + 42 hand-landmark velocity
    PHRASE_MIN_FRAMES = 12          # predict once this many frames are buffered
    PHRASE_TOP_K = 3
    PHRASE_MIN_CONFIDENCE = 0.35    # slightly higher threshold with better model

    # Holistic extractor (replaces Hands when phrase recognition is enabled)
    HOLISTIC_MODEL_COMPLEXITY = 1   # 0 fastest, 2 best
    HOLISTIC_SMOOTH_LANDMARKS = True
