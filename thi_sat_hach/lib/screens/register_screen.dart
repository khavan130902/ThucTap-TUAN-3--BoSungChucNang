import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:password_strength/password_strength.dart';
import 'package:clipboard/clipboard.dart';
// import '../db_helper.dart'; // Giả định DBHelper nằm ở đây

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();

  String? _passwordStrengthMsg;
  Color _passwordStrengthColor = Colors.transparent;

  bool _obscurePwd = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullnameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    final strength = estimatePasswordStrength(password);
    setState(() {
      if (password.isEmpty) {
        _passwordStrengthMsg = null;
        _passwordStrengthColor = Colors.transparent;
      } else if (strength < 0.3) {
        _passwordStrengthMsg = "Rất yếu";
        _passwordStrengthColor = Colors.red;
      } else if (strength < 0.6) {
        _passwordStrengthMsg = "Trung bình";
        _passwordStrengthColor = Colors.orange;
      } else {
        _passwordStrengthMsg = "Mạnh";
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final fullname = _fullnameController.text.trim();
    final email = _emailController.text.trim();

    setState(() => _isLoading = true);

    try {
      // Vì bạn dùng code cũ với DBHelper, tôi giữ nguyên logic
      // LƯU Ý: Trong project Flutter/Firebase, bạn sẽ thay thế bằng Firebase Auth

      // 1. KIỂM TRA TÊN ĐĂNG NHẬP ĐÃ TỒN TẠI (Giả định DBHelper có)
      // final usernameExists = await DBHelper.instance.rawQuery(
      //   "SELECT id FROM users WHERE username = ?",
      //   [username],
      // );

      // if (usernameExists.isNotEmpty) {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text("❌ Tên đăng nhập đã tồn tại")),
      //     );
      //   }
      //   return;
      // }

      // 2. KIỂM TRA EMAIL ĐÃ TỒN TẠI (Giả định DBHelper có)
      // final emailExists = await DBHelper.instance.rawQuery(
      //   "SELECT id FROM users WHERE email = ?",
      //   [email],
      // );

      // if (emailExists.isNotEmpty) {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text("❌ Email này đã được đăng ký")),
      //     );
      //   }
      //   return;
      // }

      // 3. THỰC HIỆN ĐĂNG KÝ (Giả định DBHelper có)
      // await DBHelper.instance.insert("users", {
      //   "username": username,
      //   "password": password,
      //   "fullname": fullname,
      //   "email": email,
      // });

      // **********************************************
      // LƯU Ý: Nếu bạn dùng Firebase, code sẽ là:
      // await FirebaseAuth.instance.createUserWithEmailAndPassword(
      //   email: email,
      //   password: password,
      // );
      // **********************************************

      await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎉 Đăng ký thành công!")),
      );

      // Thay thế bằng /home nếu cần
      Navigator.pop(context); // Quay về màn hình trước (thường là Login)

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi đăng ký: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPasswordGeneratorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return PasswordGeneratorDialog(
          onPasswordGenerated: (password) {
            _passwordController.text = password;
            _confirmPasswordController.text = password;
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng ký tài khoản"),
        backgroundColor: const Color(0xFFA8E6CF),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFA8E6CF),
              Color(0xFFFFD3B6),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Center(
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: "Tên đăng nhập",
                                  prefixIcon: const Icon(Icons.person, color: Color(
                                      0xFFFD9700)),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Vui lòng nhập tên đăng nhập";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePwd,
                                    decoration: InputDecoration(
                                      labelText: "Mật khẩu",
                                      prefixIcon: const Icon(Icons.lock, color: Color(
                                          0xFFFD9700)),
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      suffixIcon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.vpn_key, color: Color(
                                                0xFFFD9700)),
                                            onPressed: _showPasswordGeneratorDialog,
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              _obscurePwd ? Icons.visibility_off : Icons.visibility,
                                              color: const Color(0xFFFD9700),
                                            ),
                                            onPressed: () =>
                                                setState(() => _obscurePwd = !_obscurePwd),
                                          ),
                                        ],
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Vui lòng nhập mật khẩu";
                                      }
                                      // Giữ nguyên kiểm tra độ mạnh, vì nó liên quan đến logic UX
                                      if (estimatePasswordStrength(value) < 0.3) {
                                        return "Mật khẩu quá yếu";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  if (_passwordStrengthMsg != null)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        LinearProgressIndicator(
                                          value: estimatePasswordStrength(_passwordController.text),
                                          color: _passwordStrengthColor,
                                          backgroundColor: Colors.grey[300],
                                          minHeight: 8,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Độ mạnh: $_passwordStrengthMsg",
                                          style: TextStyle(color: _passwordStrengthColor),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: "Xác nhận mật khẩu",
                                  prefixIcon: const Icon(Icons.lock, color: Color(
                                      0xFFFD9700)),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Vui lòng xác nhận mật khẩu";
                                  }
                                  if (value != _passwordController.text) {
                                    return "Mật khẩu không khớp";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _fullnameController,
                                decoration: InputDecoration(
                                  labelText: "Họ và tên",
                                  prefixIcon: const Icon(Icons.badge, color: Color(
                                      0xFFFD9700)),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  prefixIcon: const Icon(Icons.email, color: Color(
                                      0xFFFD9700)),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Vui lòng nhập Email";
                                  }
                                  // Kiểm tra định dạng Email cơ bản
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                    return "Email không hợp lệ";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    backgroundColor: const Color(0xFF80C683),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: _isLoading
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : const Icon(Icons.app_registration),
                                  label: const Text(
                                    "Đăng ký",
                                    style: TextStyle(fontSize: 16, color: Colors.white),
                                  ),
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
          },
        ),
      ),
    );
  }
}

