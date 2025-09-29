import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 💡 IMPORT MỚI
import 'db_helper.dart';

// Screens (Giả định các file này tồn tại)
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/topic_screen.dart';
import 'screens/question_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/update_profile_screen.dart';
import 'screens/update_password_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/practice_result_screen.dart';
import 'screens/practice_review_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/practice_history_screen.dart';
import 'screens/chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 💡 BƯỚC KHẮC PHỤC QUAN TRỌNG: Tải file .env trước khi chạy app
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ Đã tải file .env thành công.");
  } catch (e) {
    debugPrint('⚠️ Lỗi tải file .env: $e');
  }

  bool needReset = false;

  try {
    final db = await DBHelper.instance.database;

    // 📌 Lấy danh sách bảng trong DB
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    final tableNames = tables.map((e) => e["name"] as String).toList();

    // Nếu thiếu bảng chính → reset
    if (!tableNames.contains("exam_history") ||
        !tableNames.contains("exam_detail")) {
      needReset = true;
    } else {
      // 📌 Kiểm tra cột trong exam_detail
      final columns = await db.rawQuery("PRAGMA table_info(exam_detail);");
      final columnNames = columns.map((c) => c["name"] as String).toList();

      if (!columnNames.contains("content")) {
        debugPrint("⚠️ Thiếu cột 'content' → thêm tự động...");
        await db.execute("ALTER TABLE exam_detail ADD COLUMN content TEXT;");
        debugPrint("✅ Đã thêm cột content vào bảng exam_detail");
      }

      if (!columnNames.contains("correct_answer")) {
        debugPrint("⚠️ Thiếu cột 'correct_answer' → thêm tự động...");
        await db.execute("ALTER TABLE exam_detail ADD COLUMN correct_answer TEXT;");
        debugPrint("✅ Đã thêm cột correct_answer vào bảng exam_detail");
      }
    }
  } catch (e) {
    debugPrint("⚠️ Lỗi khi kiểm tra DB: $e");
    needReset = true;
  }

  // 🔄 Reset DB nếu lỗi
  if (needReset) {
    debugPrint("⚠️ DB lỗi hoặc thiếu bảng → reset toàn bộ...");
    await DBHelper.instance.deleteOldDB();
    await DBHelper.instance.database; // khởi tạo lại DB sau khi reset
  }

  // 📊 Debug cấu trúc DB (chỉ chạy khi debug mode)
  if (kDebugMode) {
    await DBHelper.instance.debugTables();
    for (var table in [
      "topics",
      "question",
      "users",
      "exam_history",
      "exam_detail"
    ]) {
      await DBHelper.instance.debugColumns(table);
    }
    await DBHelper.instance.debugQuestionsCount();
    await DBHelper.instance.debugExamDetailCount();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thi Sát Hạch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',

      // 📍 Route tĩnh
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/menu': (context) => const MenuScreen(),
        '/chatbot': (context) => const ChatScreen(),
      },

      // 📍 Route động
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/topics':
            return MaterialPageRoute(
              builder: (_) => const TopicScreen(),
              settings: settings,
            );
          case '/questions':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => QuestionScreen(
                topicId: args['topicId'] as int,
                topicName: args['topicName'] as String,
              ),
              settings: settings,
            );

        // Sửa ProfileScreen để sử dụng onGenerateRoute để truyền arguments
          case '/profile':
            return MaterialPageRoute(
              builder: (_) => const ProfileScreen(),
              settings: settings,
            );

          case '/update_profile':
            return MaterialPageRoute(
              builder: (_) => const UpdateProfileScreen(),
              settings: settings,
            );
          case '/update_password':
            return MaterialPageRoute(
              builder: (_) => const UpdatePasswordScreen(),
              settings: settings,
            );
          case '/practice':
            return MaterialPageRoute(
              builder: (_) => const PracticeScreen(),
              settings: settings,
            );
          case '/practice_result':
            return MaterialPageRoute(
              builder: (_) => const PracticeResultScreen(),
              settings: settings,
            );
          case '/practice_review':
            return MaterialPageRoute(
              builder: (_) => const PracticeReviewScreen(),
              settings: settings,
            );
          case '/history':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => PracticeHistoryScreen(user: args['user']),
              settings: settings,
            );
        }
        return null;
      },
    );
  }
}
