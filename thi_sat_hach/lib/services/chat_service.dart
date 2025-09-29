import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'; // Import để dùng debugPrint

class ChatService {
  // ⚠️ KHÔNG ĐỌC KEY TĨNH NỮA (tránh NotInitializedError)
  // Chỉ đọc envModel (nếu có)
  static final String envModel = dotenv.env['GEMINI_MODEL'] ?? '';
  static String? _currentModel;

  // Helper: Lấy API Key động và kiểm tra
  static String _getApiKey() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('Lỗi: GEMINI_API_KEY chưa cấu hình hoặc không tìm thấy trong .env.');
    }
    return apiKey;
  }

  // Helper: build URI for generateContent
  static Uri _generateUriForModel(String modelName) {
    final apiKey = _getApiKey(); // 💡 LẤY KEY ĐỘNG
    // modelName có thể là: "models/gemini-1.5-flash-latest" hoặc "gemini-1.5-flash-latest"
    final modelPath = modelName.startsWith('models/') ? modelName : 'models/$modelName';
    return Uri.parse('https://generativelanguage.googleapis.com/v1beta/$modelPath:generateContent?key=$apiKey');
  }

  /// Gọi generateContent với model cụ thể
  static Future<http.Response> _callGenerate(String modelName, String prompt) {
    final uri = _generateUriForModel(modelName);
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });
    // Thêm timeout 30 giây để tránh bị treo vô thời hạn
    return http.post(uri, headers: {"Content-Type": "application/json"}, body: body).timeout(const Duration(seconds: 30));
  }

  /// Lấy danh sách model từ endpoint ListModels
  static Future<List<Map<String, dynamic>>> listModels() async {
    final apiKey = _getApiKey(); // 💡 LẤY KEY ĐỘNG
    if (apiKey.isEmpty) throw Exception('GEMINI_API_KEY chưa cấu hình (.env).');

    final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');

    final resp = await http.get(uri, headers: {"Content-Type": "application/json"}).timeout(const Duration(seconds: 15)); // Thêm timeout

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final raw = data['models'];
      if (raw is List) {
        // đảm bảo mỗi item là Map để đọc trường name/supportedMethods (nếu có)
        return raw.map<Map<String, dynamic>>((e) {
          if (e is Map<String, dynamic>) return e;
          return {"name": e.toString()};
        }).toList();
      } else {
        return [];
      }
    } else {
      // Vẫn ném Exception cho listModels vì nó chỉ dùng nội bộ trong sendMessage
      throw Exception('ListModels lỗi: ${resp.statusCode} ${resp.body}');
    }
  }

  /// Chọn model "tốt nhất" từ danh sách models trả về
  static String? _pickBestModelFromList(List<Map<String, dynamic>> models) {
    final names = models.map((m) {
      final n = m['name']?.toString() ?? '';
      // strip if starts with "models/"
      return n.startsWith('models/') ? n.substring('models/'.length) : n;
    }).toList();

    // 1) prefer gemini + flash-latest
    final flashLatest = names.firstWhere(
          (n) => n.contains('gemini') && n.contains('flash') && n.contains('latest'),
      orElse: () => '',
    );
    if (flashLatest.isNotEmpty) return flashLatest;

    // 2) prefer gemini + pro-latest
    final proLatest = names.firstWhere(
          (n) => n.contains('gemini') && n.contains('pro') && n.contains('latest'),
      orElse: () => '',
    );
    if (proLatest.isNotEmpty) return proLatest;

    // 3) prefer any gemini-1.5 (flash/pro)
    final g15 = names.firstWhere(
          (n) => n.contains('gemini-1.5'),
      orElse: () => '',
    );
    if (g15.isNotEmpty) return g15;

    // 4) prefer any gemini
    final anyGemini = names.firstWhere(
          (n) => n.contains('gemini'),
      orElse: () => '',
    );
    if (anyGemini.isNotEmpty) return anyGemini;

    // 5) fallback: first model in list (strip prefix done above)
    if (names.isNotEmpty) return names.first;

    return null;
  }

  /// Public: gửi message, tự động fallback model nếu cần
  static Future<String> sendMessage(String question) async {
    final apiKey = _getApiKey(); // 💡 LẤY KEY ĐỘNG
    if (apiKey.isEmpty) return '⚠️ Lỗi: GEMINI_API_KEY chưa cấu hình.';

    // 1) start with cached model, else envModel, else try common default
    final initialModel = _currentModel ?? (envModel.isNotEmpty ? envModel : 'gemini-1.5-flash-latest');

    try {
      final r = await _callGenerate(initialModel, question); // Đã có timeout bên trong _callGenerate
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        // cache model (store without "models/" prefix)
        _currentModel = initialModel.startsWith('models/') ? initialModel.substring('models/'.length) : initialModel;
        return text ?? '⚠️ Không có phản hồi từ AI.';
      } else {
        // Nếu NOT_FOUND hoặc lỗi model -> thử liệt kê models và chọn cái mới
        if (r.statusCode == 404 || r.body.contains('not found') || r.body.contains('NOT_FOUND')) {
          try {
            // List models
            final models = await listModels(); // Có timeout bên trong listModels
            if (models.isEmpty) {
              return '⚠️ Lỗi: Không có model khả dụng trong ListModels.';
            }
            final candidate = _pickBestModelFromList(models);
            if (candidate == null || candidate.isEmpty) {
              return '⚠️ Lỗi: Không tìm được model phù hợp từ ListModels.';
            }

            // Thử candidate
            final r2 = await _callGenerate(candidate, question); // Có timeout bên trong _callGenerate
            if (r2.statusCode == 200) {
              final data = jsonDecode(r2.body);
              final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
              _currentModel = candidate;
              return text ?? '⚠️ Không có phản hồi từ AI.';
            } else {
              // Trả về lỗi rõ ràng thay vì throw
              return '⚠️ Lỗi API sau khi thử model ${candidate}: ${r2.statusCode} ${r2.body}';
            }
          } catch (e) {
            // Bắt lỗi khi gọi listModels hoặc r2 bị timeout
            debugPrint('Lỗi khi List/Fallback Model: $e');
            return '⚠️ Lỗi: Thử lại model thất bại: ${e.toString()}';
          }
        } else if (r.statusCode == 401) {
          return '⚠️ Lỗi 401 Unauthorized — kiểm tra GEMINI_API_KEY và quyền của key.';
        } else if (r.statusCode == 400) {
          return '⚠️ Lỗi 400 Bad Request — kiểm tra payload hoặc model.';
        } else {
          return '⚠️ Lỗi API (${r.statusCode}): ${r.body}';
        }
      }
    } catch (e) {
      // Bắt lỗi Network, Timeout (TimeoutException) hoặc lỗi Parse JSON
      debugPrint('Lỗi nghiêm trọng trong ChatService (catch cuối): $e');
      return '⚠️ Lỗi mạng/API: ${e.toString()}';
    }
  }

  /// Tiện ích: cho debug, in danh sách model từ server
  static Future<String> debugListModels() async {
    try {
      final models = await listModels();
      if (models.isEmpty) return 'Không tìm thấy model nào.';
      final names = models.map((m) {
        final n = m['name']?.toString() ?? '';
        return n;
      }).join('\n');
      return 'Models:\n$names';
    } catch (e) {
      return 'Lỗi khi listModels: $e';
    }
  }
}