import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<Map<String, dynamic>> registerDeviceWithAI({
    required String brand,
    required String model,
    required String serialNumber,
    required String imageUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/register-device'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'brand': brand,
        'model': model,
        'serial_number': serialNumber,
        'image_url': imageUrl,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to register device: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> verifyDeviceWithAI({
    required String deviceId,
    required String qrHash,
    required String liveImageUrl,
    required int timestamp,
    List<double>? registeredFeatures,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/verify-device'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_id': deviceId,
        'qr_hash': qrHash,
        'live_image_url': liveImageUrl,
        'timestamp': timestamp,
        'registered_features': registeredFeatures,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to verify device: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> checkQRWithAI({
    required String qrHash,
    required String qrData,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/check-qr'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'qr_hash': qrHash,
        'qr_data': qrData,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to check QR: ${response.body}');
    }
  }
}

