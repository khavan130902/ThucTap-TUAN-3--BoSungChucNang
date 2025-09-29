import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Màu chính mới
  static const Color primaryPurple = Color(0xFFB08FCA);
  // Màu nền cho màn hình Chat
  static const Color lightBackground = Color(0xFFF7F2FC); // Tím rất nhạt

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  void _scrollToBottom() {
    // Đảm bảo tin nhắn mới nhất luôn hiển thị
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    // 1. Cập nhật UI: Thêm tin nhắn người dùng và BẬT Loading
    setState(() {
      _messages.add({"role": "user", "content": text});
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // 2. Gọi API
      // Sử dụng ChatService.sendMessage đã được cung cấp
      final reply = await ChatService.sendMessage(text);

      // 3. Cập nhật UI: Thêm phản hồi AI
      setState(() {
        _messages.add({"role": "assistant", "content": reply});
      });

    } catch (e) {
      debugPrint('Lỗi không mong muốn ở ChatScreen: $e');
      setState(() {
        _messages.add({"role": "assistant", "content": "⚠️ Lỗi không xác định: $e"});
      });
    } finally {
      // 4. TẮT Loading trong mọi trường hợp
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Thay thế primaryColor của Theme bằng màu tím mới
    const primaryColor = primaryPurple;

    return Scaffold(
      // Màu nền nhẹ hơn cho cảm giác dễ chịu
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text(
          "Chat Hỗ Trợ Học Tập",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4, // Thêm bóng cho AppBar
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              // Đảm bảo tin nhắn mới nhất nằm ở dưới cùng
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              // Duyệt ngược list để tin nhắn mới nhất hiển thị dưới cùng
              itemBuilder: (context, index) {
                final msg = _messages[_messages.length - 1 - index];
                final isUser = msg["role"] == "user";
                return _buildMessageBubble(msg["content"] ?? "", isUser, primaryColor);
              },
            ),
          ),
          // Hiển thị Loading indicator ngay trên thanh nhập liệu
          if (_isLoading)
            LinearProgressIndicator(
              backgroundColor: primaryColor.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryPurple), // Màu tím đậm
            ),
          _buildInputBar(primaryColor),
        ],
      ),
    );
  }

  // --- Widget tách riêng để xây dựng Message Bubble ---
  Widget _buildMessageBubble(String content, bool isUser, Color primaryColor) {
    // Điều chỉnh độ bo tròn tùy theo vai trò
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        // Giới hạn chiều rộng tối đa của bubble
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
        decoration: BoxDecoration(
          color: isUser ? primaryColor : Colors.white,
          borderRadius: borderRadius,
          // Thêm bóng nhẹ cho bubble (đặc biệt cho tin nhắn của AI)
          boxShadow: [
            BoxShadow(
              color: isUser ? primaryColor.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          content,
          style: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
              fontSize: 15,
              height: 1.4 // Tăng khoảng cách dòng
          ),
        ),
      ),
    );
  }

  // --- Widget tách riêng để xây dựng Thanh nhập liệu ---
  Widget _buildInputBar(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      // Đổ bóng cho thanh nhập liệu
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: _isLoading ? "Đang xử lý..." : "Nhập câu hỏi...",
                hintStyle: TextStyle(color: Colors.grey[500]),
                // Loại bỏ đường viền mặc định, thay bằng style riêng
                border: InputBorder.none,
                filled: true,
                fillColor: lightBackground, // Màu nền tím nhạt hơn một chút
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.8), width: 1.5),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _isLoading ? Colors.grey : primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _isLoading ? null : _sendMessage,
              // Tăng kích thước khu vực chạm cho icon
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
