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
    STATIC_IMAGE_MODE = False
    MAX_NUM_HANDS = 2
    MIN_DETECTION_CONFIDENCE = 0.7
    MIN_TRACKING_CONFIDENCE = 0.7

    # Preprocessing
    CLAHE_CLIP_LIMIT = 2.0
    CLAHE_TILE_GRID = (8, 8)
    GAUSSIAN_KERNEL = 5

    # GestureBuffer
    BUFFER_MAX_SIZE = 15
    BUFFER_MAX_AGE = 5.0
    DEBOUNCE_THRESHOLD = 3

    # Classification
    CONFIDENCE_THRESHOLD = 0.6
    MODEL_PATH = "models/alphabet_model.tflite"
