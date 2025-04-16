import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'language_teacher_crm.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Students table
    await db.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        language TEXT NOT NULL,
        level TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Classes table
    await db.execute('''
      CREATE TABLE classes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        date_time TEXT NOT NULL,
        duration INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');

    // Payments table
    await db.execute('''
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        description TEXT,
        invoice_number TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');

    // Progress table
    await db.execute('''
      CREATE TABLE progress(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        notes TEXT NOT NULL,
        assessment TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');
  }

  // Helper method to insert a record
  Future<int> insert(String table, Map<String, dynamic> data) async {
    Database db = await database;
    return await db.insert(table, data);
  }

  // Helper method to query all records from a table
  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    Database db = await database;
    return await db.query(table);
  }

  // Helper method to query by ID
  Future<List<Map<String, dynamic>>> queryById(String table, int id) async {
    Database db = await database;
    return await db.query(table, where: 'id = ?', whereArgs: [id]);
  }

  // Helper method for custom queries
  Future<List<Map<String, dynamic>>> rawQuery(String query, [List<dynamic>? arguments]) async {
    Database db = await database;
    return await db.rawQuery(query, arguments);
  }

  // Helper method to update a record
  Future<int> update(String table, Map<String, dynamic> data, int id) async {
    Database db = await database;
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  // Helper method to delete a record
  Future<int> delete(String table, int id) async {
    Database db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}