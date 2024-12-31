import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:mcprj/domain/guesture_model.dart';

class GuestureService {
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
}
