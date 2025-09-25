import 'package:flutter/material.dart';
import '../db_helper.dart';

class TopicScreen extends StatelessWidget {
  const TopicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbHelper = DBHelper.instance;

    // 👉 Nhận user từ arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final user = args?['user'];

    return Scaffold(
      backgroundColor: const Color(0xFFFDBF76), // Đặt background trong suốt để gradient bên dưới hiển thị
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDBF76),
        title: const Text("Chọn chủ đề ôn thi"),
        centerTitle: true,
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: "Thông tin cá nhân",
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/profile',
                  arguments: {'user': user}, // 👈 truyền user
                );
              },
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDBF76),
              Color(0xFFFFD3B6),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // 🔹 Nút Thi thử
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  if (user == null) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                  } else {
                    Navigator.pushNamed(
                      context,
                      '/practice',
                      arguments: {'user': user},
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF77DD77), const Color(0xFF6FE498)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(2, 4),
                      )
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.school, color: Colors.white, size: 36),
                      SizedBox(height: 8),
                      Text(
                        "Thi thử 30 câu / 30 phút",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Danh sách chủ đề
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: dbHelper.getTopics(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "❌ Lỗi khi load chủ đề:\n${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("⚠️ Chưa có dữ liệu chủ đề"));
                  }

                  final topics = snapshot.data!;

                  // Thay đổi từ GridView.builder sang ListView.builder
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: topics.length,
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      final topicId = topic['id'];
                      final topicName = topic['title'] ?? topic['name'] ?? "Chủ đề";
                      final questionCount = topic['question_count'] ?? 0;

                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/questions',
                            arguments: {
                              'topicId': topicId,
                              'topicName': topicName,
                              'user': user, // 👈 truyền luôn user (nếu cần trong Questions)
                            },
                          );
                        },
                        child: Container(
                          // Thêm margin dưới để các item cách nhau
                          margin: const EdgeInsets.only(bottom: 16),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [const Color(0xFFFDBF76), const Color(0xFFEDA371)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(2, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              // Số thứ tự
                              Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topicName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "$questionCount",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}