class PasswordGeneratorDialog extends StatefulWidget {
  final Function(String) onPasswordGenerated;

  const PasswordGeneratorDialog({super.key, required this.onPasswordGenerated});

  @override
  State<PasswordGeneratorDialog> createState() => _PasswordGeneratorDialogState();
}

class _PasswordGeneratorDialogState extends State<PasswordGeneratorDialog> {
  int _length = 12;
  bool _includeLowercase = true;
  bool _includeUppercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  String _generatedPassword = '';
  // ⭐ BIẾN MỚI: Theo dõi xem mật khẩu đã được sao chép chưa
  bool _isPasswordCopied = false;

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()-_+=[]{}|;:,.<>?';

    String chars = '';
    if (_includeLowercase) chars += lowercase;
    if (_includeUppercase) chars += uppercase;
    if (_includeNumbers) chars += numbers;
    if (_includeSymbols) chars += symbols;

    if (chars.isEmpty) {
      setState(() {
        _generatedPassword = '';
        _isPasswordCopied = false; // Reset trạng thái sao chép
      });
      return;
    }

    final rnd = Random();
    String password = '';
    for (int i = 0; i < _length; i++) {
      password += chars[rnd.nextInt(chars.length)];
    }

    setState(() {
      _generatedPassword = password;
      // ⭐ RESET: Khi mật khẩu mới được tạo (do thay đổi tham số), yêu cầu sao chép lại
      _isPasswordCopied = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final passwordStrength = estimatePasswordStrength(_generatedPassword);

    return AlertDialog(
      title: const Text("Tạo mật khẩu ngẫu nhiên"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: _generatedPassword,
              readOnly: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      Icons.copy,
                      // Màu sắc gợi ý trạng thái sao chép
                      color: _isPasswordCopied ? Colors.green : const Color(0xFFFD9700)
                  ),
                  onPressed: () {
                    FlutterClipboard.copy(_generatedPassword);
                    // ⭐ CẬP NHẬT TRẠNG THÁI SAO CHÉP
                    setState(() {
                      _isPasswordCopied = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Đã sao chép mật khẩu. Bạn có thể sử dụng.")),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: passwordStrength,
                    color: passwordStrength < 0.3 ? Colors.red : (passwordStrength < 0.6 ? Colors.orange : Colors.green),
                    backgroundColor: Colors.grey[300],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  passwordStrength < 0.3 ? "Yếu" : (passwordStrength < 0.6 ? "Trung bình" : "Mạnh"),
                  style: TextStyle(
                    color: passwordStrength < 0.3 ? Colors.red : (passwordStrength < 0.6 ? Colors.orange : Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text("Độ dài:"),
            Slider(
              value: _length.toDouble(),
              min: 8,
              max: 20,
              divisions: 12,
              label: _length.toString(),
              onChanged: (double value) {
                setState(() {
                  _length = value.round();
                  _generatePassword();
                });
              },
            ),
            CheckboxListTile(
              title: const Text("Chữ thường (abc)"),
              value: _includeLowercase,
              onChanged: (bool? value) {
                setState(() {
                  _includeLowercase = value!;
                  _generatePassword();
                });
              },
            ),
            CheckboxListTile(
              title: const Text("Chữ hoa (ABC)"),
              value: _includeUppercase,
              onChanged: (bool? value) {
                setState(() {
                  _includeUppercase = value!;
                  _generatePassword();
                });
              },
            ),
            CheckboxListTile(
              title: const Text("Số (123)"),
              value: _includeNumbers,
              onChanged: (bool? value) {
                setState(() {
                  _includeNumbers = value!;
                  _generatePassword();
                });
              },
            ),
            CheckboxListTile(
              title: const Text("Ký tự đặc biệt (!@#)"),
              value: _includeSymbols,
              onChanged: (bool? value) {
                setState(() {
                  _includeSymbols = value!;
                  _generatePassword();
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Hủy"),
        ),
        ElevatedButton(
          // ⭐ ĐIỀU KIỆN VÔ HIỆU HÓA: Chỉ cho phép sử dụng nếu đã sao chép
          onPressed: _isPasswordCopied
              ? () => widget.onPasswordGenerated(_generatedPassword)
              : null, // null sẽ vô hiệu hóa nút
          child: const Text("Sử dụng mật khẩu"),
        ),
      ],
    );
  }
}