import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

Future<String> sendFrameToBackend(Uint8List frameBytes) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:5000/process'), // Replace with your backend URL
    );

    // Add the image file to the request
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        frameBytes,
        filename: 'frame.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(await response.stream.bytesToString());
      if (jsonResponse.containsKey('gesture')) {
        return jsonResponse['gesture']; // Receive and return gesture
      } else {
        return 'No hands detected';
      }
    } else {
      return 'Error: ${response.statusCode}';
    }
  } catch (e) {
    return 'Error: $e';
  }
}
Future<String> sendFrameForEmotion(Uint8List frameBytes) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:5000/process/emotion'), // Updated backend URL
    );

    // Add the image file to the request
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        frameBytes,
        filename: 'frame.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(await response.stream.bytesToString());
      if (jsonResponse.containsKey('emotion')) {
        return jsonResponse['emotion']; // Receive and return detected emotion
      } else {
        return 'No emotion detected';
      }
    } else {
      return 'Error: ${response.statusCode}';
    }
  } catch (e) {
    return 'Error: $e';
  }
}

