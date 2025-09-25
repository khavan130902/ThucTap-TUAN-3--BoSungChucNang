import 'package:flutter/material.dart';

class PracticeReviewScreen extends StatefulWidget {
  const PracticeReviewScreen({super.key});

  @override
  State<PracticeReviewScreen> createState() => _PracticeReviewScreenState();
}

class _PracticeReviewScreenState extends State<PracticeReviewScreen> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return const Scaffold(
        body: Center(child: Text("❌ Không có dữ liệu để xem lại")),
      );
    }

    final user = args['user'] as Map<String, dynamic>?;
    final questions = args['questions'] as List<Map<String, dynamic>>? ?? [];
    final answers = args['answers'] as List<String?>? ?? [];

    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("❌ Không có câu hỏi")),
      );
    }

    final q = questions[_current];
    final chosen = (answers[_current] ?? '').toUpperCase();
    final right = (q['ansright'] ?? '').toString().toUpperCase();

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
                "Câu ${_current + 1}/${questions.length}",
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
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ✅ danh sách đáp án
              ...[
                MapEntry('A', q['ansa']?.toString() ?? ""),
                MapEntry('B', q['ansb']?.toString() ?? ""),
                MapEntry('C', q['ansc']?.toString() ?? ""),
                MapEntry('D', q['ansd']?.toString() ?? ""),
              ].map((e) {
                final isCorrect = e.key == right;
                final isChosen = e.key == chosen;

                Color bg = Colors.white;
                if (isCorrect) bg = const Color(0xFF96C8E6);
                if (isChosen && !isCorrect) bg = const Color(0xFFDD3434);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF8DE19F),
                        child: Text(e.key,
                            style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(e.value)),
                    ],
                  ),
                );
              }),

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
                    onPressed: _current < questions.length - 1
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
