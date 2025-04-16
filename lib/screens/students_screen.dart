import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/student_model.dart';
import '../models/class_model.dart';
import '../models/payment_model.dart';
import '../widgets/common_widgets.dart';

class StudentsScreen extends StatefulWidget {
  @override
  _StudentsScreenState createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> with SingleTickerProviderStateMixin {
  final StudentProvider _studentProvider = StudentProvider();
  final List<Student> _students = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadStudents();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    
    try {
      final students = await _studentProvider.getAllStudents();
      setState(() {
        _students.clear();
        _students.addAll(students);
        _filteredStudents = List.from(_students);
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      print('Error loading students: $e');
      setState(() => _isLoading = false);
    }
  }
  
  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = List.from(_students);
      } else {
        _filteredStudents = _students
            .where((student) =>
                student.name.toLowerCase().contains(query.toLowerCase()) ||
                (student.email?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                (student.phone?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students'),
        actions: [
          IconButton(
            icon: Icon(Icons.tune),
            onPressed: () {
              // Show filter/sort options
            },
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchField(
              hint: 'Search students...',
              controller: _searchController,
              onChanged: _filterStudents,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                    ? EmptyStateWidget(
                        message: _searchController.text.isNotEmpty
                            ? 'No students found for "${_searchController.text}"'
                            : 'No students yet. Add your first student!',
                        icon: Icons.people_outline,
                        actionLabel: 'Add Student',
                        onActionPressed: () => _showAddEditStudentDialog(context),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStudents,
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) {
                                final student = _filteredStudents[index];
                                // Apply staggered animation
                                final itemAnimation = Tween<Offset>(
                                  begin: Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: Interval(
                                      index / _filteredStudents.length * 0.6,
                                      (1.0).clamp(0.0, (index + 1) / _filteredStudents.length * 0.6 + 0.4),
                                      curve: Curves.easeOutQuart,
                                    ),
                                  ),
                                );
                                
                                return SlideTransition(
                                  position: itemAnimation,
                                  child: _buildStudentCard(student),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditStudentDialog(context),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Student',
      ),
    );
  }
  
  Widget _buildStudentCard(Student student) {
    return Slidable(
      endActionPane: ActionPane(
        motion: ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            label: 'Edit',
            backgroundColor: Colors.blue,
            icon: Icons.edit,
            onPressed: (context) => _showAddEditStudentDialog(context, student),
          ),
          SlidableAction(
            label: 'Delete',
            backgroundColor: Colors.red,
            icon: Icons.delete,
            onPressed: (context) => _deleteStudent(student),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.only(bottom: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToStudentDetails(student),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getLanguageColor(student.language).withOpacity(0.2),
                  child: Text(
                    _getInitials(student.name),
                    style: TextStyle(
                      color: _getLanguageColor(student.language),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (student.email != null && student.email!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.email_outlined, size: 14, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                student.email!,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      if (student.phone != null && student.phone!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 14, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                student.phone!,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getLanguageColor(student.language).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        student.language,
                        style: TextStyle(
                          color: _getLanguageColor(student.language),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (student.level != null && student.level!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Level: ${student.level}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
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
  
  Color _getLanguageColor(String language) {
    final Map<String, Color> languageColors = {
      'English': Color(0xFF6750A4),    // Purple
      'Spanish': Color(0xFF625B71),    // Dark purple
      'French': Color(0xFF7D5260),     // Mauve
      'German': Color(0xFF984061),     // Deep pink
      'Italian': Color(0xFFA94238),    // Red
      'Chinese': Color(0xFFB58B00),    // Yellow/gold
      'Japanese': Color(0xFF5DB075),   // Green
      'Korean': Color(0xFF1A73E8),     // Blue
      'Russian': Color(0xFF458588),    // Teal
      'Portuguese': Color(0xFFFF5252),  // Red
      'Arabic': Color(0xFFFF9800),     // Orange
    };
    
    return languageColors[language] ?? Colors.grey;
  }
  
  String _getInitials(String name) {
    final nameList = name.split(' ');
    if (nameList.length > 1) {
      return '${nameList[0][0]}${nameList[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
  
  void _navigateToStudentDetails(Student student) {
    // Navigate to student details screen
  }
  
  Future<void> _deleteStudent(Student student) async {
    final confirm = await showConfirmationDialog(
      context: context,
      title: 'Delete Student',
      content: 'Are you sure you want to delete ${student.name}? This will also delete all associated classes and payments.',
      confirmText: 'Delete',
    );
    
    if (confirm) {
      try {
        await _studentProvider.deleteStudent(student.id!);
        setState(() {
          _students.removeWhere((s) => s.id == student.id);
          _filteredStudents.removeWhere((s) => s.id == student.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${student.name} deleted successfully'),
          behavior: SnackBarBehavior.floating,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error deleting student: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
  
  Future<void> _showAddEditStudentDialog(BuildContext context, [Student? student]) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: student?.name ?? '');
    final emailController = TextEditingController(text: student?.email ?? '');
    final phoneController = TextEditingController(text: student?.phone ?? '');
    final notesController = TextEditingController(text: student?.notes ?? '');
    
    String language = student?.language ?? 'English';
    String? level = student?.level;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(student == null ? 'Add Student' : 'Edit Student'),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16),
                  CustomDropdownField<String>(
                    label: 'Language',
                    value: language,
                    items: [
                      'English',
                      'Spanish',
                      'French',
                      'German',
                      'Italian',
                      'Chinese',
                      'Japanese',
                      'Korean',
                      'Russian',
                      'Portuguese',
                      'Arabic',
                      'Other',
                    ].map((lang) => DropdownMenuItem<String>(
                      value: lang,
                      child: Text(lang),
                    )).toList(),
                    onChanged: (value) {
                      language = value!;
                    },
                  ),
                  SizedBox(height: 16),
                  CustomDropdownField<String>(
                    label: 'Level',
                    value: level,
                    items: [
                      'Beginner',
                      'Elementary',
                      'Intermediate',
                      'Upper Intermediate',
                      'Advanced',
                      'Proficient',
                    ].map((lvl) => DropdownMenuItem<String>(
                      value: lvl,
                      child: Text(lvl),
                    )).toList(),
                    onChanged: (value) {
                      level = value;
                    },
                    hint: 'Select level',
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    decoration: InputDecoration(labelText: 'Notes'),
                    maxLines: 3,
                  ),
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
                  if (student == null) {
                    // Add new student
                    final newStudent = Student(
                      name: nameController.text.trim(),
                      email: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
                      phone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                      language: language,
                      level: level,
                      notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                    );
                    
                    final id = await _studentProvider.insertStudent(newStudent);
                    final addedStudent = newStudent.copyWith(id: id);
                    
                    setState(() {
                      _students.add(addedStudent);
                      _filterStudents(_searchController.text);
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${addedStudent.name} added successfully'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  } else {
                    // Update existing student
                    final updatedStudent = student.copyWith(
                      name: nameController.text.trim(),
                      email: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
                      phone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                      language: language,
                      level: level,
                      notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                    );
                    
                    await _studentProvider.updateStudent(updatedStudent);
                    
                    setState(() {
                      final index = _students.indexWhere((s) => s.id == student.id);
                      if (index != -1) {
                        _students[index] = updatedStudent;
                      }
                      _filterStudents(_searchController.text);
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${updatedStudent.name} updated successfully'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                  Navigator.of(dialogContext).pop(true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error saving student: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            child: Text(student == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }
}