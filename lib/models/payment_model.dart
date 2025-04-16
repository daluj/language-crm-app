import 'package:intl/intl.dart';
import 'database_helper.dart';

class Payment {
  final int? id;
  final int studentId;
  final double amount;
  final String date; // YYYY-MM-DD
  final String status; // paid, pending, cancelled
  final String? description;
  final String? invoiceNumber;
  final String createdAt;
  final String updatedAt;

  Payment({
    this.id,
    required this.studentId,
    required this.amount,
    required this.date,
    required this.status,
    this.description,
    this.invoiceNumber,
    String? createdAt,
    String? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    this.updatedAt = updatedAt ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'amount': amount,
      'date': date,
      'status': status,
      'description': description,
      'invoice_number': invoiceNumber,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      studentId: map['student_id'],
      amount: map['amount'].toDouble(),
      date: map['date'],
      status: map['status'],
      description: map['description'],
      invoiceNumber: map['invoice_number'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Payment copyWith({
    int? id,
    int? studentId,
    double? amount,
    String? date,
    String? status,
    String? description,
    String? invoiceNumber,
  }) {
    return Payment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      description: description ?? this.description,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      createdAt: this.createdAt,
      updatedAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );
  }
  
  String get formattedAmount => NumberFormat.currency(symbol: '\$').format(amount);
  
  String get formattedDate => DateFormat('MMM d, yyyy').format(DateTime.parse(date));
}

class PaymentProvider {
  final dbHelper = DatabaseHelper();

  Future<int> insertPayment(Payment payment) async {
    final paymentMap = payment.toMap();
    if (paymentMap['id'] == null) {
      paymentMap.remove('id');
    }
    return await dbHelper.insert('payments', paymentMap);
  }

  Future<List<Payment>> getAllPayments() async {
    final paymentMaps = await dbHelper.queryAll('payments');
    return paymentMaps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<Payment?> getPaymentById(int id) async {
    final paymentMaps = await dbHelper.queryById('payments', id);
    if (paymentMaps.isEmpty) return null;
    return Payment.fromMap(paymentMaps.first);
  }

  Future<List<Payment>> getPaymentsByStudentId(int studentId) async {
    final paymentMaps = await dbHelper.rawQuery(
      'SELECT * FROM payments WHERE student_id = ? ORDER BY date DESC', 
      [studentId]
    );
    return paymentMaps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<int> updatePayment(Payment payment) async {
    if (payment.id == null) return 0;
    return await dbHelper.update('payments', payment.toMap(), payment.id!);
  }

  Future<int> deletePayment(int id) async {
    return await dbHelper.delete('payments', id);
  }

  Future<Map<String, dynamic>> getPaymentStatistics() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);
    
    final startOfMonthStr = DateFormat('yyyy-MM-dd').format(startOfMonth);
    final startOfYearStr = DateFormat('yyyy-MM-dd').format(startOfYear);
    
    final monthResult = await dbHelper.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE date >= ? AND status = "paid"', 
      [startOfMonthStr]
    );
    
    final yearResult = await dbHelper.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE date >= ? AND status = "paid"', 
      [startOfYearStr]
    );
    
    final totalResult = await dbHelper.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE status = "paid"'
    );
    
    final pendingResult = await dbHelper.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE status = "pending"'
    );
    
    return <String, dynamic>{
      'month': monthResult.first['total'] ?? 0.0,
      'year': yearResult.first['total'] ?? 0.0,
      'total': totalResult.first['total'] ?? 0.0,
      'pending': pendingResult.first['total'] ?? 0.0
    };
  }
  
  Future<String> generateInvoiceNumber() async {
    final result = await dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM payments'
    );
    final count = result.first['count'] as int;
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}-${(count + 1).toString().padLeft(3, '0')}';
  }
}