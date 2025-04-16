import 'package:intl/intl.dart';
import 'database_helper.dart';

class Class {
  final int? id;
  final int studentId;
  final String title;
  final String? description;
  final String dateTime; // ISO 8601 format
  final int duration; // in minutes
  final String status; // scheduled, completed, cancelled
  final String createdAt;
  final String updatedAt;

  Class({
    this.id,
    required this.studentId,
    required this.title,
    this.description,
    required this.dateTime,
    required this.duration,
    required this.status,
    String? createdAt,
    String? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    this.updatedAt = updatedAt ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'title': title,
      'description': description,
      'date_time': dateTime,
      'duration': duration,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Class.fromMap(Map<String, dynamic> map) {
    return Class(
      id: map['id'],
      studentId: map['student_id'],
      title: map['title'],
      description: map['description'],
      dateTime: map['date_time'],
      duration: map['duration'],
      status: map['status'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Class copyWith({
    int? id,
    int? studentId,
    String? title,
    String? description,
    String? dateTime,
    int? duration,
    String? status,
  }) {
    return Class(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      createdAt: this.createdAt,
      updatedAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );
  }

  DateTime get getDateTime => DateTime.parse(dateTime);
  
  String get formattedDateTime => 
      DateFormat('MMM d, yyyy · h:mm a').format(DateTime.parse(dateTime));

  String get formattedDuration {
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    if (hours > 0) {
      return '${hours}h${minutes > 0 ? ' ${minutes}m' : ''}';
    }
    return '${minutes}m';
  }
}

class ClassProvider {
  final dbHelper = DatabaseHelper();

  Future<int> insertClass(Class classObj) async {
    final classMap = classObj.toMap();
    if (classMap['id'] == null) {
      classMap.remove('id');
    }
    return await dbHelper.insert('classes', classMap);
  }

  Future<List<Class>> getAllClasses() async {
    final classMaps = await dbHelper.queryAll('classes');
    return classMaps.map((map) => Class.fromMap(map)).toList();
  }

  Future<Class?> getClassById(int id) async {
    final classMaps = await dbHelper.queryById('classes', id);
    if (classMaps.isEmpty) return null;
    return Class.fromMap(classMaps.first);
  }

  Future<List<Class>> getClassesByStudentId(int studentId) async {
    final classMaps = await dbHelper.rawQuery(
      'SELECT * FROM classes WHERE student_id = ? ORDER BY date_time DESC', 
      [studentId]
    );
    return classMaps.map((map) => Class.fromMap(map)).toList();
  }
  
  Future<List<Class>> getUpcomingClasses() async {
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final classMaps = await dbHelper.rawQuery(
      'SELECT * FROM classes WHERE date_time > ? AND status != "cancelled" ORDER BY date_time ASC', 
      [now]
    );
    return classMaps.map((map) => Class.fromMap(map)).toList();
  }

  Future<int> updateClass(Class classObj) async {
    if (classObj.id == null) return 0;
    return await dbHelper.update('classes', classObj.toMap(), classObj.id!);
  }

  Future<int> deleteClass(int id) async {
    return await dbHelper.delete('classes', id);
  }

  Future<Map<String, int>> getClassesStatistics() async {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(today.year, today.month, 1);
    
    final startOfWeekStr = DateFormat('yyyy-MM-dd').format(startOfWeek);
    final startOfMonthStr = DateFormat('yyyy-MM-dd').format(startOfMonth);
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    
    final todayResult = await dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM classes WHERE date(date_time) = ?', 
      [todayStr]
    );
    
    final weekResult = await dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM classes WHERE date(date_time) >= ?', 
      [startOfWeekStr]
    );
    
    final monthResult = await dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM classes WHERE date(date_time) >= ?', 
      [startOfMonthStr]
    );
    
    final totalResult = await dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM classes'
    );
    
    return {
      'today': todayResult.first['count'] as int,
      'week': weekResult.first['count'] as int,
      'month': monthResult.first['count'] as int,
      'total': totalResult.first['count'] as int,
    };
  }
}