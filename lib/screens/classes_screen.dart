import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';
import '../models/class_model.dart';
import '../widgets/common_widgets.dart';

class ClassesScreen extends StatefulWidget {
  @override
  _ClassesScreenState createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final ClassProvider _classProvider = ClassProvider();
  final StudentProvider _studentProvider = StudentProvider();
  
  List<Class> _classes = [];
  List<Class> _selectedDayClasses = [];
  List<Student> _students = [];
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  bool _isLoading = true;
  bool _isLoadingStudents = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isLoadingStudents = true;
    });
    
    try {
      // Load data in parallel
      final classesFuture = _classProvider.getAllClasses();
      final studentsFuture = _studentProvider.getAllStudents();
      
      final results = await Future.wait([classesFuture, studentsFuture]);
      
      setState(() {
        _classes = results[0] as List<Class>;
        _students = results[1] as List<Student>;
        _isLoading = false;
        _isLoadingStudents = false;
        _updateSelectedDayClasses();
      });
    } catch (e) {
      print('Error loading classes data: $e');
      setState(() {
        _isLoading = false;
        _isLoadingStudents = false;
      });
    }
  }
  
  void _updateSelectedDayClasses() {
    final selectedDate = DateFormat('yyyy-MM-dd').format(_selectedDay);
    _selectedDayClasses = _classes.where((classItem) {
      final classDate = DateFormat('yyyy-MM-dd').format(classItem.getDateTime);
      return classDate == selectedDate;
    }).toList();
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
        title: Text('Classes'),
        actions: [
          IconButton(
            icon: Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
                _updateSelectedDayClasses();
              });
            },
            tooltip: 'Today',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendar(),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(Icons.event_note, color: Theme.of(context).colorScheme.primary),
                      SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildClassList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditClassDialog(context),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Schedule Class',
      ),
    );
  }
  
  Widget _buildCalendar() {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          eventLoader: (day) {
            final dayStr = DateFormat('yyyy-MM-dd').format(day);
            return _classes.where((classItem) {
              final classDate = DateFormat('yyyy-MM-dd').format(classItem.getDateTime);
              return classDate == dayStr;
            }).toList();
          },
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            markerSize: 8,
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
            titleCentered: true,
            formatButtonShowsNext: false,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _updateSelectedDayClasses();
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
      ),
    );
  }
  
  Widget _buildClassList() {
    if (_selectedDayClasses.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          message: 'No classes scheduled for ${DateFormat('MMMM d, yyyy').format(_selectedDay)}',
          icon: Icons.event_busy,
          actionLabel: 'Schedule Class',
          onActionPressed: () => _showAddEditClassDialog(context),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _selectedDayClasses.length,
      itemBuilder: (context, index) {
        final classItem = _selectedDayClasses[index];
        final startTime = DateFormat('h:mm a').format(classItem.getDateTime);
        final endTime = DateFormat('h:mm a').format(
          classItem.getDateTime.add(Duration(minutes: classItem.duration)),
        );
        
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showAddEditClassDialog(context, classItem),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          classItem.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      StatusBadge(status: classItem.status),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        _getStudentName(classItem.studentId),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        '$startTime - $endTime (${classItem.formattedDuration})',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  if (classItem.description != null && classItem.description!.isNotEmpty) ...[  
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              classItem.description!,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _deleteClass(classItem),
                        icon: Icon(Icons.delete_outline, size: 18),
                        label: Text('Cancel Class'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _deleteClass(Class classItem) async {
    final confirm = await showConfirmationDialog(
      context: context,
      title: 'Cancel Class',
      content: 'Are you sure you want to cancel this class with ${_getStudentName(classItem.studentId)}?',
      confirmText: 'Cancel Class',
    );
    
    if (confirm) {
      try {
        // Instead of deleting, mark as cancelled
        final updatedClass = classItem.copyWith(status: 'cancelled');
        await _classProvider.updateClass(updatedClass);
        
        setState(() {
          final index = _classes.indexWhere((c) => c.id == classItem.id);
          if (index != -1) {
            _classes[index] = updatedClass;
          }
          _updateSelectedDayClasses();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Class cancelled successfully'),
          behavior: SnackBarBehavior.floating,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error cancelling class: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
  
  Future<void> _showAddEditClassDialog(BuildContext context, [Class? classItem]) async {
    if (_isLoadingStudents || _students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please add students before scheduling classes'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: classItem?.title ?? '');
    final descriptionController = TextEditingController(text: classItem?.description ?? '');
    
    DateTime selectedDateTime = classItem?.getDateTime ?? DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, DateTime.now().hour, 0);
    int selectedDuration = classItem?.duration ?? 60;
    int selectedStudentId = classItem?.studentId ?? _students.first.id!;
    String selectedStatus = classItem?.status ?? 'scheduled';
    
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(classItem == null ? 'Schedule Class' : 'Edit Class'),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomDropdownField<int>(
                    label: 'Student',
                    value: selectedStudentId,
                    items: _students.map((student) => DropdownMenuItem<int>(
                      value: student.id!,
                      child: Text(student.name),
                    )).toList(),
                    onChanged: (value) {
                      selectedStudentId = value!;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Class Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  Text('Date & Time', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.calendar_today),
                    title: Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(selectedDateTime),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            selectedDateTime.hour,
                            selectedDateTime.minute,
                          );
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.access_time),
                    title: Text(
                      DateFormat('h:mm a').format(selectedDateTime),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDateTime = DateTime(
                            selectedDateTime.year,
                            selectedDateTime.month,
                            selectedDateTime.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  Text('Duration', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Slider(
                    value: selectedDuration.toDouble(),
                    min: 15,
                    max: 180,
                    divisions: 11,
                    label: '${selectedDuration} min',
                    onChanged: (value) {
                      setState(() {
                        selectedDuration = value.toInt();
                      });
                    },
                  ),
                  Center(
                    child: Text(
                      '$selectedDuration minutes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (classItem != null) ...[  
                    SizedBox(height: 16),
                    CustomDropdownField<String>(
                      label: 'Status',
                      value: selectedStatus,
                      items: ['scheduled', 'completed', 'cancelled'].map((status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(status.substring(0, 1).toUpperCase() + status.substring(1)),
                      )).toList(),
                      onChanged: (value) {
                        selectedStatus = value!;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final dateTimeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDateTime);
                  
                  if (classItem == null) {
                    // Add new class
                    final newClass = Class(
                      studentId: selectedStudentId,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : null,
                      dateTime: dateTimeStr,
                      duration: selectedDuration,
                      status: 'scheduled',
                    );
                    
                    final id = await _classProvider.insertClass(newClass);
                    final addedClass = newClass.copyWith(id: id);
                    
                    setState(() {
                      _classes.add(addedClass);
                      if (DateFormat('yyyy-MM-dd').format(selectedDateTime) == 
                          DateFormat('yyyy-MM-dd').format(_selectedDay)) {
                        _selectedDayClasses.add(addedClass);
                      }
                    });
                  } else {
                    // Update existing class
                    final updatedClass = classItem.copyWith(
                      studentId: selectedStudentId,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : null,
                      dateTime: dateTimeStr,
                      duration: selectedDuration,
                      status: selectedStatus,
                    );
                    
                    await _classProvider.updateClass(updatedClass);
                    
                    setState(() {
                      final index = _classes.indexWhere((c) => c.id == classItem.id);
                      if (index != -1) {
                        _classes[index] = updatedClass;
                      }
                      _updateSelectedDayClasses();
                    });
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(classItem == null ? 'Class scheduled successfully' : 'Class updated successfully'),
                    behavior: SnackBarBehavior.floating,
                  ));
                  
                  Navigator.of(dialogContext).pop(true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error saving class: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            child: Text(classItem == null ? 'Schedule' : 'Update'),
          ),
        ],
      ),
    );
  }
}