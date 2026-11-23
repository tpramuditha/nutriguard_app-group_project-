import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/food_recognition_result.dart';

class FoodRecognitionService {
  static const String _baseUrl = 'http://127.0.0.1:3000';

  static const int _maxImageSize = 3 * 1024 * 1024;

  Future<FoodRecognitionResult> recognizeFood(
    XFile image, {
    http.Client? client,
  }) async {
    final Uint8List imageBytes = await image.readAsBytes();

    if (imageBytes.isEmpty || imageBytes.length > _maxImageSize) {
      throw Exception('Please select an image smaller than 3 MB.');
    }

    final String mimeType = _detectImageType(imageBytes);

    try {
      final uri = Uri.parse('$_baseUrl/api/recognize-food');

      final requestBody = jsonEncode({
        'imageBase64': base64Encode(imageBytes),
        'mimeType': mimeType,
      });

      final responseFuture = client == null
          ? http.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            )
          : client.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            );

      final response = await responseFuture.timeout(
        const Duration(seconds: 70),
      );

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid backend response.');
      }

      if (response.statusCode != 200 || decoded['success'] != true) {
        final message = decoded['message'];

        throw Exception(
          message is String ? message : 'Food recognition failed.',
        );
      }

      return FoodRecognitionResult.fromJson(decoded);
    } on TimeoutException {
      throw Exception(
        'Food recognition took too long. '
        'Please check your connection and try again.',
      );
    } on http.ClientException {
      throw Exception(
        'Cannot connect to the NutriGuard backend. '
        'Check that Node.js is running and ADB reverse is active.',
      );
    } on FormatException {
      throw Exception(
        'The AI service returned an invalid response. '
        'Please try again.',
      );
    }
  }

  String _detectImageType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'image/png';
    }

    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }

    throw Exception('Unsupported image format. Please use JPEG, PNG, or WebP.');
  }
}
