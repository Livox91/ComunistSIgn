import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mcprj/data/server_config.dart';
import 'package:mcprj/domain/guesture_model.dart';

class GuestureService {
  final String baseUrl;

  GuestureService({String? baseUrl}) : baseUrl = baseUrl ?? '';

  /// Async constructor that pulls the URL from [ServerConfig] (SharedPreferences).
  static Future<GuestureService> create() async {
    final url = await ServerConfig.getServerUrl();
    return GuestureService(baseUrl: url);
  }

  Future<GestureResponse> sendFrameToBackend(Uint8List frameBytes) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/process'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          frameBytes,
          filename: 'frame.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        return GestureResponse(
          gestures: const [],
          sequence: const [],
          phrase: 'Detecting...',
        );
      }

      final json = jsonDecode(response.body);

      // Status-only response (early-exit on the server)
      if (json is String && json.contains('Detecting')) {
        return GestureResponse(
          gestures: const [],
          sequence: const [],
          phrase: 'Detecting...',
        );
      }

      // "No hands detected" or generic status payload
      if (json is Map<String, dynamic> && !json.containsKey('gestures')) {
        return GestureResponse(
          gestures: const [],
          sequence: const [],
          phrase: json['gesture'] as String?,
        );
      }

      final map = json as Map<String, dynamic>;

      final phrasePredictions = (map['phrase_predictions'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(PhrasePrediction.fromJson)
              .toList() ??
          const <PhrasePrediction>[];

      return GestureResponse(
        gestures: List<String>.from(map['gestures'] ?? const []),
        phrase: map['phrase'] as String?,
        sequence: List<String>.from(map['sequence'] ?? const []),
        phrasePredictions: phrasePredictions,
      );
    } catch (e) {
      return GestureResponse(
        gestures: const [],
        sequence: const [],
        phrase: 'Detecting...',
      );
    }
  }
}
