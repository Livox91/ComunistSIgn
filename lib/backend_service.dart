import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

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

class BackendService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  Future<GestureResponse> sendFrameToBackend(Uint8List frameBytes) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/process'),
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
        
        return GestureResponse(
          gestures: jsonResponse.containsKey('gestures') 
              ? List<String>.from(jsonResponse['gestures'])
              : [],
          phrase: jsonResponse['phrase'],
          sequence: jsonResponse.containsKey('sequence')
              ? List<String>.from(jsonResponse['sequence'])
              : [],
          error: null,
        );
      } else {
        return GestureResponse(
          gestures: [],
          sequence: [],
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return GestureResponse(
        gestures: [],
        sequence: [],
        error: 'Error: $e',
      );
    }
  }

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