// Thay thế nội dung file profile_screen.dart bằng code dưới đây
import 'package:flutter/material.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _user = args?['user'];
  }

  // Phương thức để kiểm tra và trả về widget avatar phù hợp
  Widget _getAvatarWidget(String? avatarPath) {
    if (avatarPath != null && avatarPath.isNotEmpty) {
      if (avatarPath.startsWith('avatar') && avatarPath.endsWith('.png')) {
        // Đây là avatar mặc định từ assets
        return Image.asset(
          "assets/img/$avatarPath",
          width: 110,
          height: 110,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.person, size: 60, color: Colors.white);
          },
        );
      } else {
        // Đây là avatar được chọn từ thư viện, là một đường dẫn file
        final file = File(avatarPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: 110,
            height: 110,
            fit: BoxFit.cover,
          );
        }
      }
    }
    // Trường hợp không có avatar hoặc lỗi
    return const Icon(Icons.person, size: 60, color: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _user ?? {};

    final username = user['username']?.toString() ?? "Chưa có";
    final fullname = user['fullname']?.toString() ?? "Chưa cập nhật";
    final email = user['email']?.toString() ?? "Chưa cập nhật";
    final avatarPath = user['avatar']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông tin thành viên"),
        backgroundColor: const Color(0xFFFCC8D1),
        foregroundColor: Colors.white,
      ),
      body: Container( // Bọc body trong Container
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFCC8D1), // Màu bắt đầu
              Color(0xFFFFFFFF), // Màu kết thúc
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.indigo.shade100,
                child: ClipOval(
                  child: _getAvatarWidget(avatarPath),
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoCard(Icons.account_circle, "Tên đăng nhập", username),
              _buildInfoCard(Icons.badge, "Họ tên", fullname),
              _buildInfoCard(Icons.email, "Email", email),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/update_profile',
                      arguments: {'user': user},
                    );
                    if (result != null && result is Map<String, dynamic>) {
                      setState(() {
                        _user = result;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text("Cập nhật thông tin"),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (user['id'] != null) {
                      Navigator.pushNamed(
                        context,
                        '/update_password',
                        arguments: {'userId': user['id']},
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("⚠️ Không tìm thấy userId")),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.lock_reset),
                  label: const Text("Đổi mật khẩu"),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                          (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text("Đăng xuất"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String value, String label) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(label),
      ),
    );
  }
}