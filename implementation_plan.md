# CommuniSign — Implementation Blueprint

> **Goal**: Replace the hard-coded heuristic gesture classifier with a trained ML model,
> add DIP (Digital Image Processing) preprocessing, and restructure the codebase
> using Dependency Injection for maintainability.

---

## Phase 0 — Project Restructuring & DI Foundation

**Duration**: ~1 day  
**Why first**: Every later phase plugs into this structure.

### 0.1 New server-side folder layout

```
server/
├── app.py                    # Flask app factory + DI wiring
├── config.py                 # All configurable values (thresholds, paths, ports)
├── preprocessing/
│   ├── __init__.py
│   ├── base.py               # Abstract PreProcessor interface
│   ├── histogram_eq.py       # CLAHE implementation
│   ├── noise_filter.py       # Gaussian / bilateral filter
│   └── pipeline.py           # Chains multiple preprocessors
├── extraction/
│   ├── __init__.py
│   ├── landmark_extractor.py # Wraps MediaPipe Hands
│   └── normalizer.py         # Landmark normalization (wrist-relative, unit scale)
├── classification/
│   ├── __init__.py
│   ├── base.py               # Abstract GestureClassifier interface
│   ├── heuristic.py          # Current classify_gesture() wrapped in a class
│   ├── tflite_classifier.py  # Trained model classifier (added in Phase 5)
│   └── motion_classifier.py  # Optical flow classifier for J/Z (added in Phase 1.5)
├── postprocessing/
│   ├── __init__.py
│   ├── buffer.py             # GestureBuffer (existing, cleaned up)
│   └── phrase_matcher.py     # match_phrase() as a class
├── emotion/
│   ├── __init__.py
│   └── emotion_detector.py   # Existing FER logic wrapped
├── models/                   # Trained model files (.tflite, .h5)
│   └── .gitkeep
└── requirements.txt
```

### 0.2 Define abstract interfaces

```python
# preprocessing/base.py
from abc import ABC, abstractmethod
import numpy as np

class PreProcessor(ABC):
    @abstractmethod
    def process(self, frame: np.ndarray) -> np.ndarray:
        """Takes a BGR frame, returns a processed BGR frame."""
        pass
```

```python
# classification/base.py
from abc import ABC, abstractmethod
from typing import List, Dict

class GestureClassifier(ABC):
    @abstractmethod
    def classify(self, landmarks: List[Dict]) -> str:
        """Takes normalized landmarks, returns a gesture label."""
        pass
```

### 0.3 App factory with DI wiring

```python
# app.py
from flask import Flask
from preprocessing.pipeline import PreProcessingPipeline
from preprocessing.histogram_eq import CLAHEProcessor
from preprocessing.noise_filter import GaussianFilter
from classification.heuristic import HeuristicClassifier
from config import Config

def create_app():
    app = Flask(__name__)
    cfg = Config()

    # Assemble the preprocessing pipeline
    preprocessors = [CLAHEProcessor(), GaussianFilter(kernel_size=cfg.GAUSSIAN_KERNEL)]
    app.preprocessor = PreProcessingPipeline(preprocessors)

    # Start with heuristic; swap to TFLite in Phase 5
    app.classifier = HeuristicClassifier()

    # Register routes
    from routes import register_routes
    register_routes(app)

    return app
```

### 0.4 Wrap existing heuristic in the new interface

Move the current `classify_gesture()`, `calculate_angle()`, `distance()`, `GestureBuffer`, and `match_phrase()` from the monolithic `server.py` into their respective modules listed above. The heuristic classifier stays fully functional — nothing breaks at this point.

### 0.5 Deliverable checklist

- [ ] New folder structure created
- [ ] `server.py` split into modules
- [ ] App starts with `python app.py` and `/process` + `/process/emotion` still work exactly as before
- [ ] No behavioural change — purely structural refactor

---

## Phase 1 — DIP Preprocessing Pipeline

**Duration**: ~1–2 days  
**Depends on**: Phase 0

### 1.1 CLAHE (Histogram Equalization)

```python
# preprocessing/histogram_eq.py
import cv2
import numpy as np
from preprocessing.base import PreProcessor

class CLAHEProcessor(PreProcessor):
    def __init__(self, clip_limit: float = 2.0, tile_grid: tuple = (8, 8)):
        self.clahe = cv2.createCLAHE(clipLimit=clip_limit, tileGridSize=tile_grid)

    def process(self, frame: np.ndarray) -> np.ndarray:
        # Convert to LAB, apply CLAHE to L channel, convert back
        lab = cv2.cvtColor(frame, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        l = self.clahe.apply(l)
        lab = cv2.merge([l, a, b])
        return cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)
```

**Why LAB instead of grayscale?** Applying CLAHE to the L (lightness) channel preserves colour information while normalizing brightness — important because MediaPipe's hand detector uses colour cues internally.

### 1.2 Gaussian Filter

```python
# preprocessing/noise_filter.py
import cv2
import numpy as np
from preprocessing.base import PreProcessor

class GaussianFilter(PreProcessor):
    def __init__(self, kernel_size: int = 5):
        self.kernel_size = kernel_size

    def process(self, frame: np.ndarray) -> np.ndarray:
        return cv2.GaussianBlur(frame, (self.kernel_size, self.kernel_size), 0)
```

### 1.3 Pipeline chaining

```python
# preprocessing/pipeline.py
import numpy as np
from typing import List
from preprocessing.base import PreProcessor

class PreProcessingPipeline(PreProcessor):
    def __init__(self, steps: List[PreProcessor]):
        self.steps = steps

    def process(self, frame: np.ndarray) -> np.ndarray:
        for step in self.steps:
            frame = step.process(frame)
        return frame
```

### 1.4 Integration into the `/process` endpoint

```python
# In the route handler (simplified)
@app.route('/process', methods=['POST'])
def process_frame():
    file = request.files['image']
    img = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)

    # NEW: run DIP preprocessing
    img = app.preprocessor.process(img)

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    results = hands.process(img_rgb)
    # ... rest unchanged
```

### 1.5 Deliverable checklist

