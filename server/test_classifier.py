"""
Smoke test for TFLiteAlphabetClassifier — no Flask, no camera.
Verifies: model loads, label encoder loads, inference runs end-to-end on a synthetic input.

Run from the server/ directory:
    python test_classifier.py
"""
import numpy as np

from classification.tflite_classifier import TFLiteAlphabetClassifier


def make_fake_landmarks(seed: int = 0):
    """Generate 21 plausible-looking landmark dicts (random but in a hand-ish layout)."""
    rng = np.random.default_rng(seed)
    base = np.array([0.5, 0.5, 0.0])
    coords = base + rng.normal(0, 0.1, (21, 3))
    return [{"x": float(p[0]), "y": float(p[1]), "z": float(p[2])} for p in coords]


def main():
    clf = TFLiteAlphabetClassifier(
        model_path="models/alphabet_model.tflite",
        label_encoder_path="models/label_encoder.pkl",
        confidence_threshold=0.0,  # disable threshold so we always see a prediction
    )
    print("Classifier loaded.")
    print("Label set:", sorted(clf.idx_to_label.values()))

    print("\nRunning inference on 5 random fake hand landmarks:")
    for seed in range(5):
        landmarks = make_fake_landmarks(seed=seed)
        pred = clf.classify(landmarks)
        print(f"  seed={seed}: {pred}")

    print("\nIf each line printed a label, the pipeline works.")


if __name__ == "__main__":
    main()
