import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mcprj/data/server_config.dart';
import 'package:mcprj/domain/emotion_model.dart';

class EmotionService {
  final String baseUrl;

  EmotionService({String? baseUrl}) : baseUrl = baseUrl ?? '';

  static Future<EmotionService> create() async {
    final url = await ServerConfig.getServerUrl();
    return EmotionService(baseUrl: url);
  }

  Future<EmotionResponse> sendFrameForEmotion(Uint8List frameBytes) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/process/emotion'),
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

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return EmotionResponse(
          emotion: json['emotion'],
          confidence: (json['confidence'] as num?)?.toDouble(),
          allEmotions: json['all_emotions'],
          error: null,
        );
      }
      return EmotionResponse(error: 'Server error: ${response.statusCode}');
    } catch (e) {
      return EmotionResponse(error: 'Error: $e');
    }
  }
}
