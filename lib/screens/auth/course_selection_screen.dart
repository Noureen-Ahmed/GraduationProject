import 'package:flutter/material.dart';
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
  String selectedYear = '';
  String selectedDepartment = 'All';
  List<String> selectedCourseIds = [];

  final List<String> departments = [
    'All',
    'Computer Science',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology'
  ];

  final List<Course> courses = [
    Course(
      id: 'CS101',
      code: 'CS101',
      name: 'Introduction to Computer Science',
      category: 'Computer Science',
      creditHours: 3,
    ),
    Course(
      id: 'CS102',
      code: 'CS102',
      name: 'Data Structures',
      category: 'Computer Science',
      creditHours: 3,
    ),
    Course(
      id: 'MATH101',
      code: 'MATH101',
      name: 'Calculus I',
      category: 'Mathematics',
      creditHours: 4,
    ),
    Course(
      id: 'PHYS101',
      code: 'PHYS101',
      name: 'Physics I',
      category: 'Physics',
      creditHours: 3,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Course> _getFilteredCourses() {
    String query = _searchController.text.toLowerCase();
    return courses.where((course) {
      final matchesSearch = course.code.toLowerCase().contains(query) ||
          course.name.toLowerCase().contains(query);
      final matchesYear =
          selectedYear.isEmpty || course.code.contains(selectedYear);
      final matchesDept =
          selectedDepartment == 'All' || course.category == selectedDepartment;
      return matchesSearch && matchesYear && matchesDept;
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

  Future<void> _finishSelection() async {
    if (selectedCourseIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one course'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await StorageService.saveCourses(selectedCourseIds);

    // Update real repository state
 final currentUser = ref.read(currentUserProvider).value;
  if (currentUser != null) {
    final updatedUser = currentUser.copyWith(
      enrolledCourses: selectedCourseIds,
      isOnboardingComplete: true,
    );
    await ref.read(appSessionControllerProvider.notifier).updateUser(updatedUser);
    }

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
                          'Select Your Courses',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
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
                    const Text(
                      'Choose courses to build your schedule',
                      style: TextStyle(color: Color(0xFFd1d5db)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search courses...',
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF9ca3af)),
                          filled: true,
                          fillColor: const Color(0xFFf9fafb),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedYear.isEmpty ? null : selectedYear,
                              hint: const Text('All Years'),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFf9fafb),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: ['1', '2', '3', '4']
                                  .map((y) => DropdownMenuItem(
                                        value: y,
                                        child: Text('Year $y'),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => selectedYear = v ?? ''),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedDepartment,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFf9fafb),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: departments
                                  .map((d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(d),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(
                                  () => selectedDepartment = v ?? 'All'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: filteredCourses.isEmpty
                            ? const Center(child: Text('No courses found'))
                            : ListView.builder(
                                itemCount: filteredCourses.length,
                                itemBuilder: (context, index) {
                                  final course = filteredCourses[index];
                                  final selected =
                                      selectedCourseIds.contains(course.id);

                                  return GestureDetector(
                                    onTap: () => _toggleCourse(course.id),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xFFeff6ff)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected
                                              ? const Color(0xFF2563eb)
                                              : const Color(0xFFe5e7eb),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? const Color(0xFF2563eb)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: selected
                                                    ? const Color(0xFF2563eb)
                                                    : const Color(0xFFd1d5db),
                                              ),
                                            ),
                                            child: selected
                                                ? const Icon(Icons.check,
                                                    color: Colors.white,
                                                    size: 16)
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  course.code,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: selected
                                                        ? const Color(
                                                            0xFF2563eb)
                                                        : Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(course.name),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${course.category} - ${course.creditHours} credits',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF6b7280),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _finishSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563eb),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Continue (${selectedCourseIds.length} selected)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
