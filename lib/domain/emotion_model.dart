class EmotionResponse {
  final String? emotion;
  final double? confidence;
  final Map<String, dynamic>? allEmotions;
  final String? error;

  EmotionResponse({
    this.emotion,
    this.confidence,
    this.allEmotions,
    this.error,
  });
}
