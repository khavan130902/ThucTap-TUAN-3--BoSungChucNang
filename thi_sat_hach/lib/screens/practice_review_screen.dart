import 'package:flutter/material.dart';

class PracticeReviewScreen extends StatefulWidget {
  const PracticeReviewScreen({super.key});

  @override
  State<PracticeReviewScreen> createState() => _PracticeReviewScreenState();
}

class _PracticeReviewScreenState extends State<PracticeReviewScreen> {
  int _current = 0;
  List<Map<String, dynamic>> _filteredQuestions = [];
  List<String?> _filteredAnswers = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filteredQuestions.isEmpty) {
      _filterData();
    }
  }

  void _filterData() {
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) return;

    final questions = args['questions'] as List<Map<String, dynamic>>? ?? [];
    final answers = args['answers'] as List<String?>? ?? [];

    List<Map<String, dynamic>> validQuestions = [];
    List<String?> validAnswers = [];

    // Lọc câu hỏi: chỉ giữ lại những câu có nội dung VÀ có ít nhất một đáp án
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];

      // 1. Kiểm tra nội dung câu hỏi
      final questionTextExists = (q['content']?.toString().trim().isNotEmpty == true) ||
          (q['title']?.toString().trim().isNotEmpty == true);

      // 2. Kiểm tra ít nhất một đáp án (A, B, C, D) có tồn tại
      final optionsExist = (q['ansa']?.toString().trim().isNotEmpty == true) ||
          (q['ansb']?.toString().trim().isNotEmpty == true) ||
          (q['ansc']?.toString().trim().isNotEmpty == true) ||
          (q['ansd']?.toString().trim().isNotEmpty == true);

      if (questionTextExists && optionsExist) {
        validQuestions.add(q);
        // Lưu đáp án tương ứng của câu hỏi hợp lệ
        validAnswers.add(i < answers.length ? answers[i] : null);
      }
    }

    setState(() {
      _filteredQuestions = validQuestions;
      _filteredAnswers = validAnswers;
    });
  }

  // Widget để tạo từng ô đáp án
  Widget _buildOptionTile(String key, String value, String chosen, String right) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink(); // Loại bỏ widget nếu đáp án rỗng
    }

    final isCorrect = key == right;
    final isChosen = key == chosen;

    Color bg = Colors.white;
    if (isCorrect) {
      bg = const Color(0xFF96C8E6).withOpacity(0.8); // Màu xanh lam nhẹ cho đáp án đúng
    } else if (isChosen && !isCorrect) {
      bg = const Color(0xFFDD3434).withOpacity(0.8); // Màu đỏ cho đáp án sai đã chọn
    } else {
      bg = Colors.grey.shade100; // Màu nền mặc định
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCorrect || (isChosen && !isCorrect)
              ? Colors.grey.shade400
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isCorrect ? const Color(0xFF38B2AC) : const Color(0xFF8DE19F),
            child: Text(key,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(value)),
          if (isChosen && !isCorrect)
            const Icon(Icons.close, color: Colors.red),
          if (isCorrect)
            const Icon(Icons.check, color: Colors.green),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredQuestions.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "❌ Không có câu hỏi hợp lệ để xem lại. Các câu hỏi không có đáp án đã được lọc bỏ.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final q = _filteredQuestions[_current];
    // Chuyển sang chữ hoa và trim để so sánh an toàn
    final chosen = (_filteredAnswers[_current] ?? '').toUpperCase().trim();
    final right = (q['ansright'] ?? '').toString().toUpperCase().trim();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6FE498),
        title: const Text("Xem lại bài thi", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ số câu
              Text(
                "Câu ${_current + 1}/${_filteredQuestions.length}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // ✅ nội dung câu hỏi
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    (q['content']?.toString().trim().isNotEmpty == true)
                        ? q['content']
                        : (q['title'] ?? "Nội dung câu hỏi"),
                    style: const TextStyle(fontSize: 18, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ✅ danh sách đáp án (đã lọc)
              ...[
                MapEntry('A', q['ansa']?.toString() ?? ""),
                MapEntry('B', q['ansb']?.toString() ?? ""),
                MapEntry('C', q['ansc']?.toString() ?? ""),
                MapEntry('D', q['ansd']?.toString() ?? ""),
              ].map((e) => _buildOptionTile(e.key, e.value, chosen, right)).toList(),

              const SizedBox(height: 100), // chừa chỗ cho bottomNavigationBar
            ],
          ),
        ),
      ),

      // ✅ cố định nút điều hướng ở dưới
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _current > 0
                        ? () => setState(() => _current--)
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Trước"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _current < _filteredQuestions.length - 1
                        ? () => setState(() => _current++)
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text("Sau"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.exit_to_app),
                label: const Text("Quay lại kết quả"),
              ),
            )
          ],
        ),
      ),
    );
  }
}