import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:mcprj/domain/emotion_model.dart';

class EmotionService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  Future<EmotionResponse> sendFrameForEmotion(Uint8List frameBytes) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/process/emotion'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          frameBytes,
          filename: 'frame.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        return EmotionResponse(
          emotion: jsonResponse['emotion'],
          confidence: jsonResponse['confidence']?.toDouble(),
          allEmotions: jsonResponse['all_emotions'],
          error: null,
        );
      } else {
        return EmotionResponse(
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return EmotionResponse(
        error: 'Error: $e',
      );
    }
  }
}
