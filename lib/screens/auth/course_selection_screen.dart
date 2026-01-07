import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../storage_services.dart';
import '../../providers/app_session_provider.dart';
import '../../providers/app_mode_provider.dart';

class SelectCoursePage extends ConsumerStatefulWidget {
  final String email;
  final String? password;
  const SelectCoursePage({super.key, required this.email, this.password});

  @override
  ConsumerState<SelectCoursePage> createState() => _SelectCoursePageState();
}

class _SelectCoursePageState extends ConsumerState<SelectCoursePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _gpaController = TextEditingController();
  
  // Department and Program data
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _levels = [];
  
  String? _selectedDepartmentId;
  String? _selectedProgramId;
  int? _selectedLevel;
  
  List<String> selectedCourseIds = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final List<Course> courses = [
    Course(id: 'CS101', code: 'CS101', name: 'Introduction to Computer Science', category: 'Computer Science', creditHours: 3),
    Course(id: 'CS102', code: 'CS102', name: 'Data Structures', category: 'Computer Science', creditHours: 3),
    Course(id: 'CS201', code: 'CS201', name: 'Algorithms', category: 'Computer Science', creditHours: 3),
    Course(id: 'CS301', code: 'CS301', name: 'Database Systems', category: 'Computer Science', creditHours: 3),
    Course(id: 'MATH101', code: 'MATH101', name: 'Calculus I', category: 'Mathematics', creditHours: 4),
    Course(id: 'MATH201', code: 'MATH201', name: 'Linear Algebra', category: 'Mathematics', creditHours: 3),
    Course(id: 'PHYS101', code: 'PHYS101', name: 'Physics I', category: 'Physics', creditHours: 3),
    Course(id: 'STAT101', code: 'STAT101', name: 'Statistics', category: 'Statistics', creditHours: 3),
  ];

  @override
  void initState() {
    super.initState();
    _loadDepartmentData();
  }

  Future<void> _loadDepartmentData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/mock/departments.json');
      final data = jsonDecode(jsonString);
      
      setState(() {
        _departments = List<Map<String, dynamic>>.from(data['departments']);
        _levels = List<Map<String, dynamic>>.from(data['levels']);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading departments: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onDepartmentChanged(String? departmentId) {
    setState(() {
      _selectedDepartmentId = departmentId;
      _selectedProgramId = null;
      
      // Update programs based on selected department
      if (departmentId != null) {
        final dept = _departments.firstWhere(
          (d) => d['id'] == departmentId,
          orElse: () => {'programs': []},
        );
        _programs = List<Map<String, dynamic>>.from(dept['programs'] ?? []);
      } else {
        _programs = [];
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  List<Course> _getFilteredCourses() {
    String query = _searchController.text.toLowerCase();
    return courses.where((course) {
      return course.code.toLowerCase().contains(query) ||
          course.name.toLowerCase().contains(query);
    }).toList();
  }

  void _toggleCourse(String id) {
    setState(() {
      if (selectedCourseIds.contains(id)) {
        selectedCourseIds.remove(id);
      } else {
        selectedCourseIds.add(id);
      }
    });
  }

  bool _validateForm() {
    if (_selectedDepartmentId == null) {
      _showError('Please select a department');
      return false;
    }
    if (_selectedProgramId == null) {
      _showError('Please select a program');
      return false;
    }
    if (_selectedLevel == null) {
      _showError('Please select your level');
      return false;
    }
    
    final gpaText = _gpaController.text.trim();
    if (gpaText.isNotEmpty) {
      final gpa = double.tryParse(gpaText);
      if (gpa == null || gpa < 0 || gpa > 4.0) {
        _showError('GPA must be between 0.0 and 4.0');
        return false;
      }
    }
    
    if (selectedCourseIds.isEmpty) {
      _showError('Please select at least one course');
      return false;
    }
    
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _finishSelection() async {
    if (!_validateForm()) return;
    
    setState(() => _isSaving = true);

    await StorageService.saveCourses(selectedCourseIds);

    // Get department and program names
    final deptName = _departments.firstWhere(
      (d) => d['id'] == _selectedDepartmentId,
      orElse: () => {'name': ''},
    )['name'];
    
    final programName = _programs.firstWhere(
      (p) => p['id'] == _selectedProgramId,
      orElse: () => {'name': ''},
    )['name'];

    // Update user with all profile data
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      final gpa = _gpaController.text.isNotEmpty 
          ? double.tryParse(_gpaController.text) 
          : null;
          
      final updatedUser = currentUser.copyWith(
        department: deptName,
        major: programName,
        level: _selectedLevel,
        gpa: gpa,
        enrolledCourses: selectedCourseIds,
        isOnboardingComplete: true,
      );
      await ref.read(appSessionControllerProvider.notifier).updateUser(updatedUser);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      // Logout so user must login again
      await ref.read(appSessionControllerProvider.notifier).logout();
      
      context.go('/login', extra: {
        'email': widget.email,
        'password': widget.password ?? '',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setup complete! Please login to continue.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCourses = _getFilteredCourses();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050816), Color(0xFF1a1f3a)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Complete Your Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white70),
                          onPressed: () async {
                            await ref.read(appSessionControllerProvider.notifier).logout();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome, ${widget.email}',
                      style: const TextStyle(color: Color(0xFFd1d5db)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Setup Section
                              const Text(
                                'Academic Information',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1a1f3a),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Department Dropdown
                              _buildDropdown(
                                label: 'Department',
                                value: _selectedDepartmentId,
                                items: _departments.map((d) => DropdownMenuItem<String>(
                                  value: d['id'],
                                  child: Text(d['name']),
                                )).toList(),
                                onChanged: _onDepartmentChanged,
                              ),
                              const SizedBox(height: 16),
                              
                              // Program Dropdown
                              _buildDropdown(
                                label: 'Program',
                                value: _selectedProgramId,
                                items: _programs.map((p) => DropdownMenuItem<String>(
                                  value: p['id'],
                                  child: Text(p['name']),
                                )).toList(),
                                onChanged: (value) => setState(() => _selectedProgramId = value),
                                enabled: _selectedDepartmentId != null,
                              ),
                              const SizedBox(height: 16),
                              
                              // Level Dropdown
                              _buildDropdown(
                                label: 'Level',
                                value: _selectedLevel,
                                items: _levels.map((l) => DropdownMenuItem<int>(
                                  value: l['id'],
                                  child: Text(l['name']),
                                )).toList(),
                                onChanged: (value) => setState(() => _selectedLevel = value),
                              ),
                              const SizedBox(height: 16),
                              
                              // GPA Input
                              TextFormField(
                                controller: _gpaController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'GPA (optional)',
                                  hintText: 'Enter your GPA (0.0 - 4.0)',
                                  filled: true,
                                  fillColor: const Color(0xFFf9fafb),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              const Divider(),
                              const SizedBox(height: 16),
                              
                              // Course Selection Section
                              const Text(
                                'Select Courses',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1a1f3a),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Selected: ${selectedCourseIds.length} courses',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              
                              // Search
                              TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Search courses...',
                                  prefixIcon: const Icon(Icons.search, color: Color(0xFF9ca3af)),
                                  filled: true,
                                  fillColor: const Color(0xFFf9fafb),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Course List
                              ...filteredCourses.map((course) => _buildCourseCard(course)),
                              
                              const SizedBox(height: 24),
                              
                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _finishSelection,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563eb),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text(
                                          'Complete Setup',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? const Color(0xFFf9fafb) : const Color(0xFFe5e7eb),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
        ),
      ),
      items: items,
      onChanged: enabled ? onChanged : null,
      hint: Text(enabled ? 'Select $label' : 'Select department first'),
    );
  }

  Widget _buildCourseCard(Course course) {
    final isSelected = selectedCourseIds.contains(course.id);
    
    return GestureDetector(
      onTap: () => _toggleCourse(course.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFeff6ff) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563eb) : const Color(0xFFe5e7eb),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF2563eb) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2563eb) : const Color(0xFFd1d5db),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1f2937),
                    ),
                  ),
                  Text(
                    course.name,
                    style: const TextStyle(color: Color(0xFF6b7280)),
                  ),
                ],
              ),
            ),
            Text(
              '${course.creditHours} hrs',
              style: const TextStyle(color: Color(0xFF9ca3af)),
            ),
          ],
        ),
      ),
    );
  }
}

class Course {
  final String id;
  final String code;
  final String name;
  final String category;
  final int creditHours;

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.creditHours,
  });
}
