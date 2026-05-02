"""
85-d feature extractor for the LSTM phrase model.

Mirrors Phase 3 cell 7 of phase3_data_prep_and_eda.ipynb — the same body-frame
normalization that produced the training-time features. Any divergence here would
collapse model accuracy at inference, so this stays line-for-line with training.

Layout of the 85-d output vector:
    [0..63)   hand shape: 21 landmarks × (x,y,z), wrist-relative + unit-scaled
    [63..65)  hand wrist position (xy) in body frame
    [65..81)  8 face anchors (xy each) in body frame
    [81..85)  2 elbows (xy each) in body frame

Body frame: origin = shoulder midpoint, scale = inter-shoulder distance.
"""
from typing import Dict, List, Optional

import numpy as np


# Indices that match the training-time extraction.
# Face: nose tip, chin, lips top/bottom, mouth corners, eye outer corners
TARGET_FACE_IDX = [1, 152, 13, 14, 61, 291, 33, 263]
LEFT_SHOULDER_IDX = 11
RIGHT_SHOULDER_IDX = 12
LEFT_ELBOW_IDX = 13
RIGHT_ELBOW_IDX = 14

FEATURE_DIM = 63 + 2 + len(TARGET_FACE_IDX) * 2 + 2 * 2  # = 85


class BodyFrameNormalizer:
    """Stateless. Produces an 85-d feature vector per frame, or None if extraction fails."""

    def normalize(
        self,
        hand_landmarks: List[Dict],
        face_landmarks: Optional[List[Dict]],
        pose_landmarks: Optional[List[Dict]],
        hand_type: str = "right_hand",
    ) -> Optional[np.ndarray]:
        if hand_landmarks is None or len(hand_landmarks) != 21:
            return None
        if pose_landmarks is None or len(pose_landmarks) <= max(LEFT_ELBOW_IDX, RIGHT_ELBOW_IDX):
            return None

        # Body frame (shoulder midpoint origin, shoulder distance scale)
        sl = pose_landmarks[LEFT_SHOULDER_IDX]
        sr = pose_landmarks[RIGHT_SHOULDER_IDX]
        sl_xy = np.array([sl["x"], sl["y"]], dtype=np.float32)
        sr_xy = np.array([sr["x"], sr["y"]], dtype=np.float32)
        body_origin = (sl_xy + sr_xy) * 0.5
        body_scale = float(np.linalg.norm(sl_xy - sr_xy))
        if body_scale < 1e-6:
            return None

        def to_body(xy: np.ndarray) -> np.ndarray:
            return (xy - body_origin) / body_scale

        # Hand shape (63d): wrist-relative + unit-scaled
        hand = np.array(
            [[lm["x"], lm["y"], lm["z"]] for lm in hand_landmarks], dtype=np.float32
        )
        wrist_xyz = hand[0].copy()
        centered = hand - wrist_xyz
        max_d = float(np.linalg.norm(centered, axis=1).max())
        if max_d > 0:
            centered = centered / max_d
        hand_shape = centered.flatten()  # (63,)

        # Hand wrist xy in body frame (2d)
        wrist_body = to_body(np.array([wrist_xyz[0], wrist_xyz[1]], dtype=np.float32))

        # Face anchors in body frame (16d). Zero-fill any missing.
        face_features = np.zeros(len(TARGET_FACE_IDX) * 2, dtype=np.float32)
        if face_landmarks is not None and len(face_landmarks) > max(TARGET_FACE_IDX):
            for k, fi in enumerate(TARGET_FACE_IDX):
                fp = face_landmarks[fi]
                face_features[2 * k : 2 * k + 2] = to_body(
                    np.array([fp["x"], fp["y"]], dtype=np.float32)
                )

        # Elbows in body frame (4d)
        elbow_features = np.zeros(4, dtype=np.float32)
        for k, ei in enumerate([LEFT_ELBOW_IDX, RIGHT_ELBOW_IDX]):
            ep = pose_landmarks[ei]
            elbow_features[2 * k : 2 * k + 2] = to_body(
                np.array([ep["x"], ep["y"]], dtype=np.float32)
            )

        feats = np.concatenate(
            [hand_shape, wrist_body, face_features, elbow_features]
        ).astype(np.float32)
        assert feats.shape == (FEATURE_DIM,)

        # Mirror x for left-hand input — matches training-time canonicalization
        if hand_type == "left_hand":
            feats = feats.copy()
            feats[0:63:3] *= -1     # hand shape x components
            feats[63::2] *= -1      # body-frame x columns (wrist x, face x's, elbow x's)

        return feats
