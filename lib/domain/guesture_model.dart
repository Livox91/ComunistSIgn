class PhrasePrediction {
  final String label;
  final double confidence;

  PhrasePrediction({required this.label, required this.confidence});

  factory PhrasePrediction.fromJson(Map<String, dynamic> json) {
    return PhrasePrediction(
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class GestureResponse {
  /// Letters detected this frame ("A", "B", "SPACE", "DELETE", ...).
  final List<String> gestures;

  /// Final phrase string-matcher result (legacy heuristic phrase output).
  final String? phrase;

  /// Per-frame letter-buffer history (for word building).
  final List<String> sequence;

  /// Top-3 LSTM phrase predictions, present once the 30-frame buffer fills.
  final List<PhrasePrediction> phrasePredictions;

  final String? error;

  GestureResponse({
    required this.gestures,
    this.phrase,
    required this.sequence,
    this.phrasePredictions = const [],
    this.error,
  });
}
