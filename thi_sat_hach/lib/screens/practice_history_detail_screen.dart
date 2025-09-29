// lib/screens/practice_history_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_helper.dart';

class PracticeHistoryDetailScreen extends StatefulWidget {
  final int examId; // ID của lần thi cần xem chi tiết
  final Map<String, dynamic> user; // Thông tin người dùng đang đăng nhập

  const PracticeHistoryDetailScreen({
    super.key,
    required this.examId,
    required this.user,
  });

  @override
  State<PracticeHistoryDetailScreen> createState() =>
      _PracticeHistoryDetailScreenState();
}

class _PracticeHistoryDetailScreenState
    extends State<PracticeHistoryDetailScreen> {
  List<Map<String, dynamic>> _details = []; // Lưu danh sách câu hỏi + đáp án của lần thi
  bool _loading = true; // Trạng thái loading khi fetch dữ liệu

  int _score = 0; // Số câu đúng
  int _total = 0; // Tổng số câu hỏi
  String _createdAt = ""; // Ngày giờ thi

  @override
  void initState() {
    super.initState();
    _loadDetails(); // Khi mở màn hình thì load chi tiết lần thi
  }

  /// Hàm lấy chi tiết bài thi từ DB
  Future<void> _loadDetails() async {
    try {
      final data = await DBHelper.instance.getExamDetail(widget.examId);

      int score = 0;
      int total = 0;
      String createdAt = "";

      if (data.isNotEmpty) {
        // Đếm số câu đúng (is_correct = 1)
        score = data.where((q) => (q['is_correct'] as int? ?? 0) == 1).length;
        total = data.length;
        // Lấy ngày tạo từ bản ghi đầu tiên
        createdAt = data.first['created_at']?.toString() ?? "";
      }

      setState(() {
        _details = data;
        _score = score;
        _total = total;
        _createdAt = createdAt;
        _loading = false;
      });
    } catch (e) {
      debugPrint("❌ Lỗi khi load chi tiết kỳ thi: $e");
      setState(() {
        _loading = false;
        _details = [];
      });
    }
  }

  /// Hàm định dạng ngày từ DB -> hiển thị đẹp
  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat("dd/MM/yyyy HH:mm").format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double percent = (_total > 0) ? (_score / _total) * 100 : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("📖 Chi tiết lần thi"),
        backgroundColor: const Color(0xFF8EC1EB),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _details.isEmpty
          ? const Center(child: Text("📭 Không có dữ liệu chi tiết"))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Khối thông tin tổng quan (user, ngày thi, kết quả)
          Container(
            width: double.infinity,
            color: Colors.indigo.shade50,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "👤 Người thi: ${widget.user['username'] ?? 'Unknown'}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  "Ngày thi: ${_formatDate(_createdAt)}",
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  "Kết quả: $_score / $_total (${percent.toStringAsFixed(1)}%)",
                  style: TextStyle(
                    // Nếu đạt >= 80% thì xanh, ngược lại đỏ
                    color: _score >= (_total * 0.8)
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 🔹 Danh sách câu hỏi chi tiết
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _details.length,
              itemBuilder: (context, index) {
                final q = _details[index];
                final isCorrect = (q['is_correct'] as int? ?? 0) == 1;

                // Lấy nội dung câu hỏi (tùy DB trường nào có dữ liệu)
                final questionText = q['question_content']?.toString() ??
                    q['question_title']?.toString() ??
                    q['user_content']?.toString() ??
                    '';

                // Lấy đáp án đúng (ưu tiên correct_answer, nếu trống thì lấy ansright)
                final correctAnswer =
                q['correct_answer']?.toString().trim().isNotEmpty == true
                    ? q['correct_answer'].toString()
                    : q['ansright']?.toString() ?? '';

                final userAnswer = q['user_answer']?.toString() ?? '';
                final hint = q['anshint']?.toString() ?? '';

                // Lấy 4 lựa chọn (lọc bỏ null và chuỗi rỗng)
                final options = [
                  q['option_a'],
                  q['option_b'],
                  q['option_c'],
                  q['option_d'],
                ]
                    .where((o) => o != null && o.toString().trim().isNotEmpty)
                    .toList();

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Hiển thị câu hỏi + icon kết quả
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                "Câu ${index + 1}: $questionText",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Icon(
                              isCorrect
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: isCorrect
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 🔹 Các lựa chọn A, B, C, D
                        if (options.isNotEmpty) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(options.length, (i) {
                              final letter = String.fromCharCode(65 + i); // A/B/C/D
                              final optionText = options[i].toString();

                              final isUserPick = optionText == userAnswer;
                              final isAnswer = optionText == correctAnswer;

                              // Nền màu: xanh nhạt cho đáp án đúng, đỏ nhạt cho đáp án sai mà user chọn
                              Color bg = Colors.transparent;
                              if (isAnswer) {
                                bg = Colors.green.withOpacity(0.15);
                              } else if (isUserPick && !isAnswer) {
                                bg = Colors.red.withOpacity(0.15);
                              }

                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "$letter. $optionText",
                                  style: const TextStyle(fontSize: 15),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // 🔹 Luôn hiển thị đáp án đúng
                        if (correctAnswer.isNotEmpty) ...[
                          Text(
                            "👉 Đáp án đúng: $correctAnswer",
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                        ],

                        // 🔹 Giải thích (nếu có)
                        if (hint.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Colors.blue, size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Giải thích: $hint",
                                    style: const TextStyle(
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
