import 'package:flutter/material.dart';
import 'dart:io'; // Cần thiết để kiểm tra và hiển thị ảnh từ đường dẫn file

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // Màu sắc cố định
  static const Color primaryTeal = Color(0xFFA7E5CE);
  static const Color primaryPeach = Color(0xFFF4D2B6);

  Map<String, dynamic>? _user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Khởi tạo _user từ arguments, chỉ chạy lần đầu
    if (_user == null) {
      final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _user = args?['user'];
    }
  }

  // Hàm xử lý việc điều hướng đến màn hình Hồ sơ và chờ kết quả cập nhật
  Future<void> _navigateToProfile() async {
    // Chờ kết quả (updatedUser) trả về từ màn hình Profile
    final updatedUser = await Navigator.pushNamed(
      context,
      '/profile', // Giả sử /profile sẽ dẫn đến UpdateProfileScreen
      arguments: {'user': _user},
    );

    // Nếu có dữ liệu mới trả về (người dùng đã lưu thay đổi)
    if (updatedUser != null && updatedUser is Map<String, dynamic>) {
      setState(() {
        _user = updatedUser; // Cập nhật trạng thái người dùng
      });
      if (mounted) {
        // Thông báo cho người dùng
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thông tin hồ sơ đã được cập nhật.")),
        );
      }
    }
  }

  // Hàm xây dựng Widget Avatar, xử lý cả File Path và Asset
  Widget _buildAvatarWidget(String? avatarPath) {
    if (avatarPath != null) {
      final file = File(avatarPath);
      // 1. Nếu avatar là một đường dẫn file hợp lệ (ảnh chọn từ thư viện)
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 64, // Bán kính * 2
          height: 64,
          fit: BoxFit.cover,
        );
      }
      // 2. Nếu avatar là tên asset (ảnh có sẵn)
      else if (avatarPath.endsWith('.png')) { // Giả định asset có đuôi .png
        return Image.asset(
          "assets/img/$avatarPath",
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback nếu không tìm thấy asset
            return const Icon(Icons.person, size: 36, color: Color(0xFF203a43));
          },
        );
      }
    }
    // 3. Avatar mặc định (Placeholder)
    return const Icon(Icons.person, size: 36, color: Color(0xFF203a43));
  }

  @override
  Widget build(BuildContext context) {
    final user = _user; // Dùng state variable
    final username = user?['username'] ?? "Người dùng";
    final avatarPath = user?['avatar'];
    // final isUserLoggedIn = user != null; // Không cần thiết

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "THI SÁT HẠCH B2",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          // Gradient nhẹ nhàng hơn
          gradient: LinearGradient(
            colors: [primaryTeal, primaryPeach], // Light blue/cyan gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Phần User Info ---
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Avatar đã được cập nhật
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: _buildAvatarWidget(avatarPath),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0f2027), // Màu chữ đậm hơn
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Chào mừng bạn quay lại!",
                          style: TextStyle(
                              color: Color(0xFF203a43), fontSize: 15),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // --- Phần Menu Cards (ListView) ---
              Expanded(
                child: ListView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    _buildMenuCard(
                      context,
                      icon: Icons.book,
                      title: "Ôn Thi",
                      subtitle: "Học 600 câu hỏi lý thuyết",
                      colors: const [Color(0xFFFCB34E), Color(0xFFFCD0B0)],
                      onTap: () => Navigator.pushNamed(context, '/topics',
                          arguments: {'user': user}),
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.quiz,
                      title: "Thi Thử",
                      subtitle: "Thi với bộ đề ngẫu nhiên như thi thật",
                      colors: const [Color(0xFF78DC7B), Color(0xFFA3E4C8)],
                      onTap: () => Navigator.pushNamed(context, '/practice',
                          arguments: {'user': user}),
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.history,
                      title: "Lịch Sử Thi",
                      subtitle: "Xem lại kết quả và thống kê",
                      colors: const [Color(0xFF86B8EF), Color(0xFFB1E5D7)],
                      onTap: () => Navigator.pushNamed(context, '/history',
                          arguments: {'user': user}),
                    ),
                    // Thẻ Chatbot AI mới
                    _buildMenuCard(
                      context,
                      icon: Icons.chat_bubble_outline,
                      title: "Chatbot AI",
                      subtitle: "Hỏi đáp mọi câu hỏi về luật giao thông",
                      colors: const [Color(0xFFB08FCA), Color(0xFFCFB5E4)],
                      onTap: () => Navigator.pushNamed(context, '/chatbot',
                          arguments: {'user': user}),
                    ),
                    // Gọi hàm mới để chờ kết quả cập nhật
                    _buildMenuCard(
                      context,
                      icon: Icons.person,
                      title: "Hồ Sơ Tài Khoản",
                      subtitle: "Quản lý thông tin cá nhân",
                      colors: const [Color(0xFFFCC1CC), Color(0xFFFCDDE3)],
                      onTap: _navigateToProfile,
                    ),
                    const SizedBox(height: 20),
                    // --- Lợi ích của ứng dụng ---
                    _buildBenefitsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Thẻ menu full-width theo thiết kế mới
  Widget _buildMenuCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required List<Color> colors,
        required VoidCallback onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.last.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon lớn bên trái
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(width: 16),
              // Tiêu đề và mô tả
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Mũi tên > (tùy chọn)
              const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Lợi ích của ứng dụng
  Widget _buildBenefitsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                "Lợi ích của ứng dụng",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 1, color: Colors.black12),
          _buildBenefitItem("Học và ôn tập toàn bộ 600 câu hỏi."),
          _buildBenefitItem("Thi thử với bộ đề ngẫu nhiên như thi thật."),
          _buildBenefitItem("Hỗ trợ ôn tập các câu hỏi điểm liệt."),
        ],
      ),
    );
  }

  // Widget item lợi ích
  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}