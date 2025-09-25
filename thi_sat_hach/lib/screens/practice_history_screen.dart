import 'dart:async';
import 'package:flutter/material.dart';
import '../db_helper.dart';
import 'practice_history_detail_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PracticeHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const PracticeHistoryScreen({super.key, required this.user});

  @override
  State<PracticeHistoryScreen> createState() => _PracticeHistoryScreenState();
}

class _PracticeHistoryScreenState extends State<PracticeHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  int passCount = 0;
  int failCount = 0;
  bool _loading = true;

  // 🎨 Màu pastel
  final Color pastelGreen = const Color(0xFF85DF90);
  final Color pastelOrange = const Color(0xFFEDA371);
  final Color pastelBlue = const Color(0xFF8FC2EC);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await DBHelper.instance.getExamHistory(widget.user['id']);
      data.sort((a, b) => (b['created_at'] ?? '')
          .toString()
          .compareTo((a['created_at'] ?? '').toString()));

      int pass = 0;
      int fail = 0;

      for (var row in data) {
        final correct = row['score'] as int? ?? 0;
        final total = row['total'] as int? ?? 1;
        if (correct >= (total * 0.8)) {
          pass++;
        } else {
          fail++;
        }
      }

      setState(() {
        _history = data;
        passCount = pass;
        failCount = fail;
        _loading = false;
      });
    } catch (e) {
      debugPrint("❌ Lỗi khi load lịch sử: $e");
      setState(() {
        _loading = false;
        _history = [];
      });
    }
  }

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
    final total = passCount + failCount;
    final passRate =
    total > 0 ? (passCount / total * 100).toStringAsFixed(1) : "0";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử thi thử"),
        backgroundColor: const Color(0xFF8FC2EC),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF96C8E6),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _history.isEmpty
            ? const Center(child: Text("📭 Chưa có lịch sử thi thử"))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Tổng quan nhanh
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem("Tổng lần thi", total.toString(),
                        Icons.history, pastelBlue),
                    _statItem("Số lần đậu", passCount.toString(),
                        Icons.check_circle, pastelGreen),
                    _statItem("Số lần rớt", failCount.toString(),
                        Icons.cancel, const Color(0xFFDD3434)), // ✅ Thêm chỉ số rớt
                    _statItem("Tỷ lệ đậu", "$passRate%",
                        Icons.leaderboard, pastelOrange),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Danh sách chi tiết
              const Text(
                "📚 Chi tiết các lần thi",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  final correct = item['score'] as int? ?? 0;
                  final total = item['total'] as int? ?? 1;
                  final isPass = correct >= (total * 0.8);

                  return Card(
                    color: isPass
                        ? pastelGreen.withOpacity(0.3)
                        : pastelOrange.withOpacity(0.3),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(
                          "📅 Ngày: ${_formatDate(item['created_at'] ?? "")}"),
                      subtitle: Text(
                          "Kết quả: $correct / $total (${(total > 0 ? correct / total * 100 : 0).toStringAsFixed(1)}%)"),
                      trailing: Icon(
                        isPass ? Icons.check_circle : Icons.cancel,
                        color: isPass
                            ? const Color(0xFF77DD77)
                            : const Color(0xFFDD3434),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PracticeHistoryDetailScreen(
                                  examId: item['id'] as int,
                                  user: widget.user,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title,
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ],
    );
  }
}