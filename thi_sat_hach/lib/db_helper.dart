import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static const _dbName = "Cau_Thi.db";
  static Database? _database;

  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// ✅ Khởi tạo database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    // Copy DB từ assets nếu chưa tồn tại
    if (!await File(path).exists()) {
      await _copyDBFromAssets(path);
    } else {
      print("ℹ️ DB đã tồn tại ở: $path");
    }

    // ✅ Mở DB
    final db = await openDatabase(path, version: 1);

    // Tạo bảng thi thử nếu chưa có
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exam_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        score INTEGER,
        total INTEGER,
        time_used INTEGER,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS exam_detail (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER,
        question_id INTEGER,
        content TEXT,
        user_answer TEXT,
        is_correct INTEGER,
        FOREIGN KEY(exam_id) REFERENCES exam_history(id)
      )
    ''');

    // ✅ Đảm bảo các cột mới tồn tại
    await _ensureColumnExists(db, "exam_detail", "correct_answer", "TEXT");

    print("✅ DB đã mở thành công ở $path");
    return db;
  }

  /// ✅ Copy DB từ assets sang writable path
  Future<void> _copyDBFromAssets(String path) async {
    try {
      await Directory(dirname(path)).create(recursive: true);
      ByteData data = await rootBundle.load("assets/$_dbName");
      List<int> bytes =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
      print("✅ DB copied to writable path: $path");
    } catch (e) {
      print("❌ Copy DB failed: $e");
    }
  }

  /// ✅ Đảm bảo cột tồn tại (nếu chưa thì ALTER TABLE)
  Future<void> _ensureColumnExists(
      Database db, String table, String column, String type) async {
    final cols = await db.rawQuery("PRAGMA table_info($table)");
    final hasCol = cols.any((c) => c["name"] == column);
    if (!hasCol) {
      await db.execute("ALTER TABLE $table ADD COLUMN $column $type");
      print("🆕 Đã thêm cột $column vào bảng $table");
    } else {
      print("ℹ️ Cột $column đã tồn tại trong $table");
    }
  }

  /// ✅ Xóa DB cũ (reset dữ liệu)
  Future<void> deleteOldDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    if (await File(path).exists()) {
      await File(path).delete();
      _database = null;
      print("🗑 DB cũ đã bị xóa!");
    }
  }

  /// ✅ Reset & migrate DB
  Future<void> resetAndMigrate() async {
    await deleteOldDB();
    await database; // Gọi lại để init và ensure cột mới
    print("🔄 Reset & migrate DB thành công!");
  }

  // ======================
  // 📚 Chủ đề & câu hỏi
  // ======================

  Future<List<Map<String, dynamic>>> getTopics() async {
    final db = await database;
    final result = await db.query("topics", orderBy: "id ASC");
    print("📋 Lấy được ${result.length} topics");
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getQuestionsByTopic(int topicId) async {
    final db = await database;
    final result = await db.query(
      "question",
      where: "topic_id = ?",
      whereArgs: [topicId],
      orderBy: "id ASC",
    );
    print("📋 Lấy được ${result.length} câu hỏi cho topic_id=$topicId");
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ======================
  // 📝 Thi thử
  // ======================

  Future<int> saveExamHistory({
    required int userId,
    required int score,
    required int total,
    required int timeUsed,
  }) async {
    final db = await database;
    final examId = await db.insert("exam_history", {
      "user_id": userId,
      "score": score,
      "total": total,
      "time_used": timeUsed,
      "created_at": DateTime.now().toIso8601String(),
    });
    print("✅ Đã lưu exam_history với id=$examId");
    return examId;
  }

  Future<void> saveExamDetail(
      int examId, List<Map<String, dynamic>> answers) async {
    final db = await database;
    for (var ans in answers) {
      await db.insert("exam_detail", {
        "exam_id": examId,
        "question_id": ans["question_id"],
        "content": ans["content"],
        "correct_answer": ans["correct_answer"],
        "user_answer": ans["user_answer"],
        "is_correct": (ans["is_correct"] == true) ? 1 : 0,
      });
    }
    print("✅ Đã lưu ${answers.length} exam_detail cho examId=$examId");
  }

  Future<List<Map<String, dynamic>>> getExamHistory(int userId) async {
    final db = await database;
    final result = await db.query(
      "exam_history",
      where: "user_id = ?",
      whereArgs: [userId],
      orderBy: "created_at DESC",
    );
    final writable = result.map((e) => Map<String, dynamic>.from(e)).toList();
    print("📋 Lấy được ${writable.length} lịch sử thi cho userId=$userId");
    return writable;
  }

  Future<List<Map<String, dynamic>>> getAllExamHistory() async {
    final db = await database;
    final result = await db.query("exam_history", orderBy: "created_at DESC");
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// ✅ Lấy chi tiết 1 kỳ thi
  Future<List<Map<String, dynamic>>> getExamDetail(int examId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT d.id, d.exam_id, d.question_id,
             d.content AS user_content,
             d.correct_answer, d.user_answer, d.is_correct,
             h.created_at,
             q.title AS question_title,
             q.content AS question_content,
             q.ansa AS option_a,
             q.ansb AS option_b,
             q.ansc AS option_c,
             q.ansd AS option_d,
             q.ansright,
             q.anshint
      FROM exam_detail d
      LEFT JOIN question q ON q.id = d.question_id
      LEFT JOIN exam_history h ON h.id = d.exam_id
      WHERE d.exam_id = ?
      ORDER BY d.id ASC
    ''', [examId]);

    print("📋 ExamId=$examId -> Lấy được ${result.length} chi tiết");
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> clearExamData() async {
    final db = await database;
    await db.delete("exam_history");
    await db.delete("exam_detail");
    print("🗑 Đã xóa toàn bộ dữ liệu thi thử");
  }

  // ======================
  // 🧰 Raw Query, Insert, Update
  // ======================

  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<Object?>? args]) async {
    final db = await database;
    final result = await db.rawQuery(sql, args);
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<int> insert(String table, Map<String, Object?> values) async {
    final db = await database;
    return db.insert(table, values);
  }

  Future<int> update(String table, Map<String, Object?> values,
      {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  // ======================
  // 🔎 Debug Helper
  // ======================

  Future<void> debugTables() async {
    final db = await database;
    final tables =
    await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    print("📋 Tables: $tables");
  }

  Future<void> debugColumns(String table) async {
    final db = await database;
    final cols = await db.rawQuery("PRAGMA table_info($table)");
    print("📋 Columns in $table: $cols");
  }

  Future<void> debugQuestionsCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM question"));
    print("📊 Total questions: $count");
  }

  Future<void> debugExamDetailCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM exam_detail"));
    print("📊 Total exam_detail: $count");
  }
}
