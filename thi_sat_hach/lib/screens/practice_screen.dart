import 'dart:async';
import 'package:flutter/material.dart';
import '../db_helper.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  List<Map<String, dynamic>> _questions = [];
  List<String?> _answers = [];
  bool _isLoading = true;
  bool _submitted = false;
  int _current = 0;

  static const int totalSeconds = 30 * 60;
  int _remaining = totalSeconds;
  Timer? _timer;

  Map<String, dynamic>? _user;

  bool _isGridVisible = true;

  int get _completedCount =>
      _answers.where((answer) => answer != null).length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _user = args?['user'] as Map<String, dynamic>?;

    if (_user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
      return;
    }

    if (_questions.isEmpty && _isLoading) {
      _loadQuestions();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final data = await DBHelper.instance
          .rawQuery("SELECT * FROM question ORDER BY RANDOM() LIMIT 30");
      _questions = data;
      _answers = List<String?>.filled(_questions.length, null);
      _startTimer();
    } catch (e) {
      debugPrint("❌ Lỗi load questions: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi tải câu hỏi")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _remaining = totalSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          _remaining = 0;
          t.cancel();
          _autoSubmit();
        }
      });
    });
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _choose(String option) {
    if (_submitted) return;
    setState(() {
      _answers[_current] = option;
    });
  }

  void _goTo(int index) {
    if (index >= 0 && index < _questions.length) {
      setState(() {
        _current = index;
      });
    }
  }

  void _autoSubmit() {
    if (_submitted) return;
    _finish();
  }

  void _finish() {
    _timer?.cancel();
    setState(() => _submitted = true);

    int correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      final right = (_questions[i]['ansright'] ?? '').toString().toUpperCase();
      final chosen = (_answers[i] ?? '').toUpperCase();
      if (chosen == right && right.isNotEmpty) correct++;
    }

    Navigator.pushReplacementNamed(context, '/practice_result', arguments: {
      'user': _user,
      'questions': _questions,
      'answers': _answers,
      'score': correct,
      'total': _questions.length,
      'timeUsed': totalSeconds - _remaining,
    });
  }

  String normalizeFileName(String? file) {
    if (file == null || file.trim().isEmpty) return "";
    var f = file.trim();
    if (f.contains("/") || f.contains("\\")) {
      f = f.split(RegExp(r'[\\/]+')).last;
    }
    if (!f.contains(".")) {
      f = "$f.png";
    }
    return f;
  }

  bool isImageFile(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith(".png") ||
        lower.endsWith(".jpg") ||
        lower.endsWith(".jpeg") ||
        lower.endsWith(".gif");
  }

  bool isAudioFile(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith(".mp3") ||
        lower.endsWith(".wav") ||
        lower.endsWith(".aac");
  }

  Widget _optionTile(
      String key, String text, bool selected, bool reveal, bool isCorrect) {
    Color bg = Colors.white;
    if (reveal) {
      if (isCorrect) {
        bg = const Color(0xFFC3EBC5);
      } else if (selected && !isCorrect) {
        bg = Colors.red.shade200;
      }
    } else {
      if (selected) bg = const Color(0xFFC8E5FF);
    }

    return InkWell(
      onTap: _submitted ? null : () => _choose(key),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? const Color(0xFF7EB7F1) : Colors.grey.shade300,
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF7EB7F1) : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
              child: Text(key,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_filled,
                      color: Color(0xFF7EB7F1),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Thời gian: ${_formatTime(_remaining)}",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7EB7F1)),
                    ),
                  ],
                ),
                Text(
                  "Đã làm: $_completedCount/${_questions.length}",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6FE498)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _completedCount / _questions.length,
                backgroundColor: Colors.grey.shade300,
                color: const Color(0xFF6FE498),
                minHeight: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _questions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, i) {
          final selected = _answers[i] != null;
          final isCurrent = _current == i;
          return GestureDetector(
            onTap: () => _goTo(i),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFF7EB7F1)
                    : (selected
                    ? const Color(0xFFFDBF76)
                    : Colors.white),
                shape: BoxShape.circle,
              ),
              child: Text(
                "${i + 1}",
                style: TextStyle(
                  color: isCurrent ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF84DE8F),
        title: const Text("Thi thử",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isGridVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isGridVisible = !_isGridVisible;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF83DD8E),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressCard(),
                if (_isGridVisible) ...[
                  _buildQuestionGrid(),
                  const Divider(
                      thickness: 1, height: 1, indent: 16, endIndent: 16),
                ],
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Câu ${_current + 1}/${_questions.length}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF222121))),
                      const SizedBox(height: 12),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (_questions[_current]['content']
                                    .toString()
                                    .trim()
                                    .isNotEmpty ==
                                    true)
                                    ? _questions[_current]['content']
                                    : (_questions[_current]['title'] ??
                                    "Nội dung câu hỏi"),
                                style: const TextStyle(
                                    fontSize: 18, height: 1.5),
                              ),
                              const SizedBox(height: 16),
                              Builder(builder: (_) {
                                String mediaFile = normalizeFileName(
                                    _questions[_current]['audio']);
                                if (mediaFile.isEmpty) return const SizedBox();
                                if (isImageFile(mediaFile)) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      "assets/img/$mediaFile",
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error,
                                          stackTrace) {
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          color: Colors.red.shade50,
                                          child: const Row(
                                            children: [
                                              Icon(Icons.error_outline,
                                                  color: Colors.red),
                                              SizedBox(width: 8),
                                              Text(
                                                  "Không tải được ảnh",
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontStyle:
                                                      FontStyle.italic)),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                } else if (isAudioFile(mediaFile)) {
                                  return Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.volume_up,
                                            color: Color(0xFFC0C1C7),
                                            size: 30),
                                        onPressed: () {
                                          debugPrint(
                                              "🔊 Play audio: $mediaFile");
                                          // TODO: tích hợp audio player
                                        },
                                      ),
                                      Text("Nghe audio",
                                          style: TextStyle(
                                              color: const Color(
                                                  0xFF8DE19F),
                                              fontSize: 16,
                                              fontWeight:
                                              FontWeight.bold)),
                                    ],
                                  );
                                }
                                return const SizedBox();
                              }),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // BẮT ĐẦU: Logic đã được chỉnh sửa để lọc các đáp án rỗng
                      ...() {
                        final q = _questions[_current];

                        // Khởi tạo tất cả tùy chọn
                        final allOptions = [
                          MapEntry('A', q['ansa']?.toString() ?? ""),
                          MapEntry('B', q['ansb']?.toString() ?? ""),
                          MapEntry('C', q['ansc']?.toString() ?? ""),
                          MapEntry('D', q['ansd']?.toString() ?? ""),
                        ];

                        // LỌC: Chỉ giữ lại các tùy chọn có nội dung (không rỗng sau khi trim)
                        final optionsToShow = allOptions
                            .where((e) => e.value.trim().isNotEmpty)
                            .toList();

                        final right = (q['ansright'] ?? '').toString().toUpperCase();
                        final chosen = (_answers[_current] ?? '').toUpperCase();
                        final reveal = _submitted || _remaining == 0;

                        // Mapping các tùy chọn đã lọc sang Widget _optionTile
                        return optionsToShow.map((e) {
                          final selected = chosen == e.key;
                          final isCorrect = right == e.key;
                          return _optionTile(e.key, e.value, selected, reveal, isCorrect);
                        }).toList();
                      }(),
                      // KẾT THÚC: Logic đã được chỉnh sửa
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildNavigationButtons(),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_current > 0)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _goTo(_current - 1),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label:
                    const Text("Trước", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF77DD77),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              if (_current > 0 && _current < _questions.length - 1)
                const SizedBox(width: 16),
              if (_current < _questions.length - 1)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _goTo(_current + 1),
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: const Text("Sau", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF77DD77),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD30000), width: 2.0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _submitted ? null : _finish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDD3434),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Hoàn thành bài thi",
                    style: TextStyle(
                        color: const Color(0xFFFFFFFF).withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          )
        ],
      ),
    );
  }
}