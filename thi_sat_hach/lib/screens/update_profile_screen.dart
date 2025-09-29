import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../db_helper.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  Map<String, dynamic>? _user;

  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedAvatar;
  bool _isLoading = false;

  final List<String> _predefinedAvatars = [
    'avatar1.png',
    'avatar2.png',
    'avatar3.png',
    'avatar4.png',
    'avatar5.png',
    'avatar6.png',
    'avatar7.png',
    'avatar8.png',
    'avatar9.png',
    'avatar10.png',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (_user == null && args != null) {
      _user = args['user'];
      _fullnameController.text = _user?['fullname'] ?? '';
      _emailController.text = _user?['email'] ?? '';
      _selectedAvatar = _user?['avatar'];
    }
  }

  Future<void> _updateProfile() async {
    if (_user == null) return;

    final fullname = _fullnameController.text.trim();
    final email = _emailController.text.trim();

    if (fullname.isEmpty || email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Vui lòng nhập đầy đủ thông tin")),
        );
      }
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Email không hợp lệ")),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint("✏️ Đang cập nhật user id=${_user!['id']}");

      final updatedData = {
        "fullname": fullname,
        "email": email,
        "avatar": _selectedAvatar,
        // Giữ lại các trường khác (ví dụ: username)
        "username": _user!['username'],
      };

      final rows = await DBHelper.instance.update(
        "users",
        updatedData,
        where: "id = ?",
        whereArgs: [_user!['id']],
      );

      if (rows > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Cập nhật thành công")),
          );
          // TRẢ VỀ TOÀN BỘ DỮ LIỆU ĐÃ CẬP NHẬT
          Navigator.pop(context, {
            ..._user!,
            ...updatedData,
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ Không tìm thấy người dùng")),
          );
        }
      }
    } catch (e, st) {
      debugPrint("❌ Lỗi cập nhật profile: $e\n$st");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi cập nhật: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Phương thức mới để chọn ảnh từ thư viện
  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedAvatar = pickedFile.path;
      });
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showAvatarSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Chọn hình đại diện"),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút "Chọn từ thư viện"
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text("Chọn từ thư viện"),
                    onTap: _pickImageFromGallery,
                  ),
                  const Divider(),
                  // Lưới ảnh có sẵn
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _predefinedAvatars.length,
                    itemBuilder: (context, index) {
                      final avatarName = _predefinedAvatars[index];
                      final isSelected = _selectedAvatar == avatarName;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatar = avatarName;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: isSelected
                                ? Border.all(color: Colors.blue, width: 3)
                                : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              "assets/img/$avatarName",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Đóng"),
            ),
          ],
        );
      },
    );
  }

  // Hàm helper để xác định Widget Avatar cần hiển thị
  Widget _getAvatarWidget(String? avatarPath) {
    if (avatarPath != null) {
      final file = File(avatarPath);
      // Kiểm tra nếu đó là file từ gallery (đường dẫn tuyệt đối)
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        );
      }
      // Nếu là tên asset
      else if (avatarPath.endsWith('.png') || avatarPath.endsWith('.jpg')) {
        return Image.asset(
          "assets/img/$avatarPath",
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.person, size: 50, color: Colors.grey);
          },
        );
      }
    }
    return const Icon(Icons.person, size: 50, color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text("❌ Không tìm thấy user")),
      );
    }

    final avatarWidget = _getAvatarWidget(_selectedAvatar);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cập nhật thông tin"),
        backgroundColor: const Color(0xFFFCC8D1),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFCC8D1),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Avatar với nút chọn ảnh
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey.shade200,
                            child: ClipOval(child: avatarWidget),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: _showAvatarSelectionDialog,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _fullnameController,
                        decoration: InputDecoration(
                          labelText: "Họ tên",
                          prefixIcon: const Icon(Icons.badge),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: theme.colorScheme.primary,
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
                              : const Icon(Icons.save),
                          label: const Text(
                            "Lưu thay đổi",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}