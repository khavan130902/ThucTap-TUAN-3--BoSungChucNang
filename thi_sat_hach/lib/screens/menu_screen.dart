// Thay thế toàn bộ nội dung file menu_screen.dart bằng code dưới đây
import 'package:flutter/material.dart';
import 'dart:io';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // Biến để lưu trữ thông tin người dùng
  Map<String, dynamic>? _user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lấy đối số khi màn hình được tạo lần đầu
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _user = args?['user'];
  }

  // Hàm để cập nhật thông tin người dùng từ đối số trả về
  void _updateUser(Map<String, dynamic>? updatedUser) {
    if (updatedUser != null && mounted) {
      setState(() {
        _user = updatedUser;
      });
    }
  }

  // Phương thức để kiểm tra và trả về widget avatar phù hợp
  Widget _getAvatarWidget(String? avatarPath) {
    if (avatarPath != null && avatarPath.isNotEmpty) {
      if (avatarPath.startsWith('avatar') && avatarPath.endsWith('.png')) {
        // Đây là avatar mặc định từ assets
        return Image.asset(
          "assets/img/$avatarPath",
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.person, size: 32, color: Color(0xFF388E3C));
          },
        );
      } else {
        // Đây là avatar được chọn từ thư viện, là một đường dẫn file
        final file = File(avatarPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          );
        }
      }
    }
    // Trường hợp không có avatar hoặc lỗi
    return const Icon(Icons.person, size: 32, color: Color(0xFF388E3C));
  }

  // Hàm điều hướng đến trang hồ sơ và chờ kết quả trả về
  Future<void> _navigateToProfile() async {
    final updatedUser = await Navigator.pushNamed(
      context,
      '/profile',
      arguments: {'user': _user},
    );
    _updateUser(updatedUser as Map<String, dynamic>?);
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng _user để đảm bảo UI được cập nhật
    final user = _user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("THI SÁT HẠCH B2", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFA8E6CF),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFA8E6CF),
              Color(0xFFFFD3B6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (user != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // ✅ Bọc CircleAvatar bằng GestureDetector
                      GestureDetector(
                        onTap: _navigateToProfile,
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: _getAvatarWidget(user['avatar']?.toString()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['username'] ?? "Người dùng",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF000000),
                            ),
                          ),
                          const Text(
                            "Chào mừng bạn quay lại!",
                            style: TextStyle(color: Colors.black54, fontSize: 14),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

              const SizedBox(height: 5),

              // 👉 Bố cục menu dạng cột với các Card lớnmenu_screen
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _menuListCard(
                        context,
                        icon: Icons.book,
                        title: "Ôn Thi",
                        subtitle: "Học 600 câu hỏi lý thuyết",
                        color1: const Color(0xFFFFB347),
                        color2: const Color(0xFFFFD3B6),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/topics',
                            arguments: {'user': user},
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _menuListCard(
                        context,
                        icon: Icons.quiz,
                        title: "Thi Thử",
                        subtitle: "Thi đề ngẫu nhiên",
                        color1: const Color(0xFF77DD77),
                        color2: const Color(0xFFA8E6CF),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/practice',
                            arguments: {'user': user},
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _menuListCard(
                        context,
                        icon: Icons.history,
                        title: "Lịch Sử Thi",
                        subtitle: "Xem lại kết quả và thống kê",
                        color1: const Color(0xFF84B6F4),
                        color2: const Color(0xFFB5EAD7),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/history',
                            arguments: {'user': user},
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Chức năng hồ sơ đã được thay thế bằng _navigateToProfile ở avatar
                      _menuListCard(
                        context,
                        icon: Icons.person,
                        title: "Hồ Sơ Tài Khoản",
                        subtitle: "Quản lý thông tin cá nhân",
                        color1: const Color(0xFFFFC1CC),
                        color2: const Color(0xFFFFE0E6),
                        onTap: _navigateToProfile,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.teal),
                          SizedBox(width: 8),
                          Text(
                            "Lợi ích của ứng dụng",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Text("• Học và ôn tập toàn bộ 600 câu hỏi."),
                      Text("• Thi thử với bộ đề ngẫu nhiên như thi thật."),
                      Text("• Hỗ trợ ôn tập các câu hỏi điểm liệt."),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color1,
        required Color color2,
        required VoidCallback onTap,
      }) {
    // Hàm này không còn được sử dụng
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _menuListCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color1,
        required Color color2,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}