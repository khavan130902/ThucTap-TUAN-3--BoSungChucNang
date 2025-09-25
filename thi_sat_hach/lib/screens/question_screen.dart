import 'package:flutter/material.dart';
import '../db_helper.dart';

class QuestionScreen extends StatefulWidget {
  final int topicId;
  final String topicName;

  const QuestionScreen({
    super.key,
    required this.topicId,
    required this.topicName,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final dbHelper = DBHelper.instance;
  int currentIndex = 0;
  List<Map<String, dynamic>> questions = [];
  int correctCount = 0;
  String? selectedOption;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    try {
      final data = await dbHelper.getQuestionsByTopic(widget.topicId);
      setState(() {
        questions = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Lỗi khi load questions: $e");
      setState(() => isLoading = false);
    }
  }

  void checkAnswer(String chosen, String correct) {
    setState(() {
      if (selectedOption == null) {
        selectedOption = chosen;
        if (chosen.toUpperCase() == correct.toUpperCase()) {
          correctCount++;
        }
      }
    });
  }

  void nextQuestion() {
    setState(() {
      currentIndex++;
      selectedOption = null;
    });
  }

  void previousQuestion() {
    setState(() {
      currentIndex--;
      selectedOption = null;
    });
  }

  /// ✅ Chuẩn hóa tên file (loại bỏ path thừa, thêm đuôi nếu cần)
  String normalizeFileName(String? file) {
    if (file == null || file.trim().isEmpty) return "";
    var f = file.trim();

    // Nếu DB lưu nguyên đường dẫn -> chỉ lấy tên file
    if (f.contains("/") || f.contains("\\")) {
      f = f.split(RegExp(r'[\\/]+')).last;
    }

    // Nếu chưa có đuôi file -> mặc định .png
    if (!f.contains(".")) {
      f = "$f.png";
    }

    return f;
  }

  bool isImageFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith(".jpg") ||
        lower.endsWith(".jpeg") ||
        lower.endsWith(".png") ||
        lower.endsWith(".gif");
  }

  bool isAudioFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith(".mp3") || lower.endsWith(".wav");
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topicName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topicName)),
        body: const Center(
          child: Text(
            "⚠️ Chủ đề này chưa có câu hỏi",
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    final total = questions.length;
    final question = questions[currentIndex];
    final content = question['content']?.toString().trim().isNotEmpty == true
        ? question['content']
        : (question['title'] ?? "Nội dung câu hỏi");

    final correctAnswer = question['ansright']?.toString().toUpperCase() ?? '';
    final hint = question['anshint'] ?? "";

    // ✅ chuẩn hóa file media
    String mediaFile = normalizeFileName(question['audio']);
    debugPrint("🖼 Media file: $mediaFile"); // log kiểm tra

    final isMandatory = question['mandatory'] == 1;

    final options = {
      'A': question['ansa'] ?? "",
      'B': question['ansb'] ?? "",
      'C': question['ansc'] ?? "",
      'D': question['ansd'] ?? "",
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicName, style: const TextStyle(fontSize: 18)),
        centerTitle: true,
        backgroundColor: const Color(0xFFFDBF76),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// Thanh tiến trình
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (currentIndex + 1) / total,
              backgroundColor: Colors.grey[300],
              color: Colors.indigo,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),

          /// Thông tin câu hỏi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Câu ${currentIndex + 1}/$total ${isMandatory ? "⭐" : ""}",
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (selectedOption != null)
                Icon(
                  selectedOption == correctAnswer
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: selectedOption == correctAnswer
                      ? const Color(0xFF8DE19F)
                      : const Color(0xFFDD3434),
                ),
            ],
          ),
          const SizedBox(height: 12),

          /// Nội dung câu hỏi
          Card(
            elevation: 5,
            shadowColor: Colors.indigo.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          /// Media (Ảnh hoặc Âm thanh)
          if (mediaFile.isNotEmpty) ...[
            if (isImageFile(mediaFile))
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/img/$mediaFile",
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) {
                    debugPrint("❌ Không load được ảnh: assets/img/$mediaFile");
                    return const Text("⚠️ Không tải được ảnh");
                  },
                ),
              ),
            if (isAudioFile(mediaFile))
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.indigo),
                    onPressed: () {
                      debugPrint("🔊 Play audio: $mediaFile");
                      // TODO: tích hợp audio player
                    },
                  ),
                  Text("Nghe audio",
                      style: TextStyle(color: Colors.indigo[600])),
                ],
              ),
            const SizedBox(height: 20),
          ],

          /// Các đáp án
          ...options.entries.map((entry) {
            final opt = entry.key;
            final text = entry.value;
            final isChosen = selectedOption == opt;
            final isCorrect = correctAnswer == opt;

            Color? bgColor;
            if (selectedOption != null) {
              if (isChosen && isCorrect) {
                bgColor = Colors.green.shade300;
              } else if (isChosen && !isCorrect) {
                bgColor = Colors.red.shade300;
              } else if (isCorrect) {
                bgColor = Colors.green.shade100;
              }
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: selectedOption == null
                    ? () => checkAnswer(opt, correctAnswer)
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgColor ?? Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isChosen ? const Color(0xFF6FE498) : const Color(
                          0xFFFDBF76),
                    ),
                  ),
                  child: Text(
                    "$opt. $text",
                    style: const TextStyle(fontSize: 16, height: 1.3),
                  ),
                ),
              ),
            );
          }),

          /// Gợi ý
          if (hint.toString().trim().isNotEmpty && selectedOption != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "💡 Gợi ý: $hint",
                style: const TextStyle(
                    fontSize: 16, color: Colors.deepOrange, height: 1.3),
              ),
            ),
          ],

          const SizedBox(height: 24),

          /// Nút điều hướng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (currentIndex > 0)
                OutlinedButton.icon(
                  onPressed: previousQuestion,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Trước"),
                ),
              if (currentIndex < total - 1)
                ElevatedButton.icon(
                  onPressed:
                  selectedOption == null ? null : () => nextQuestion(),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Tiếp"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDBF76)),
                ),
              if (currentIndex == total - 1)
                ElevatedButton.icon(
                  onPressed: selectedOption == null
                      ? null
                      : () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text("🎉 Kết thúc ôn thi"),
                        content: Text(
                          "Bạn đã trả lời đúng $correctCount/$total câu.",
                          style: const TextStyle(fontSize: 18),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.popUntil(
                              context,
                              ModalRoute.withName('/topics'),
                            ),
                            child: const Text("Về chủ đề"),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(),
                            child: const Text("Xem lại"),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Hoàn thành"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
