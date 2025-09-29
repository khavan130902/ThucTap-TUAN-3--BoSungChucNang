// lib/services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  final String apiKey;
  final String baseUrl;

  AiService({
    required this.apiKey,
    this.baseUrl = "https://api.openai.com/v1/chat/completions",
  });

  Future<String> explainAnswer({
    required String question,
    required List<String> options,
    required String correctAnswer,
    String? userAnswer,
  }) async {
    final prompt = """
Bạn là trợ lý ôn thi bằng lái xe. Hãy giải thích đáp án đúng cho câu hỏi sau:

Câu hỏi: $question

Các lựa chọn:
${options.join("\n")}

Người dùng chọn: ${userAnswer ?? "chưa chọn"}
Đáp án đúng: $correctAnswer

👉 Giải thích ngắn gọn, dễ hiểu bằng tiếng Việt.
""";

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini", // Hoặc "gpt-3.5-turbo" nếu rẻ hơn
        "messages": [
          {"role": "system", "content": "Bạn là trợ lý chuyên giải thích đáp án."},
          {"role": "user", "content": prompt},
        ],
        "max_tokens": 300,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["choices"][0]["message"]["content"];
    } else {
      return "⚠️ Lỗi gọi API (${response.statusCode}): ${response.body}";
    }
  }
}
