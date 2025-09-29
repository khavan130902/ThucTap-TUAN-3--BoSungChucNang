import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final String? apiKey = dotenv.env['API_KEY'];
  final String model = dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';

  /// Gọi Gemini. Trả về text trả lời hoặc ném Exception.
  Future<String> generateText(String prompt) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key not found. Put API_KEY in .env file.');
    }

    // Sử dụng query param key=... (đôi khi cần), hoặc Bearer header.
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    };

    final resp = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      try {
        final text =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        return text ?? 'Xin lỗi, tôi không có câu trả lời.';
      } catch (e) {
        throw Exception('Không parse được response: $e');
      }
    } else if (resp.statusCode == 401) {
      throw Exception('Unauthorized (401). Kiểm tra API key hoặc quyền.');
    } else if (resp.statusCode == 400) {
      throw Exception('Bad Request (400). Kiểm tra format payload.');
    } else {
      throw Exception(
          'Lỗi API: ${resp.statusCode} - ${resp.body.substring(0, resp.body.length > 300 ? 300 : resp.body.length)}');
    }
  }
}
