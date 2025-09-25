// lib/screens/practice_result_screen.dart
import 'package:flutter/material.dart';
import '../db_helper.dart';

class PracticeResultScreen extends StatefulWidget {
  const PracticeResultScreen({super.key});

  @override
  State<PracticeResultScreen> createState() => _PracticeResultScreenState();
}

class _PracticeResultScreenState extends State<PracticeResultScreen> {
  Map<String, dynamic>? user;
  List<Map<String, dynamic>> questions = [];
  List<String?> answers = [];
  int score = 0;
  int total = 0;
  int timeUsed = 0;

  @override
  void initState() {
    super.initState();
    // Chờ context sẵn sàng để lấy arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        setState(() {
          user = args['user'] as Map<String, dynamic>?;
          questions = args['questions'] as List<Map<String, dynamic>>? ?? [];
          answers = args['answers'] as List<String?>? ?? [];
          score = args['score'] as int? ?? 0;
          total = args['total'] as int? ?? 0;
          timeUsed = args['timeUsed'] as int? ?? 0;
        });

        debugPrint("👤 User nhận ở result: $user");

        if (user?['id'] != null) {
          _saveHistory();
        } else {
          debugPrint("⚠️ User không có id → không lưu lịch sử");
        }
      }
    });
  }

  Future<void> _saveHistory() async {
    try {
      final examId = await DBHelper.instance.saveExamHistory(
        userId: user!['id'],
        score: score,
        total: total,
        timeUsed: timeUsed,
      );

      debugPrint("✅ Đã lưu exam_history exam_id=$examId, user_id=${user!['id']}");

      final List<Map<String, dynamic>> details = [];
      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final userAns = answers.length > i ? answers[i] : null;
        final correctAns = q['answer'];

        details.add({
          "question_id": q['id'],
          "user_answer": userAns ?? "",
          "is_correct": userAns != null && userAns == correctAns,
        });
      }

      await DBHelper.instance.saveExamDetail(examId, details);
      debugPrint("📋 Đã lưu ${details.length} exam_detail cho exam_id=$examId");
    } catch (e) {
      debugPrint("❌ Lỗi khi lưu lịch sử: $e");
    }
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("❌ Không tìm thấy kết quả")),
      );
    }

    final bool isPassed = score >= 26;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF84DE8F),
        title: const Text("Kết quả thi thử",
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Kết quả ${user?['fullname'] ?? user?['username'] ?? 'Học viên'}!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isPassed ? Colors.green.shade400 : Colors.red.shade400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Vòng tròn điểm
            CircleAvatar(
              radius: 60,
              backgroundColor:
              isPassed ? Colors.green.shade400 : Colors.red.shade400,
              child: Text(
                "$score/$total",
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Thông tin kết quả
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.assignment, "Tổng số câu", "$total"),
                    _buildInfoRow(
                        Icons.cancel, "Số câu sai", "${total - score}"),
                    _buildInfoRow(Icons.check_circle, "Số câu đúng", "$score"),
                   _buildInfoRow(
                        Icons.timer, "Thời gian làm bài", formatTime(timeUsed)),
                    _buildInfoRow(
                      isPassed ? Icons.emoji_events : Icons.error,
                      "Kết quả",
                      isPassed ? "ĐẬU" : "RỚT",
                      valueColor:
                      isPassed ? Colors.green.shade400 : Colors.red.shade400,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Nút thao tác
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/practice',
                        arguments: {'user': user},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Làm lại"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/menu',
                        arguments: {'user': user},
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.home),
                    label: const Text("Trang chính"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/practice_review',
                    arguments: {
                      'user': user,
                      'questions': questions,
                      'answers': answers,
                      'score': score,
                      'total': total,
                      'timeUsed': timeUsed,
                    },
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text("Xem chi tiết bài thi"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF77DD77)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFFEDA371),
            ),
          ),
        ],
      ),
    );
  }
}
