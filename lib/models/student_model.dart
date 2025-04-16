import 'package:intl/intl.dart';
import 'database_helper.dart';

class Student {
  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String language;
  final String? level;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  Student({
    this.id,
    required this.name,
    this.email,
    this.phone,
    required this.language,
    this.level,
    this.notes,
    String? createdAt,
    String? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    this.updatedAt = updatedAt ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'language': language,
      'level': level,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      language: map['language'],
      level: map['level'],
      notes: map['notes'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Student copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? language,
    String? level,
    String? notes,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      language: language ?? this.language,
      level: level ?? this.level,
      notes: notes ?? this.notes,
      createdAt: this.createdAt,
      updatedAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );
  }
}

class StudentProvider {
  final dbHelper = DatabaseHelper();

  Future<int> insertStudent(Student student) async {
    final studentMap = student.toMap();
    // Remove id if it's null to let SQLite auto-generate it
    if (studentMap['id'] == null) {
      studentMap.remove('id');
    }
    return await dbHelper.insert('students', studentMap);
  }

  Future<List<Student>> getAllStudents() async {
    final studentMaps = await dbHelper.queryAll('students');
    return studentMaps.map((map) => Student.fromMap(map)).toList();
  }

  Future<Student?> getStudentById(int id) async {
    final studentMaps = await dbHelper.queryById('students', id);
    if (studentMaps.isEmpty) return null;
    return Student.fromMap(studentMaps.first);
  }

  Future<int> updateStudent(Student student) async {
    if (student.id == null) return 0;
    return await dbHelper.update('students', student.toMap(), student.id!);
  }

  Future<int> deleteStudent(int id) async {
    return await dbHelper.delete('students', id);
  }

  Future<List<Student>> searchStudents(String query) async {
    final studentMaps = await dbHelper.rawQuery(
      "SELECT * FROM students WHERE name LIKE ? OR email LIKE ? OR phone LIKE ?", 
      ['%$query%', '%$query%', '%$query%']
    );
    return studentMaps.map((map) => Student.fromMap(map)).toList();
  }

  Future<int> getStudentCount() async {
    final result = await dbHelper.rawQuery('SELECT COUNT(*) as count FROM students');
    return result.first['count'] as int;
  }
}