import 'dart:math';
import 'package:flutter/material.dart';
import 'package:password_strength/password_strength.dart';
import 'package:clipboard/clipboard.dart';
import '../db_helper.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  int? _userId;
  bool _obscureCurrentPwd = true;
  bool _obscurePwd = true;
  String? _passwordStrengthMsg;
  Color _passwordStrengthColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _userId = args?['userId'] as int?;
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

  void _showPasswordGeneratorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // Truyền giá trị hiện tại của mật khẩu mới vào dialog
        return PasswordGeneratorDialog(
          initialPassword: _passwordController.text,
          onPasswordGenerated: (password) {
            _passwordController.text = password;
            _confirmController.text = password;
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Không tìm thấy userId")),
      );
      return;
    }

    final currentPassword = _currentPasswordController.text.trim();
    final user = await DBHelper.instance.rawQuery(
      "SELECT * FROM users WHERE id = ? AND password = ?",
      [_userId, currentPassword],
    );

    if (user.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Mật khẩu hiện tại không đúng")),
      );
      return;
    }

    final newPassword = _passwordController.text.trim();

    try {
      final rows = await DBHelper.instance.update(
        "users",
        {"password": newPassword},
        where: "id = ?",
        whereArgs: [_userId],
      );

      if (rows > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Đổi mật khẩu thành công")),
          );
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Không tìm thấy người dùng")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi cập nhật mật khẩu: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cập nhật mật khẩu"),
        backgroundColor: const Color(0xFFFCC8D1),
        foregroundColor: Colors.white,
      ),
      body: Container(
        // Thay đổi ở đây để phối màu
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFCC8D1), // Màu trên cùng
              Color(0xFFFFFFFF), // Màu dưới cùng
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Nhập mật khẩu hiện tại
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPwd,
                  decoration: InputDecoration(
                    labelText: "Mật khẩu hiện tại",
                    prefixIcon: const Icon(Icons.lock_open),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPwd
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCurrentPwd = !_obscureCurrentPwd),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Vui lòng nhập mật khẩu hiện tại";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nhập mật khẩu mới
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePwd,
                  decoration: InputDecoration(
                    labelText: "Mật khẩu mới",
                    prefixIcon: const Icon(Icons.lock),
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
                          icon: const Icon(Icons.vpn_key),
                          onPressed: _showPasswordGeneratorDialog,
                        ),
                        IconButton(
                          icon: Icon(
                            _obscurePwd ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                        ),
                      ],
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Vui lòng nhập mật khẩu mới";
                    }
                    if (estimatePasswordStrength(value) < 0.3) {
                      return "Mật khẩu quá yếu";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Strength indicator
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

                const SizedBox(height: 16),

                // Xác nhận mật khẩu mới
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Xác nhận mật khẩu mới",
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Vui lòng xác nhận mật khẩu mới";
                    }
                    if (value != _passwordController.text) {
                      return "Mật khẩu không khớp";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // Nút lưu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _updatePassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text("Cập nhật mật khẩu"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// <h2>Chỉnh sửa tại đây: PasswordGeneratorDialog</h2>
class PasswordGeneratorDialog extends StatefulWidget {
  final Function(String) onPasswordGenerated;
  final String initialPassword; // Thêm biến để nhận mật khẩu hiện tại (tùy chọn)

  const PasswordGeneratorDialog({
    super.key,
    required this.onPasswordGenerated,
    this.initialPassword = '',
  });

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
  // THÊM BIẾN THEO DÕI TRẠNG THÁI SAO CHÉP
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo mật khẩu ngẫu nhiên mới, bỏ qua mật khẩu cũ
    _generatePassword();
    // Nếu người dùng đóng dialog và mở lại, trạng thái copied sẽ được reset
    _isCopied = false;
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
      chars = lowercase;
    }

    final rnd = Random.secure();
    String password = '';
    for (int i = 0; i < _length; i++) {
      password += chars[rnd.nextInt(chars.length)];
    }
    setState(() {
      _generatedPassword = password;
      // Khi tạo mật khẩu mới, reset trạng thái sao chép
      _isCopied = false;
    });
  }

  // Phương thức xử lý sao chép
  void _handleCopy() {
    FlutterClipboard.copy(_generatedPassword);
    setState(() {
      _isCopied = true; // Đánh dấu đã sao chép
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Đã sao chép mật khẩu. Bây giờ bạn có thể sử dụng.")),
    );
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
                  icon: const Icon(Icons.copy),
                  onPressed: _handleCopy, // Gọi phương thức xử lý sao chép
                ),
              ),
            ),
            const SizedBox(height: 10),
            // HIỂN THỊ CẢNH BÁO NẾU CHƯA SAO CHÉP
            if (!_isCopied)
              const Text(
                "⚠️ Vui lòng bấm sao chép để có thể sử dụng mật khẩu này.",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 10),
            // KẾT THÚC CẢNH BÁO
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: passwordStrength,
                    color: passwordStrength < 0.3
                        ? Colors.red
                        : (passwordStrength < 0.6 ? Colors.orange : Colors.green),
                    backgroundColor: Colors.grey[300],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  passwordStrength < 0.3
                      ? "Yếu"
                      : (passwordStrength < 0.6 ? "Trung bình" : "Mạnh"),
                  style: TextStyle(
                    color: passwordStrength < 0.3
                        ? Colors.red
                        : (passwordStrength < 0.6 ? Colors.orange : Colors.green),
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
          // VÔ HIỆU HÓA NÚT NẾU CHƯA SAO CHÉP
          onPressed: _isCopied ? () => widget.onPasswordGenerated(_generatedPassword) : null,
          child: const Text("Sử dụng mật khẩu"),
        ),
      ],
    );
  }
}