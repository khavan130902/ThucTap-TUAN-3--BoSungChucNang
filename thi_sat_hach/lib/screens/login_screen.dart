import 'package:flutter/material.dart';
import '../db_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePwd = true;
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      final result = await DBHelper.instance.rawQuery(
        "SELECT * FROM users WHERE username = ? AND password = ? LIMIT 1",
        [username, password],
      );

      if (result.isNotEmpty) {
        final user = result.first;
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Đăng nhập thành công")),
        );

        Navigator.pushReplacementNamed(context, '/menu', arguments: {'user': user});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Sai tên đăng nhập hoặc mật khẩu")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFA8E6CF), // xanh lá pastel
              Color(0xFFFFD3B6), // cam pastel
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 8,
              color: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 80, color: Colors.green),
                      const SizedBox(height: 20),
                      Text(
                        "Đăng nhập",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _usernameController,
                        validator: (v) => v!.isEmpty ? "Nhập tên đăng nhập" : null,
                        decoration: _inputDecoration("Tên đăng nhập", Icons.person),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePwd,
                        validator: (v) => v!.isEmpty ? "Nhập mật khẩu" : null,
                        decoration: _inputDecoration("Mật khẩu", Icons.lock).copyWith(
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
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
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
                      TextButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("⚠️ Chức năng quên mật khẩu chưa hỗ trợ")),
                        ),
                        child: const Text("Quên mật khẩu?", style: TextStyle(color: Colors.grey)),
                      ),
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
