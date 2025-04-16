import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/student_model.dart';
import '../models/payment_model.dart';
import '../widgets/common_widgets.dart';

class BillingScreen extends StatefulWidget {
  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen>
    with TickerProviderStateMixin {
  final StudentProvider _studentProvider = StudentProvider();
  final PaymentProvider _paymentProvider = PaymentProvider();

  List<Payment> _payments = [];
  List<Student> _students = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, pending, paid

  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load data in parallel
      final paymentsFuture = _paymentProvider.getAllPayments();
      final studentsFuture = _studentProvider.getAllStudents();

      final results = await Future.wait([paymentsFuture, studentsFuture]);

      setState(() {
        _payments = results[0] as List<Payment>;
        _students = results[1] as List<Student>;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      print('Error loading billing data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Payment> get _filteredPayments {
    if (_filter == 'all') return _payments;
    return _payments.where((payment) => payment.status == _filter).toList();
  }

  String _getStudentName(int studentId) {
    final student = _students.firstWhere(
      (student) => student.id == studentId,
      orElse: () => Student(id: -1, name: 'Unknown', language: 'Unknown'),
    );
    return student.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Billing'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: [
            Tab(text: 'Payments'),
            Tab(text: 'Create Invoice'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPaymentsTab(),
                _buildCreateInvoiceTab(),
              ],
            ),
    );
  }

  Widget _buildPaymentsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Payments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildFilterChip('All', 'all'),
                          SizedBox(width: 8),
                          _buildFilterChip('Paid', 'paid'),
                          SizedBox(width: 8),
                          _buildFilterChip('Pending', 'pending'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _filteredPayments.length,
            itemBuilder: (context, index) {
              final payment = _filteredPayments[index];
              return _buildPaymentCard(payment);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      selected: _filter == value,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: _filter == value
            ? Theme.of(context).colorScheme.primary
            : Colors.black,
        fontWeight: _filter == value ? FontWeight.bold : FontWeight.normal,
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getStudentName(payment.studentId),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            payment.description ?? 'Language lessons',
                            style: TextStyle(color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: payment.status),
                  ],
                ),
                Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Amount',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Text(
                            payment.formattedAmount,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Text(
                            payment.formattedDate,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.receipt_long),
                      onPressed: () => _generateAndPrintInvoice(payment),
                      tooltip: 'Generate Invoice',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markAsPaid(Payment payment) async {
    try {
      final updatedPayment = payment.copyWith(status: 'paid');
      await _paymentProvider.updatePayment(updatedPayment);

      setState(() {
        final index = _payments.indexWhere((p) => p.id == payment.id);
        if (index != -1) {
          _payments[index] = updatedPayment;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Payment marked as paid'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating payment: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildCreateInvoiceTab() {
    if (_students.isEmpty) {
      return SingleChildScrollView(
        child: Center(
          child: EmptyStateWidget(
            message: 'You need to add students before creating invoices',
            icon: Icons.people_outline,
            actionLabel: 'Add Students',
            onActionPressed: () {
              // Navigate to students screen
            },
          ),
        ),
      );
    }

    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    Student? selectedStudent;
    String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Invoice',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 24),
                    StatefulBuilder(
                      builder: (context, setState) => CustomDropdownField<Student>(
                        label: 'Student',
                        value: selectedStudent,
                        items: _students.map((student) => DropdownMenuItem<Student>(
                          value: student,
                          child: Text(student.name),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStudent = value;
                          });
                        },
                        hint: 'Select student',
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    StatefulBuilder(
                      builder: (context, setState) => DatePickerField(
                        label: 'Invoice Date',
                        selectedDate: DateTime.parse(selectedDate),
                        onDateSelected: (date) {
                          setState(() {
                            selectedDate = DateFormat('yyyy-MM-dd').format(date);
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'e.g. 5 English lessons, May 2023',
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        StatefulBuilder(
                          builder: (context, setState) => Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (formKey.currentState!.validate() &&
                                    selectedStudent != null) {
                                  try {
                                    final invoiceNumber = await _paymentProvider.generateInvoiceNumber();
                                    
                                    final newPayment = Payment(
                                      studentId: selectedStudent!.id!,
                                      amount: double.parse(amountController.text),
                                      date: selectedDate,
                                      status: 'pending',
                                      description: descriptionController.text.isNotEmpty
                                          ? descriptionController.text
                                          : null,
                                      invoiceNumber: invoiceNumber
                                    );
                                    
                                    final id = await _paymentProvider.insertPayment(newPayment);
                                    final addedPayment = newPayment.copyWith(id: id);
                                    
                                    setState(() {
                                      _payments.add(addedPayment);
                                      _filter = 'all'; // Reset filter to show all
                                      
                                      // Clear form
                                      amountController.clear();
                                      descriptionController.clear();
                                      selectedStudent = null;
                                    });
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text('Invoice created successfully'),
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                    
                                    // Switch to payments tab
                                    _tabController.animateTo(0);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text('Error creating invoice: $e'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                  }
                                }
                              },
                              icon: Icon(Icons.receipt_long),
                              label: Text('Create Invoice'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Billing Tips',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 16),
                    _buildTipItem(
                      icon: Icons.lightbulb_outline,
                      title: 'Create invoices in advance',
                      description: 'Prepare monthly invoices at the beginning of each month for better financial planning.',
                    ),
                    SizedBox(height: 12),
                    _buildTipItem(
                      icon: Icons.attach_money,
                      title: 'Payment packages',
                      description: 'Offer discounted rates for students who book multiple lessons in advance.',
                    ),
                    SizedBox(height: 12),
                    _buildTipItem(
                      icon: Icons.calendar_today,
                      title: 'Regular billing cycles',
                      description: 'Establish consistent billing dates to create predictable income and easier bookkeeping.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _generateAndPrintInvoice(Payment payment) async {
    final student = _students.firstWhere(
      (s) => s.id == payment.studentId,
      orElse: () => Student(id: -1, name: 'Unknown', language: 'Unknown'),
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('INVOICE',
                            style: pw.TextStyle(
                              fontSize: 40,
                              fontWeight: pw.FontWeight.bold,
                            )),
                        pw.SizedBox(height: 5),
                        pw.Text(payment.invoiceNumber ?? 'No Invoice Number',
                            style: pw.TextStyle(fontSize: 16)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Language Teacher CRM',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            )),
                        pw.SizedBox(height: 5),
                        pw.Text('language.teacher@example.com'),
                        pw.Text('+1 (123) 456-7890'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill To:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text(student.name),
                        if (student.email != null) pw.Text(student.email!),
                        if (student.phone != null) pw.Text(student.phone!),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Invoice Date:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(payment.formattedDate),
                        pw.SizedBox(height: 10),
                        pw.Text('Status:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(payment.status.toUpperCase()),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Container(
                  color: PdfColors.grey200,
                  padding: pw.EdgeInsets.all(10),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                          flex: 5,
                          child: pw.Text('Description',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text('Amount',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.right)),
                    ],
                  ),
                ),
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                          flex: 5,
                          child: pw.Text(payment.description ?? 'Language lessons')),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text('\$${payment.amount.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Container(
                              width: 150,
                              child: pw.Text('Total:',
                                  style:
                                      pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Container(
                              width: 100,
                              child: pw.Text('\$${payment.amount.toStringAsFixed(2)}',
                                  textAlign: pw.TextAlign.right,
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Text('Thank you for your business!',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text('Payment Terms: Due upon receipt'),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}