- [ ] CLAHE and Gaussian filter implemented and unit-tested with sample images
- [ ] Pipeline chains them in order: CLAHE → Gaussian
- [ ] `/process` endpoint uses the pipeline before MediaPipe
- [ ] Verified that landmark detection accuracy improves (or at least doesn't degrade) in low-light test images

---

## Phase 1.5 — Optical Flow for Motion-Based Letters (J and Z)

**Duration**: ~1–2 days  
**Depends on**: Phase 0, Phase 1

Letters **J** and **Z** are the only two ASL alphabet signs that involve motion — J is a downward-curving arc drawn with the pinky, Z is a zigzag drawn with the index finger. The static per-frame classifier from Phase 4 cannot detect them because it only sees a single snapshot. This phase adds a **temporal motion branch** that runs in parallel with the static classifier.

### 1.5.1 Frame history buffer

The server needs to remember the last N frames' landmark positions to compute movement.

```python
# classification/motion_classifier.py
import numpy as np
from collections import deque
from typing import Optional, List, Dict

class MotionClassifier:
    """
    Detects J and Z by tracking the index fingertip (landmark 8)
    and pinky fingertip (landmark 20) across consecutive frames
    using simplified optical flow on landmark positions.
    """

    def __init__(self, history_size: int = 15, min_frames: int = 8):
        self.history_size = history_size
        self.min_frames = min_frames  # minimum frames to attempt classification
        self.index_history = deque(maxlen=history_size)  # landmark 8 positions
        self.pinky_history = deque(maxlen=history_size)  # landmark 20 positions
        self.finger_states_history = deque(maxlen=history_size)  # which fingers are up

    def update(self, landmarks: List[Dict], finger_states: Dict[str, bool]):
        """Call every frame with current landmarks and finger extension states."""
        self.index_history.append((landmarks[8]['x'], landmarks[8]['y']))
        self.pinky_history.append((landmarks[20]['x'], landmarks[20]['y']))
        self.finger_states_history.append(finger_states)

    def classify(self) -> Optional[str]:
        """Returns 'J', 'Z', or None if no motion letter detected."""
        if len(self.index_history) < self.min_frames:
            return None

        j = self._check_j()
        if j:
            self.clear()
            return "J"

        z = self._check_z()
        if z:
            self.clear()
            return "Z"

        return None

    def clear(self):
        self.index_history.clear()
        self.pinky_history.clear()
        self.finger_states_history.clear()
```

### 1.5.2 J detection — downward arc with pinky

J is the letter I (pinky extended, all others curled) followed by a downward-curving motion.

```python
    def _check_j(self) -> bool:
        """J = pinky-only hand tracing a downward arc."""
        points = list(self.pinky_history)
        states = list(self.finger_states_history)

        # Verify pinky was extended and others curled for most of the sequence
        pinky_only_count = sum(
            1 for s in states
            if s.get('pinky', False)
            and not s.get('index', False)
            and not s.get('middle', False)
            and not s.get('ring', False)
        )
        if pinky_only_count < len(states) * 0.6:
            return False

        # Compute displacement vectors between consecutive frames
        dx = [points[i+1][0] - points[i][0] for i in range(len(points)-1)]
        dy = [points[i+1][1] - points[i][1] for i in range(len(points)-1)]

        total_dy = sum(dy)
        total_dx = sum(dx)

        # J motion: net downward (positive y in image coords) with some lateral curve
        if total_dy > 0.08 and abs(total_dx) > 0.03:
            return True

        return False
```

### 1.5.3 Z detection — zigzag with index finger

Z is drawn with the index finger tracing a Z-shape: right, then diagonal-left-down, then right.

```python
    def _check_z(self) -> bool:
        """Z = index finger tracing a zigzag (right, diag-left-down, right)."""
        points = list(self.index_history)
        states = list(self.finger_states_history)

        # Verify index was extended for most of the sequence
        index_up_count = sum(1 for s in states if s.get('index', False))
        if index_up_count < len(states) * 0.6:
            return False

        # Split trajectory into 3 roughly equal segments
        n = len(points)
        seg_len = n // 3
        if seg_len < 2:
            return False

        seg1 = points[:seg_len]
        seg2 = points[seg_len:2*seg_len]
        seg3 = points[2*seg_len:]

        def segment_direction(seg):
            dx = seg[-1][0] - seg[0][0]
            dy = seg[-1][1] - seg[0][1]
            return dx, dy

        dx1, dy1 = segment_direction(seg1)
        dx2, dy2 = segment_direction(seg2)
        dx3, dy3 = segment_direction(seg3)

        # Segment 1: rightward (dx > 0)
        # Segment 2: leftward and downward (dx < 0, dy > 0)
        # Segment 3: rightward (dx > 0)
        if (dx1 > 0.03 and dx2 < -0.03 and dy2 > 0.03 and dx3 > 0.03):
            return True

        return False
```

### 1.5.4 Integration into the `/process` route

The motion classifier runs **alongside** the static classifier, not instead of it. Every frame, both run. If the motion classifier detects J or Z, that takes priority.

```python
# In app.py — add to DI wiring
from classification.motion_classifier import MotionClassifier
app.motion_classifier = MotionClassifier(history_size=15, min_frames=8)

# In the /process route — after extracting landmarks
def get_finger_states(landmarks):
    """Quick check of which fingers are extended."""
    def extended(tip, pip):
        return landmarks[tip]['y'] < landmarks[pip]['y'] - 0.05
    return {
        'index': extended(8, 6),
        'middle': extended(12, 10),
        'ring': extended(16, 14),
        'pinky': extended(20, 18),
    }

# Inside the per-hand loop:
finger_states = get_finger_states(landmarks)
app.motion_classifier.update(landmarks, finger_states)

motion_gesture = app.motion_classifier.classify()
if motion_gesture:
    detected.append(motion_gesture)
    app.gesture_buffer.add(motion_gesture)
else:
    # Fall back to static classifier
    gesture = app.classifier.classify(normalized)
    if gesture != "NOTHING":
        detected.append(gesture)
        app.gesture_buffer.add(gesture)
```

**DIP concepts**: Optical flow / motion estimation — tracking the displacement of feature points across consecutive frames to detect temporal patterns. This is a classical DIP technique for motion analysis, applied here to landmark trajectories rather than raw pixel patches.

### 1.5.5 Deliverable checklist

- [ ] `MotionClassifier` implemented with J and Z detection
- [ ] Integrated into `/process` route as a parallel branch
- [ ] Tested by drawing J and Z in front of the camera
- [ ] Static letters (A–Y) still work exactly as before
- [ ] Motion detection thresholds tuned empirically

---

## Phase 2 — Landmark Normalization

**Duration**: ~0.5 day  
**Depends on**: Phase 0

### 2.1 Wrist-relative normalization

```python
# extraction/normalizer.py
import numpy as np
from typing import List, Dict, Optional

class LandmarkNormalizer:
    def __init__(self):
        self._prev_coords: Optional[np.ndarray] = None

    def normalize(self, landmarks: List[Dict], include_velocity: bool = False) -> np.ndarray:
        """
        1. Translate so wrist (landmark 0) is at origin
        2. Scale so max distance from wrist = 1.0
        3. Optionally append per-landmark velocity (delta from previous frame)

        Returns:
          - (63,) if include_velocity=False  — position only
          - (126,) if include_velocity=True  — position (63) + velocity (63)
        """
        wrist = np.array([landmarks[0]['x'], landmarks[0]['y'], landmarks[0]['z']])
        coords = np.array([[lm['x'], lm['y'], lm['z']] for lm in landmarks])
        coords -= wrist                              # translate
        max_dist = np.max(np.linalg.norm(coords, axis=1))
        if max_dist > 0:
            coords /= max_dist                        # scale

        position = coords.flatten()                    # (63,)

        if not include_velocity:
            self._prev_coords = coords
            return position

        # Compute velocity: difference from previous frame's normalized coords
        if self._prev_coords is not None:
            velocity = (coords - self._prev_coords).flatten()  # (63,)
        else:
            velocity = np.zeros(63)  # first frame has no velocity

        self._prev_coords = coords
        return np.concatenate([position, velocity])    # (126,)

    def reset(self):
        """Call when switching users or starting a new session."""
        self._prev_coords = None
```

**Why this matters**: Without normalization the model sees different feature values depending on how far the user's hand is from the camera. After normalization, a fist looks the same whether the hand is 30 cm or 80 cm from the lens.

**Why velocity matters**: The position-only (63,) vector treats every frame as a static snapshot — it cannot distinguish J from I or Z from a static pointed finger, because those letter-pairs share the same hand shape and differ only in motion. Appending velocity (Δx, Δy, Δz per landmark since the previous frame) gives the classifier a (126,) vector that captures both shape and movement. This means the trained ML model itself can learn to detect J and Z rather than relying entirely on the hardcoded `MotionClassifier` thresholds from Phase 1.5. In practice, Phase 1.5's rule-based motion detector acts as a fallback, while the 126-d model is the primary path.

### 2.2 Deliverable checklist

- [ ] `LandmarkNormalizer` tested with mock landmark dicts (both 63-d and 126-d output)
- [ ] Velocity computation verified: zero on first frame, correct deltas on subsequent frames
- [ ] Integrated into `/process` — normalized landmarks are passed to the classifier

---

## Phase 3 — Dataset Acquisition & Preparation

**Duration**: ~2 days  
**Depends on**: Nothing (can run in parallel with Phases 0–2)

### 3.1 Download datasets

```bash
# Install Kaggle CLI (if needed)
pip install kaggle

# Alphabet + fingerspelling (landmark format)
kaggle competitions download -c asl-fingerspelling -p datasets/fingerspelling

# Isolated words (landmark format)
kaggle competitions download -c asl-signs -p datasets/isolated_signs
```

### 3.2 Explore & understand the data

| Dataset | Format | Columns of interest |
|---------|--------|---------------------|
| ASL Fingerspelling | `.parquet` files | `sequence_id`, `frame`, `x_*`, `y_*`, `z_*` (543 landmarks per frame), `phrase` |
| ASL Isolated Signs | `.parquet` files | `sequence_id`, `frame`, `x_*`, `y_*`, `z_*` (543 landmarks per frame), `sign` (label) |

Both datasets provide **MediaPipe landmark coordinates** directly — no image preprocessing needed for training. The 543 landmarks come from MediaPipe Holistic (hands + pose + face); for our use case we extract only the **42 hand landmarks** (21 per hand × 2).

### 3.3 Preprocessing script

```python
# training/prepare_data.py
import pandas as pd
import numpy as np

# --- Fingerspelling (alphabet) ---
df = pd.read_parquet("datasets/fingerspelling/train.parquet")

# Extract only right-hand landmarks (columns x_right_hand_0 .. z_right_hand_20)
hand_cols = [f"{axis}_right_hand_{i}" for i in range(21) for axis in ("x", "y", "z")]
df_hand = df[["sequence_id", "frame"] + hand_cols + ["phrase"]].dropna(subset=hand_cols)

# Normalize per frame (wrist-relative, unit scale)
def normalize_frame(row):
    coords = row[hand_cols].values.astype(float).reshape(21, 3)
    wrist = coords[0]
    coords -= wrist
    max_d = np.max(np.linalg.norm(coords, axis=1))
    if max_d > 0:
        coords /= max_d
    return coords.flatten()

df_hand["features"] = df_hand.apply(normalize_frame, axis=1)
# Save processed data
df_hand[["sequence_id", "frame", "features", "phrase"]].to_pickle("training/data/fingerspelling_processed.pkl")
```

Repeat similarly for isolated signs.

### 3.4 Train/validation/test split

```python
from sklearn.model_selection import train_test_split

sequences = df_hand["sequence_id"].unique()
train_seq, temp_seq = train_test_split(sequences, test_size=0.2, random_state=42)
val_seq, test_seq   = train_test_split(temp_seq, test_size=0.5, random_state=42)
```

### 3.5 Deliverable checklist

- [ ] Both datasets downloaded and unzipped
- [ ] Preprocessing script produces `.pkl` files with normalized (63,) feature vectors per frame
- [ ] Train/val/test split saved

---

## Phase 4 — Model Training

**Duration**: ~3–5 days  
**Depends on**: Phase 3

### 4.0 Class imbalance diagnosis (do this FIRST)

The Google ASL datasets are heavily imbalanced — common signs like "A" or "E" may have 10× more samples than rare signs like "Z" or "J". Training on raw data will produce a model that is great at common letters and terrible at rare ones.

**Step 1 — Inspect the distribution:**

```python
# training/diagnose_imbalance.py
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

df = pd.read_pickle("training/data/fingerspelling_processed.pkl")
class_counts = df['phrase'].value_counts()

print("=== Class distribution ===")
print(class_counts)
print(f"\nMax/min ratio: {class_counts.max() / class_counts.min():.1f}x")
print(f"Classes with < 100 samples: {(class_counts < 100).sum()}")

# Visual check
plt.figure(figsize=(14, 5))
class_counts.plot(kind='bar')
plt.title("Samples per class")
plt.ylabel("Count")
plt.tight_layout()
plt.savefig("training/logs/class_distribution.png")
plt.show()
```

If the max/min ratio is > 5×, you **must** apply at least one of the fixes below. Do not skip this step.

### 4.1 Compute class weights

Class weights tell the loss function to penalize mistakes on rare classes more heavily. This is the simplest and most effective fix for imbalance.

```python
# training/compute_weights.py
from sklearn.utils.class_weight import compute_class_weight
import numpy as np

classes = np.unique(y_train)
weights = compute_class_weight('balanced', classes=classes, y=y_train)
class_weight_dict = dict(zip(classes, weights))

print("Class weights:")
for cls, w in sorted(class_weight_dict.items(), key=lambda x: x[1], reverse=True):
    print(f"  {cls}: {w:.3f}")

# Example output:
#   Z: 4.231  (rare → high weight)
#   J: 3.817
#   A: 0.412  (common → low weight)
```

These weights are passed directly into `model.fit()` — see 4.3 below.

### 4.2 Optional: resample the dataset

If class weights alone don't close the gap, combine with resampling:

```python
# training/resample.py
from imblearn.over_sampling import SMOTE

# SMOTE generates synthetic samples for minority classes
smote = SMOTE(random_state=42, k_neighbors=5)
X_train_resampled, y_train_resampled = smote.fit_resample(X_train, y_train)

print(f"Before: {len(X_train)} samples")
print(f"After:  {len(X_train_resampled)} samples")
```

Alternatively, use simple **random oversampling** (duplicate minority samples) or **undersampling** (drop majority samples) if SMOTE produces artifacts on landmark data.

### 4.3 Model A — Static alphabet classifier

```python
# training/train_alphabet.py
import tensorflow as tf
from tensorflow import keras
import numpy as np

# --- Feature dimension ---
# 63  = position only (21 landmarks × 3 coords)
# 126 = position (63) + velocity (63) — enables the model to detect J/Z motion
INPUT_DIM = 126  # use 63 if skipping velocity features

# --- Architecture ---
model = keras.Sequential([
    keras.layers.Input(shape=(INPUT_DIM,)),
    keras.layers.Dense(256, activation='relu'),
    keras.layers.BatchNormalization(),
    keras.layers.Dropout(0.3),
    keras.layers.Dense(128, activation='relu'),
    keras.layers.BatchNormalization(),
    keras.layers.Dropout(0.3),
    keras.layers.Dense(64, activation='relu'),
    keras.layers.Dense(29, activation='softmax')  # A-Z + SPACE + DELETE + NOTHING
])

# --- Optimizer with learning rate scheduling ---
initial_lr = 1e-3
optimizer = keras.optimizers.Adam(learning_rate=initial_lr)

model.compile(
    optimizer=optimizer,
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

# --- Data augmentation on landmarks ---
def augment_landmarks(features, label):
    # Random rotation ±15°
    angle = tf.random.uniform([], -0.26, 0.26)  # radians
    cos_a, sin_a = tf.cos(angle), tf.sin(angle)
    coords = tf.reshape(features, (21, 3))
    x_rot = coords[:, 0] * cos_a - coords[:, 1] * sin_a
    y_rot = coords[:, 0] * sin_a + coords[:, 1] * cos_a
    coords = tf.stack([x_rot, y_rot, coords[:, 2]], axis=1)
    # Random scale ±10%
    scale = tf.random.uniform([], 0.9, 1.1)
    coords *= scale
    # Random translation ±5%
    shift = tf.random.uniform([3], -0.05, 0.05)
    coords += shift
    return tf.reshape(coords, (63,)), label

# --- tf.data pipeline ---
train_ds = tf.data.Dataset.from_tensor_slices((X_train, y_train))
train_ds = train_ds.map(augment_landmarks).shuffle(10000).batch(256).prefetch(tf.data.AUTOTUNE)
val_ds   = tf.data.Dataset.from_tensor_slices((X_val, y_val)).batch(256)

# --- Callbacks ---
callbacks = [
    # Stop if val_loss doesn't improve for 7 epochs, restore best weights
    keras.callbacks.EarlyStopping(
        monitor='val_loss',
        patience=7,
        restore_best_weights=True,
        verbose=1
    ),
    # Reduce LR by 50% if val_loss plateaus for 3 epochs
    keras.callbacks.ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.5,
        patience=3,
        min_lr=1e-6,
        verbose=1
    ),
    # Save the best model checkpoint
    keras.callbacks.ModelCheckpoint(
        'training/checkpoints/best_alphabet.h5',
        monitor='val_accuracy',
        save_best_only=True,
        verbose=1
    ),
    # Log to CSV for later analysis
    keras.callbacks.CSVLogger('training/logs/alphabet_training.csv'),
]

# --- Train with class weights ---
history = model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=50,                          # higher ceiling — EarlyStopping will cut it short
    class_weight=class_weight_dict,     # from step 4.1
    callbacks=callbacks
)

model.save("server/models/alphabet_model.h5")
```

**What the callbacks do:**
- `EarlyStopping(patience=7)` — if validation loss doesn't improve for 7 consecutive epochs, training stops and the weights revert to the best checkpoint. This prevents overfitting.
- `ReduceLROnPlateau(patience=3, factor=0.5)` — if validation loss stalls for 3 epochs, the learning rate is halved. This lets the model escape plateaus by taking smaller gradient steps. The LR will drop from 1e-3 → 5e-4 → 2.5e-4 → ... down to a floor of 1e-6.
- `ModelCheckpoint` — saves the best weights to disk so you never lose a good model to a later bad epoch.
- `CSVLogger` — writes per-epoch loss/accuracy to a CSV for plotting and report figures.

### 4.4 Per-class evaluation (confusion matrix)

Overall accuracy hides per-class failures. A model at 92% accuracy might be 0% on J and Z. You must check per-class performance.

```python
# training/evaluate.py
from sklearn.metrics import classification_report, confusion_matrix
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np

LABELS = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ") + ["SPACE", "DELETE", "NOTHING"]

y_pred = np.argmax(model.predict(X_test), axis=1)

# Per-class precision, recall, F1
report = classification_report(y_test, y_pred, target_names=LABELS, output_dict=True)
print(classification_report(y_test, y_pred, target_names=LABELS))

# Find weak classes (F1 < 0.80)
weak_classes = [cls for cls, metrics in report.items()
                if isinstance(metrics, dict) and metrics.get('f1-score', 1.0) < 0.80]
print(f"\n⚠️  Weak classes (F1 < 0.80): {weak_classes}")

# Confusion matrix heatmap
cm = confusion_matrix(y_test, y_pred)
plt.figure(figsize=(16, 14))
sns.heatmap(cm, annot=True, fmt='d', xticklabels=LABELS, yticklabels=LABELS, cmap='Blues')
plt.title("Confusion Matrix — Alphabet Classifier")
plt.xlabel("Predicted")
plt.ylabel("Actual")
plt.tight_layout()
plt.savefig("training/logs/confusion_matrix.png", dpi=150)
plt.show()

# Identify the most confused pairs
for i in range(len(LABELS)):
    for j in range(len(LABELS)):
        if i != j and cm[i][j] > cm[i][i] * 0.1:  # misclassified > 10% of true count
            print(f"  {LABELS[i]} → {LABELS[j]}: {cm[i][j]} misclassifications "
                  f"({cm[i][j]/cm[i].sum()*100:.1f}% of {LABELS[i]})")
```

This will print something like:
```
  G → L: 34 misclassifications (12.3% of G)
  M → S: 28 misclassifications (9.8% of M)
```

These confused pairs tell you exactly where the model is weakest.

### 4.5 Convert to TensorFlow Lite

```python
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]  # int8 quantization for speed
tflite_model = converter.convert()

with open("server/models/alphabet_model.tflite", "wb") as f:
    f.write(tflite_model)

# Verify the TFLite model produces the same outputs
interpreter = tf.lite.Interpreter(model_path="server/models/alphabet_model.tflite")
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Test on a few samples
for i in range(5):
    interpreter.set_tensor(input_details[0]['index'], X_test[i:i+1].astype(np.float32))
    interpreter.invoke()
    tflite_pred = np.argmax(interpreter.get_tensor(output_details[0]['index']))
    keras_pred = np.argmax(model.predict(X_test[i:i+1], verbose=0))
    assert tflite_pred == keras_pred, f"TFLite/Keras mismatch on sample {i}"
print("✓ TFLite model verified — outputs match Keras model")
```

### 4.6 Model B — Sequence model for phrases

For recognizing multi-frame gesture sequences as whole words/signs.

#### 4.6.1 Data preparation for the Isolated Signs dataset

The Isolated Signs dataset has a different structure from the fingerspelling dataset. Each row is one frame of a recorded sign, grouped by `sequence_id`. The label column is `sign` (an integer index), and a separate `train.csv` maps each `sequence_id` to its sign label.

```python
# training/prepare_phrases.py
import pandas as pd
import numpy as np
import os
from pathlib import Path

# --- Load label mapping ---
labels_df = pd.read_csv("datasets/isolated_signs/train.csv")
# columns: sequence_id, sign (integer label)

# --- Load parquet files ---
# The dataset is split into multiple parquet files, one per sequence
parquet_dir = Path("datasets/isolated_signs/train_landmarks")
sequences = []

for _, row in labels_df.iterrows():
    seq_id = row['sequence_id']
    sign_label = row['sign']
    fpath = parquet_dir / f"{seq_id}.parquet"
    if not fpath.exists():
        continue
    df = pd.read_parquet(fpath)

    # --- Extract hand landmarks ---
    # Try right hand first; fall back to left hand if right is all NaN
    right_cols = [f"{axis}_right_hand_{i}" for i in range(21) for axis in ("x", "y", "z")]
    left_cols  = [f"{axis}_left_hand_{i}" for i in range(21) for axis in ("x", "y", "z")]

    right_valid = df[right_cols].notna().any(axis=1).sum()
    left_valid  = df[left_cols].notna().any(axis=1).sum()

    # Use whichever hand has more valid frames (handles left-handed signers)
    if right_valid >= left_valid:
        hand_cols = right_cols
    else:
        hand_cols = left_cols

    df_hand = df[hand_cols].copy()

    # Drop frames where all hand landmarks are NaN (hand not visible)
    df_hand = df_hand.dropna(how='all')
    if len(df_hand) < 5:  # too few frames to be useful
        continue

    # --- Normalize each frame (wrist-relative, unit scale) ---
    def normalize_frame(row_vals):
        coords = row_vals.values.astype(float).reshape(21, 3)
        # Fill any remaining per-landmark NaNs with 0 (rare but possible)
        coords = np.nan_to_num(coords, nan=0.0)
        wrist = coords[0]
        coords -= wrist
        max_d = np.max(np.linalg.norm(coords, axis=1))
        if max_d > 0:
            coords /= max_d
        return coords.flatten()  # (63,)

    frames = np.array([normalize_frame(df_hand.iloc[i]) for i in range(len(df_hand))])
    sequences.append({'features': frames, 'label': sign_label, 'n_frames': len(frames)})

print(f"Loaded {len(sequences)} sequences")
print(f"Frame counts — min: {min(s['n_frames'] for s in sequences)}, "
      f"max: {max(s['n_frames'] for s in sequences)}, "
      f"median: {np.median([s['n_frames'] for s in sequences]):.0f}")
```

#### 4.6.2 Pad/truncate to fixed length

The LSTM requires a fixed input length. We truncate long sequences and zero-pad short ones to 30 frames.

```python
TARGET_LEN = 30  # frames

def pad_or_truncate(frames: np.ndarray, target_len: int = TARGET_LEN) -> np.ndarray:
    """Pad with zeros or truncate to target_len frames."""
    n = len(frames)
    if n >= target_len:
        # Take the middle segment (avoids start/end noise)
        start = (n - target_len) // 2
        return frames[start:start + target_len]
    else:
        # Zero-pad at the end
        padded = np.zeros((target_len, frames.shape[1]))
        padded[:n] = frames
        return padded

X_seq = np.array([pad_or_truncate(s['features']) for s in sequences])  # (N, 30, 63)
y_seq = np.array([s['label'] for s in sequences])                      # (N,)

print(f"Sequence tensor shape: {X_seq.shape}")
print(f"Labels shape: {y_seq.shape}, unique labels: {len(np.unique(y_seq))}")

# Train/val/test split (by sequence, not by frame)
from sklearn.model_selection import train_test_split
idx = np.arange(len(X_seq))
train_idx, temp_idx = train_test_split(idx, test_size=0.2, random_state=42, stratify=y_seq)
val_idx, test_idx   = train_test_split(temp_idx, test_size=0.5, random_state=42,
                                        stratify=y_seq[temp_idx])

X_seq_train, y_seq_train = X_seq[train_idx], y_seq[train_idx]
X_seq_val,   y_seq_val   = X_seq[val_idx],   y_seq[val_idx]
X_seq_test,  y_seq_test  = X_seq[test_idx],  y_seq[test_idx]
```

#### 4.6.3 Compute class weights for phrases

```python
from sklearn.utils.class_weight import compute_class_weight

seq_classes = np.unique(y_seq_train)
seq_weights = compute_class_weight('balanced', classes=seq_classes, y=y_seq_train)
seq_class_weight_dict = dict(zip(seq_classes, seq_weights))
```

#### 4.6.4 Train the LSTM model

```python
# training/train_phrases.py
import tensorflow as tf
from tensorflow import keras

NUM_CLASSES = len(np.unique(y_seq))  # actual count from the dataset

sequence_model = keras.Sequential([
    keras.layers.Input(shape=(TARGET_LEN, 63)),  # 30 frames × 63 features
    keras.layers.LSTM(128, return_sequences=True),
    keras.layers.LSTM(64),
    keras.layers.Dense(128, activation='relu'),
    keras.layers.Dropout(0.3),
    keras.layers.Dense(NUM_CLASSES, activation='softmax')
])

sequence_model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=1e-3),
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

# Same callbacks pattern as Model A
sequence_model.fit(
    X_seq_train, y_seq_train,
    validation_data=(X_seq_val, y_seq_val),
    epochs=50,
    class_weight=seq_class_weight_dict,
    callbacks=[
        keras.callbacks.EarlyStopping(patience=7, restore_best_weights=True),
        keras.callbacks.ReduceLROnPlateau(factor=0.5, patience=3, min_lr=1e-6),
        keras.callbacks.ModelCheckpoint('training/checkpoints/best_phrases.h5',
                                        monitor='val_accuracy', save_best_only=True),
        keras.callbacks.CSVLogger('training/logs/phrases_training.csv'),
    ]
)
```

#### 4.6.5 Left-handed signer handling

The data preparation script (4.6.1) already handles this by checking which hand has more valid frames per sequence and using that hand's landmarks. This means:
- Right-handed signers → right-hand columns used
- Left-handed signers → left-hand columns used automatically
- The landmarks are wrist-relative, so the normalised coordinates are comparable regardless of which physical hand was used

For best results during data augmentation, also add **horizontal mirroring**: flip the x-coordinates of left-hand data so it looks like right-hand data geometrically. This doubles the effective training set.

```python
def mirror_x(features: np.ndarray) -> np.ndarray:
    """Flip x-coordinates to simulate the other hand."""
    mirrored = features.copy()
    mirrored[:, 0::3] *= -1  # negate x values (every 3rd starting from 0)
    return mirrored
```

### 4.7 Target metrics and go/no-go gate

| Model | Metric | Target | Minimum acceptable |
|-------|--------|--------|--------------------|
| Alphabet (static) | Val accuracy | ≥ 90% | ≥ 80% |
| Alphabet (static) | Worst per-class F1 | ≥ 0.75 | ≥ 0.60 |
| Phrases (sequence) | Val accuracy | ≥ 75% | ≥ 60% |

**Go/no-go decision before Phase 5:**
- If overall accuracy ≥ 90% AND no class has F1 < 0.75 → **proceed to Phase 5** with the trained model.
- If overall accuracy is between 80–90% OR a few classes have F1 between 0.60–0.75 → **proceed to Phase 5** but flag those classes for the recovery plan (see 4.8).
- If overall accuracy < 80% → **do NOT proceed**. Execute recovery plan first.

### 4.8 Recovery plan (if targets are missed)

If accuracy plateaus below target, execute these fixes **in order** — each one is additive:

**Level 1 — Quick fixes (1 day):**

| Fix | When to use | How |
|-----|-------------|-----|
| Increase augmentation | Val accuracy stalls but train accuracy is high (overfitting) | Add random Gaussian noise to landmarks (`coords += tf.random.normal(shape, stddev=0.02)`), increase rotation range to ±25° |
| Increase class weights | Specific classes have low F1 | Manually set their weight to 2–3× the computed value |
| Longer training | LR is still > 1e-5 when EarlyStopping fires | Increase EarlyStopping patience to 12 and max epochs to 100 |

**Level 2 — Architecture changes (1–2 days):**

| Fix | When to use | How |
|-----|-------------|-----|
| Wider network | Underfitting (train accuracy also low) | Change layer sizes to 512→256→128 |
| Add residual skip connections | Gradient issues, loss oscillating | Add a skip connection from input to the final Dense layer: `x = keras.layers.Add()([dense_64_output, keras.layers.Dense(64)(input)])` |
| Switch to Random Forest | MLP accuracy stuck below 85% | `sklearn.ensemble.RandomForestClassifier(n_estimators=200)` — trains in seconds, often reaches 95% on landmark data without any tuning |

**Level 3 — Data fixes (2–3 days):**

| Fix | When to use | How |
|-----|-------------|-----|
| Record custom data | Confused letter pairs (G/L, E/M/S) persist | Use the data collection script from Phase 3 to record 200+ samples per confused letter with exaggerated poses |
| Merge datasets | Not enough training data overall | Combine Google dataset + Kaggle ASL Alphabet (after extracting landmarks from images) |

**Level 4 — Hybrid fallback (last resort):**

If the trained model still can't reliably separate certain pairs after all fixes, use a **hybrid approach**: the ML model handles most letters, but for the confused pairs, fall back to the heuristic classifier with pair-specific rules.

```python
# classification/hybrid_classifier.py
class HybridClassifier(GestureClassifier):
    def __init__(self, ml_model, heuristic, confused_pairs):
        self.ml = ml_model
        self.heuristic = heuristic
        self.confused_pairs = confused_pairs  # e.g., [('G', 'L'), ('M', 'S')]

    def classify(self, landmarks_flat):
        ml_prediction = self.ml.classify(landmarks_flat)

        # If the ML model predicted one of the confused letters,
        # double-check with the heuristic
        for pair in self.confused_pairs:
            if ml_prediction in pair:
                heuristic_prediction = self.heuristic.classify(landmarks_flat)
                if heuristic_prediction in pair:
                    return heuristic_prediction  # heuristic breaks the tie
        return ml_prediction
```

### 4.9 Deliverable checklist

- [ ] Class distribution plotted and saved to `training/logs/class_distribution.png`
- [ ] Class weights computed and applied during training
- [ ] Alphabet model trained with LR scheduling + EarlyStopping
- [ ] Per-class evaluation: confusion matrix saved to `training/logs/confusion_matrix.png`
- [ ] Weak classes identified and documented
- [ ] TFLite export verified (output matches Keras model)
- [ ] Phrase model trained with same callback/weight pattern
- [ ] Training CSV logs saved for loss/accuracy curves
- [ ] Go/no-go decision made: either proceed to Phase 5 or execute recovery plan
- [ ] If recovery plan was needed: document which fixes were applied and their effect

---

## Phase 5 — Server Integration (Swap Heuristic → Trained Model)

**Duration**: ~2 days  
**Depends on**: Phases 0, 1, 2, 4

### 5.1 TFLite classifier implementation

```python
# classification/tflite_classifier.py
import numpy as np
import tensorflow as tf
from classification.base import GestureClassifier

class TFLiteClassifier(GestureClassifier):
    LABELS = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ") + ["SPACE", "DELETE", "NOTHING"]

    def __init__(self, model_path: str):
        self.interpreter = tf.lite.Interpreter(model_path=model_path)
        self.interpreter.allocate_tensors()
        self.input_details  = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()

    def classify(self, landmarks_flat: np.ndarray) -> str:
        """Accepts (63,) position-only or (126,) position+velocity vectors."""
        input_data = landmarks_flat.astype(np.float32).reshape(1, -1)
        self.interpreter.set_tensor(self.input_details[0]['index'], input_data)
        self.interpreter.invoke()
        output = self.interpreter.get_tensor(self.output_details[0]['index'])[0]
        idx = np.argmax(output)
        confidence = output[idx]
        if confidence < 0.6:
            return "NOTHING"
        return self.LABELS[idx]
```

### 5.2 Swap in `app.py`

```python
# app.py — change one line
from classification.tflite_classifier import TFLiteClassifier

def create_app():
    # ...
    app.classifier = TFLiteClassifier("models/alphabet_model.tflite")
    # ...
```

The heuristic classifier stays in the codebase as a fallback — you can switch back by changing this single line.

### 5.3 Updated `/process` route (full flow)

```python
@app.route('/process', methods=['POST'])
def process_frame():
    file = request.files['image']
    img = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)

    # Step 1: DIP preprocessing
    img = app.preprocessor.process(img)

    # Step 2: MediaPipe landmark extraction
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    results = hands.process(img_rgb)

    if not results.multi_hand_landmarks:
        return jsonify({'gesture': 'No hands detected'})

    # Step 3: Normalize (with velocity) + classify
    detected = []
    for hand_landmarks in results.multi_hand_landmarks:
        landmarks = [{'x': lm.x, 'y': lm.y, 'z': lm.z} for lm in hand_landmarks.landmark]
        normalized = app.normalizer.normalize(landmarks, include_velocity=True)  # (126,)

        # Primary path: ML model with motion awareness
        gesture = app.classifier.classify(normalized)  # "A".."Z" including J/Z

        # Fallback: if ML model says NOTHING, check rule-based motion detector
        if gesture == "NOTHING":
            finger_states = get_finger_states(landmarks)
            app.motion_classifier.update(landmarks, finger_states)
            motion_gesture = app.motion_classifier.classify()
            if motion_gesture:
                gesture = motion_gesture

        if gesture != "NOTHING":
            detected.append(gesture)
            app.gesture_buffer.add(gesture)

    # Step 4: Phrase matching
    sequence = app.gesture_buffer.get_sequence()
    phrase = app.phrase_matcher.match(sequence)

    response = {'gestures': detected, 'sequence': sequence}
    if phrase:
        response['phrase'] = phrase
        app.gesture_buffer.clear()

    return jsonify(response)
```

### 5.4 Server concurrency

The `/process` endpoint does JPEG decode → CLAHE → Gaussian blur → MediaPipe → normalize → TFLite inference synchronously in a single request thread. With the Flutter app polling `/process` every 1 second and `/process/emotion` every 500ms, concurrent requests will block each other on the default single-threaded Flask server.

**Development (your machine):**

```python
# app.py — at the bottom
if __name__ == '__main__':
    app = create_app()
    app.run(
        host='0.0.0.0',
        port=5000,
        threaded=True,  # <-- handle requests in separate threads
        debug=True
    )
```

`threaded=True` lets Flask's built-in Werkzeug server process multiple requests concurrently using OS threads. This is sufficient for a single user (one phone sending requests) because the GIL is released during the C-level OpenCV and TFLite operations.

**Production / demo day:**

If you need to demo on multiple devices simultaneously, use **gunicorn** with multiple worker processes instead of Flask's built-in server:

```bash
# Install
pip install gunicorn

# Run with 4 worker processes (each gets its own MediaPipe + TFLite instance)
gunicorn --workers 4 --bind 0.0.0.0:5000 "app:create_app()"
```

Each gunicorn worker is a separate process with its own memory space, so MediaPipe and TFLite instances don't interfere. The trade-off is higher memory usage (~300MB per worker).

> **Note:** MediaPipe's `Hands()` object is not thread-safe. If using `threaded=True`, each request must either use a thread-local `Hands()` instance or protect access with a lock. The simplest approach:

```python
import threading

# In create_app()
app.hands_lock = threading.Lock()

# In the route handler
with app.hands_lock:
    results = hands.process(img_rgb)
```

This serializes MediaPipe calls while allowing the rest of the pipeline (preprocessing, classification) to run concurrently.

### 5.5 Deliverable checklist

- [ ] `TFLiteClassifier` works with the exported 126-d model
- [ ] `/process` returns correct letters for test images
- [ ] Velocity features flow from normalizer → classifier correctly
- [ ] Motion classifier acts as fallback for J/Z when ML confidence is low
- [ ] Latency per request ≤ 200 ms (benchmark on your machine)
- [ ] `threaded=True` enabled — concurrent gesture + emotion requests don't block
- [ ] MediaPipe thread-safety handled (lock or thread-local)
- [ ] Heuristic classifier remains available as a config toggle

---

## Phase 6 — Flutter App Updates

**Duration**: ~2–3 days  
**Depends on**: Phase 5 (server working)

### 6.1 Server URL configuration (physical device support)

The current `GuestureService` and `EmotionService` both hardcode the server URL to `http://10.0.2.2:5000` — the Android emulator's loopback to the host machine. This **will not work** on a physical phone. The fix is a proper configuration system.

#### 6.1.1 Create a server config class

```dart
// lib/data/server_config.dart
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const String _key = 'server_url';
  static const String _defaultUrl = 'http://10.0.2.2:5000';  // emulator fallback

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? _defaultUrl;
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url);
  }

  /// Auto-detect: if running on emulator use loopback, otherwise
  /// prompt the user or try mDNS discovery.
  static Future<String> resolveUrl() async {
    final saved = await getServerUrl();
    if (saved != _defaultUrl) return saved;  // user has set a custom URL
    // On a real device, the emulator loopback won't work.
    // Fall back to saved URL and let the settings screen handle it.
    return saved;
  }
}
```

#### 6.1.2 Inject into services via constructor

```dart
// lib/data/guesture_service.dart
class GuestureService {
  final String baseUrl;

  GuestureService({required this.baseUrl});

  Future<GestureResponse> sendFrameToBackend(Uint8List frameBytes) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/process'),
    );
    // ... rest stays the same
  }
}
```

```dart
// lib/data/emotion_service.dart
class EmotionService {
  final String baseUrl;

  EmotionService({required this.baseUrl});

  Future<EmotionResponse> sendFrameForEmotion(Uint8List frameBytes) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/process/emotion'),
    );
    // ... rest stays the same
  }
}
```

#### 6.1.3 Initialize services at app startup

```dart
// Wherever services are created (e.g., in the screen's initState or a provider)
final serverUrl = await ServerConfig.resolveUrl();
final gestureService = GuestureService(baseUrl: serverUrl);
final emotionService = EmotionService(baseUrl: serverUrl);
```

#### 6.1.4 Add server URL field to Settings screen

In `settings_page.dart`, add a new settings card under "App Settings":

```dart
_buildSettingsCard(
  title: 'Server Connection',
  children: [
    _buildTextFieldTile(
      title: 'Server URL',
      controller: _serverUrlController,  // pre-filled from ServerConfig.getServerUrl()
      hint: 'http://192.168.1.100:5000',
      onSaved: (value) async {
        await ServerConfig.setServerUrl(value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server URL updated. Restart the app to apply.')),
        );
      },
    ),
    _buildActionTile(
      title: 'Test Connection',
      icon: Icons.wifi_find,
      onTap: () async {
        try {
          final url = _serverUrlController.text;
          final response = await http.get(Uri.parse(url)).timeout(
            Duration(seconds: 3),
          );
          // Show success/failure
          _showConnectionResult(response.statusCode == 200);
        } catch (_) {
          _showConnectionResult(false);
        }
      },
    ),
  ],
),
```

This gives the user a way to:
1. Enter their computer's local IP (e.g., `http://192.168.1.105:5000`) when using a physical phone on the same WiFi
2. Test the connection before leaving the settings screen
3. Fall back to the emulator loopback by default

### 6.2 Handle new model labels

The trained model (Phase 5) outputs labels the old Flutter code doesn't know about: `NOTHING`, `DELETE`, `SPACE`, plus `J` and `Z` (from Phase 1.5). Update the gesture response handler:

| Label | UI behaviour |
|-------|--------------|
| `A`–`Z` (including J, Z) | Append letter to current word |
| `SPACE` | Finalize current word, add a space, start new word |
| `DELETE` | Remove last character from current word |
| `NOTHING` | Ignore — no gesture detected with high enough confidence |

### 6.3 Word-building logic in the UI

```dart
// In _TranslateSignToTextScreenState
String _currentWord = '';
String _fullSentence = '';

void _handleGesture(String gesture) {
  setState(() {
    if (gesture == 'DELETE') {
      if (_currentWord.isNotEmpty) {
        _currentWord = _currentWord.substring(0, _currentWord.length - 1);
      }
    } else if (gesture == 'SPACE') {
      _fullSentence += '$_currentWord ';
      _currentWord = '';
    } else if (gesture != 'NOTHING') {
      _currentWord += gesture;
    }
    _translatedText = '$_fullSentence$_currentWord';
  });
}
```

### 6.4 Fix Text-to-Sign video playback

Replace the broken network URLs in `text_to_sign.dart` with local asset paths:

```dart
final Map<String, Map<String, String>> phraseData = {
  'Hello': {
    'video': 'assets/hello.mp4',       // was: https://example.com/videos/hello.mp4
    'description': 'Wave your hand in greeting',
  },
  'Thank you': {
    'video': 'assets/thank_you.mp4',   // was: https://example.com/videos/thank_you.mp4
    'description': 'Touch your chin and extend hand forward',
  },
  // ... same for please.mp4, sorry.mp4
};

// And change the player initialization:
_controller = VideoPlayerController.asset(videoPath);  // was: .network(videoUrl)
```

### 6.5 Deliverable checklist

- [ ] `ServerConfig` class created with `getServerUrl()` / `setServerUrl()` / `resolveUrl()`
- [ ] `GuestureService` and `EmotionService` accept `baseUrl` via constructor — no more hardcoded URL
- [ ] Settings screen has a "Server Connection" card with URL input + test button
- [ ] App works on **physical Android device** when pointed at the computer's LAN IP
- [ ] Letters accumulate into words, DELETE removes last letter, SPACE starts new word
- [ ] J and Z gestures display correctly on the Flutter side
- [ ] Text-to-Sign videos play from local assets
- [ ] UI tested on both emulator and physical device

---

## Phase 7 — Testing & Polish

**Duration**: ~1–2 days  
**Depends on**: All previous phases

### 7.1 Server-side tests

```python
# tests/test_preprocessing.py
def test_clahe_does_not_crash_on_dark_image():
    dark = np.zeros((480, 640, 3), dtype=np.uint8)
    proc = CLAHEProcessor()
    result = proc.process(dark)
    assert result.shape == dark.shape

# tests/test_classifier.py
def test_tflite_returns_valid_label():
    clf = TFLiteClassifier("models/alphabet_model.tflite")
    fake_landmarks = np.random.randn(63).astype(np.float32)
    label = clf.classify(fake_landmarks)
    assert label in TFLiteClassifier.LABELS
```

### 7.2 Flutter-side tests

- Unit test `GuestureService` with mocked HTTP responses
- Widget test the word-building logic

### 7.3 End-to-end manual test

| Test case | Expected result |
|-----------|-----------------|
| Show letter A to camera | Screen displays "A" |
| Spell H-E-L-L-O with pauses | Screen shows "HELLO" |
| Make DELETE gesture | Last letter removed |
| Make SPACE gesture | Word finalized, cursor moves to next word |
| No hand visible | No spurious detections |
| Low-light room | CLAHE helps; detection still works |

### 7.4 Deliverable checklist

- [ ] All server unit tests pass
- [ ] Flutter widget tests pass
- [ ] End-to-end test on a physical Android device
- [ ] README updated with setup instructions

---

## Summary Timeline

| Phase | Task | Duration | Depends on |
|-------|------|----------|------------|
| 0 | Restructure + DI | 1 day | — |
| 1 | DIP preprocessing | 1–2 days | Phase 0 |
| 1.5 | Optical flow (J/Z) | 1–2 days | Phases 0, 1 |
| 2 | Landmark normalization | 0.5 day | Phase 0 |
| 3 | Dataset download + prep | 2 days | — (parallel) |
| 4 | Model training | 3–5 days | Phase 3 |
| 5 | Server integration | 2 days | Phases 0–2, 4 |
| 6 | Flutter updates (URL config, word-building, video fix) | 2–3 days | Phase 5 |
| 7 | Testing + polish | 1–2 days | All |
| **Total** | | **~14–19 days** | |

> **Critical path**: Phases 0 → 1 → 1.5 → 2 → 5 → 6 → 7  
> **Parallel track**: Phases 3 → 4 (can happen while restructuring)
