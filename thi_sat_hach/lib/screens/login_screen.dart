import 'package:flutter/material.dart';
import '../db_helper.dart';

// Màn hình đăng nhập là một StatefulWidget vì nó cần quản lý trạng thái
// của các trường nhập liệu (controller), trạng thái tải (isLoading) và hiển thị mật khẩu.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey dùng để xác thực Form
  final _formKey = GlobalKey<FormState>();
  // Controllers để quản lý dữ liệu trong các trường nhập liệu
  // Đã đổi từ _usernameController sang _emailController
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Biến cờ để ẩn/hiện mật khẩu
  bool _obscurePwd = true;
  // Biến cờ để theo dõi trạng thái tải (loading) của nút bấm
  bool _isLoading = false;

  // Phương thức bất đồng bộ để xử lý logic đăng nhập
  Future<void> _login() async {
    // Kiểm tra nếu form không hợp lệ thì dừng lại
    if (!_formKey.currentState!.validate()) return;

    // Lấy dữ liệu từ controllers và loại bỏ khoảng trắng thừa
    // Đã đổi từ username sang email
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Cập nhật trạng thái isLoading để hiển thị vòng xoay
    setState(() => _isLoading = true);

    try {
      // Thực hiện truy vấn cơ sở dữ liệu để tìm người dùng
      final result = await DBHelper.instance.rawQuery(
        // Lệnh SQL đã được sửa: tìm người dùng với email và password tương ứng
        "SELECT * FROM users WHERE email = ? AND password = ? LIMIT 1",
        [email, password],
      );

      // Nếu tìm thấy người dùng (kết quả không rỗng)
      if (result.isNotEmpty) {
        final user = result.first;
        // Kiểm tra widget còn mounted không trước khi cập nhật UI
        if (!mounted) return;

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Đăng nhập thành công")),
        );

        // Chuyển hướng đến màn hình /menu và thay thế màn hình hiện tại
        Navigator.pushReplacementNamed(context, '/menu', arguments: {'user': user});
      } else {
        // Nếu không tìm thấy, hiển thị thông báo lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Sai email hoặc mật khẩu")), // Sửa thông báo lỗi
        );
      }
    } finally {
      // Luôn cập nhật trạng thái isLoading về false, ngay cả khi có lỗi
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Phương thức build() để xây dựng giao diện người dùng
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Container chính với hiệu ứng gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFA8E6CF), // Màu xanh lá pastel
              Color(0xFFFFD3B6), // Màu cam pastel
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // Căn giữa nội dung
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            // Thẻ Card nổi bật với đổ bóng và bo góc
            child: Card(
              elevation: 8,
              color: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                // Form để chứa các trường nhập liệu và thực hiện validation
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Biểu tượng khóa lớn
                      const Icon(Icons.lock_outline, size: 80, color: Colors.green),
                      const SizedBox(height: 20),
                      // Tiêu đề "Đăng nhập"
                      Text(
                        "Đăng nhập",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Trường nhập liệu email
                      TextFormField(
                        controller: _emailController,
                        // Thêm keyboardType là email để tối ưu bàn phím
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v!.isEmpty) {
                            return "Nhập email";
                          }
                          // Thêm validation cơ bản cho định dạng email
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                            return "Email không hợp lệ";
                          }
                          return null;
                        },
                        // Đã sửa nhãn và icon cho trường email
                        decoration: _inputDecoration("Email", Icons.email),
                      ),
                      const SizedBox(height: 16),
                      // Trường nhập liệu mật khẩu
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePwd, // Ẩn/hiện mật khẩu
                        validator: (v) => v!.isEmpty ? "Nhập mật khẩu" : null,
                        decoration: _inputDecoration("Mật khẩu", Icons.lock).copyWith(
                          // Nút để bật/tắt hiển thị mật khẩu
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePwd ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      // Nút "Đăng nhập"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login, // Vô hiệu hóa khi đang tải
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.green.shade300,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              : const Text(
                            "Đăng nhập",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Nút "Quên mật khẩu?"
                      TextButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("⚠️ Chức năng quên mật khẩu chưa hỗ trợ")),
                        ),
                        child: const Text("Quên mật khẩu?", style: TextStyle(color: Colors.grey)),
                      ),
                      // Nút "Đăng ký ngay"
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: const Text(
                          "Chưa có tài khoản? Đăng ký ngay",
                          style: TextStyle(color: Colors.deepOrange),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Phương thức helper để tạo InputDecoration cho các trường nhập liệu
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.orange),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}