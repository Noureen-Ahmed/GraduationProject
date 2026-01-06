import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_mode_provider.dart';
import '../providers/course_provider.dart';
import '../providers/announcement_provider.dart';
import '../providers/task_provider.dart';
import '../models/announcement.dart';
import '../models/task.dart';
import '../models/user.dart';

enum ContentType { lecture, assignment, exam }

class AddContentScreen extends ConsumerStatefulWidget {
  const AddContentScreen({super.key});

  @override
  ConsumerState<AddContentScreen> createState() => _AddContentScreenState();
}

class _AddContentScreenState extends ConsumerState<AddContentScreen> {
  ContentType? selectedType;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  DateTime? _deadline;
  String? _selectedCourseId;

  @override
  Widget build(BuildContext context) {
    final appMode = ref.watch(appModeControllerProvider);
    final coursesAsync = ref.watch(enrolledCoursesProvider);

    if (appMode != AppMode.professor) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Custom header
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.arrow_back, size: 24),
                    ),
                    const Text(
                      'Access Denied',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.lock,
                size: 80,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 16),
              const Text(
                'Only professors can add content',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF6B7280),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const Text(
                    'Add Content',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: selectedType == null
                  ? _buildContentTypeSelection()
                  : _buildContentForm(coursesAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeSelection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Content Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          
          // Content type cards
          Expanded(
            child: Column(
              children: [
                _ContentTypeCard(
                  type: ContentType.lecture,
                  title: 'Lecture',
                  description: 'Add lecture materials and content',
                  icon: Icons.menu_book,
                  color: const Color(0xFF10B981), // green-500
                  onTap: () => setState(() => selectedType = ContentType.lecture),
                ),
                const SizedBox(height: 16),
                _ContentTypeCard(
                  type: ContentType.assignment,
                  title: 'Assignment',
                  description: 'Create assignments with deadlines',
                  icon: Icons.assignment,
                  color: const Color(0xFF3B82F6), // blue-500
                  onTap: () => setState(() => selectedType = ContentType.assignment),
                ),
                const SizedBox(height: 16),
                _ContentTypeCard(
                  type: ContentType.exam,
                  title: 'Exam',
                  description: 'Schedule exams and assessments',
                  icon: Icons.quiz,
                  color: const Color(0xFFEF4444), // red-500
                  onTap: () => setState(() => selectedType = ContentType.exam),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentForm(AsyncValue coursesAsync) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course picker
            const Text(
              'Course',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            coursesAsync.when(
              data: (courses) {
                return DropdownButtonFormField<String>(
                  value: _selectedCourseId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  hint: const Text('Select a course'),
                  items: courses.map((course) {
                    return DropdownMenuItem(
                      value: course.id,
                      child: Text(course.name),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a course';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _selectedCourseId = value;
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading courses'),
            ),
            
            const SizedBox(height: 24),
            
            // Title field
            const Text(
              'Title',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                hintText: 'Enter title',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Description field
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                hintText: 'Enter description',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            
            // Conditional fields based on content type
            if (selectedType == ContentType.assignment || selectedType == ContentType.exam) ...[
              const SizedBox(height: 24),
              
              // Points field
              const Text(
                'Points',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  hintText: 'Enter points',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter points';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Deadline field
              const Text(
                'Deadline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDeadline(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20, color: Color(0xFF6B7280)),
                      const SizedBox(width: 12),
                      Text(
                        _deadline != null
                            ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                            : 'Select deadline',
                        style: TextStyle(
                          color: _deadline != null ? Colors.black : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
                    ],
                  ),
                ),
              ),
            ],
            
            // Attachment placeholder
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF9FAFB),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Click to upload attachments',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    'PDF, DOC, PPT up to 10MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Create Content',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _deadline = date;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course')),
      );
      return;
    }

    if ((selectedType == ContentType.assignment || selectedType == ContentType.exam) && _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a deadline')),
      );
      return;
    }

    try {
      if (selectedType == ContentType.lecture) {
        // Create announcement for lecture
        final announcement = Announcement(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          message: _descriptionController.text,
          date: DateTime.now(),
          type: AnnouncementType.general,
        );
        await ref.read(announcementControllerProvider.notifier).createAnnouncement(announcement);
      } else if (selectedType == ContentType.assignment) {
        // Create assignment task
        final task = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          subject: 'Course', // Would be populated from selected course
          dueDate: _deadline!,
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        );
        await ref.read(taskControllerProvider.notifier).createTask(task);
      } else if (selectedType == ContentType.exam) {
        // Create exam task
        final task = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          subject: 'Course', // Would be populated from selected course
          dueDate: _deadline!,
          priority: TaskPriority.high,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        );
        await ref.read(taskControllerProvider.notifier).createTask(task);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content created successfully')),
      );
      
      // Reset form and go back to selection
      setState(() {
        selectedType = null;
        _titleController.clear();
        _descriptionController.clear();
        _pointsController.clear();
        _deadline = null;
        _selectedCourseId = null;
      });
      
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating content: $error')),
      );
    }
  }
}

class _ContentTypeCard extends StatelessWidget {
  final ContentType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ContentTypeCard({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}