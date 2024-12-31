class GestureResponse {
  final List<String> gestures;
  final String? phrase;
  final List<String> sequence;
  final String? error;

  GestureResponse({
    required this.gestures,
    this.phrase,
    required this.sequence,
    this.error,
  });
}
