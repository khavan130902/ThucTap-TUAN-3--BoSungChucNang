import 'dart:async';
import 'package:flutter/material.dart';
import '../db_helper.dart';
import 'practice_history_detail_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PracticeHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> user; // thông tin user đăng nhập
  const PracticeHistoryScreen({super.key, required this.user});

  @override
  State<PracticeHistoryScreen> createState() => _PracticeHistoryScreenState();
}

class _PracticeHistoryScreenState extends State<PracticeHistoryScreen> {
  List<Map<String, dynamic>> _history = []; // danh sách lịch sử thi
  int passCount = 0; // số lần đậu
  int failCount = 0; // số lần rớt
  bool _loading = true; // trạng thái loading

  // 🎨 màu pastel để giao diện dịu mắt
  final Color pastelGreen = const Color(0xFF85DF90);
  final Color pastelOrange = const Color(0xFFEDA371);
  final Color pastelBlue = const Color(0xFF8FC2EC);

  @override
  void initState() {
    super.initState();
    _loadHistory(); // khi mở màn hình thì load lịch sử thi
  }

  /// Hàm lấy lịch sử thi từ DB
  Future<void> _loadHistory() async {
    try {
      // Lấy dữ liệu lịch sử thi của user hiện tại
      final data = await DBHelper.instance.getExamHistory(widget.user['id']);

      // Sắp xếp theo thời gian giảm dần (mới nhất trước)
      data.sort((a, b) => (b['created_at'] ?? '')
          .toString()
          .compareTo((a['created_at'] ?? '').toString()));

      int pass = 0;
      int fail = 0;

      // Đếm số lần đậu/rớt dựa trên 80% số câu đúng
      for (var row in data) {
        final correct = row['score'] as int? ?? 0;
        final total = row['total'] as int? ?? 1;
        if (correct >= (total * 0.8)) {
          pass++;
        } else {
          fail++;
        }
      }

      // Cập nhật state
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

  /// Định dạng ngày giờ
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
        // nền gradient xanh -> trắng
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
              // 🔹 Thống kê nhanh (tổng số lần, số đậu, số rớt, tỷ lệ đậu)
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
                        Icons.cancel, const Color(0xFFDD3434)),
                    _statItem("Tỷ lệ đậu", "$passRate%",
                        Icons.leaderboard, pastelOrange),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 Danh sách chi tiết từng lần thi
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
                    margin:
                    const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(
                          "📅 Ngày: ${_formatDate(item['created_at'] ?? "")}"),
                      subtitle: Text(
                          "Kết quả: $correct / $total (${(total > 0 ? correct / total * 100 : 0).toStringAsFixed(1)}%)"),
                      trailing: Icon(
                        isPass
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: isPass
                            ? const Color(0xFF77DD77)
                            : const Color(0xFFDD3434),
                      ),
                      // 👉 Nhấn vào 1 lần thi -> đi tới màn hình chi tiết
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

  /// Widget hiển thị 1 mục thống kê (icon + số + tên)
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
