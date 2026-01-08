import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'package:intl/intl.dart';

  @override
  Widget build(BuildContext context) {
    return CreateContentScreen(courseId: courseId);
  }


// ---- CONTENT TYPE ENUM ------------------------------------------------------

enum ContentType {
  assignment,
  exam,
  lectureMaterial,
  announcement,
}

enum ExamType {
  online,
  offline,
}

// ---- SCREEN -----------------------------------------------------------------

class CreateContentScreen extends ConsumerStatefulWidget {
  final String courseId;
  const CreateContentScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  ConsumerState<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends ConsumerState<CreateContentScreen> {
  // content types + icons (for the chips)
  final Map<ContentType, String> _contentTypeLabels = {
    ContentType.assignment: 'Assignment',
    ContentType.exam: 'Exam',
    ContentType.lectureMaterial: 'Lecture Material',
    ContentType.announcement: 'Announcement',
  };

  final Map<ContentType, IconData> _contentTypeIcons = {
    ContentType.assignment: Icons.assignment_outlined,
    ContentType.exam: Icons.fact_check_outlined,
    ContentType.lectureMaterial: Icons.menu_book_outlined,
    ContentType.announcement: Icons.campaign_outlined,
  };

  ContentType _selectedType = ContentType.assignment;
  ExamType _selectedExamType = ExamType.online;

  // Mock busy dates for testing
  final Map<DateTime, String> _busyDates = {
    DateTime(2026, 1, 13): '4 students have an exam in this day',
    DateTime(2026, 1, 10): '50 students have an assignment in this day',
  };

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();

  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String? _selectedFileName;

  // When true we show “Deadline & Grading” section .
  bool get _showDeadlineSection =>
      _selectedType == ContentType.assignment ||
      _selectedType == ContentType.exam;

  bool get _isExam => _selectedType == ContentType.exam;
  bool get _isOnlineExam => _isExam && _selectedExamType == ExamType.online;
  bool get _isAssignment => _selectedType == ContentType.assignment;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    DateTime tempDate = _dueDate ?? DateTime.now();
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final busyNote = _busyDates[DateTime(tempDate.year, tempDate.month, tempDate.day)];
          
          return AlertDialog(
            title: const Text('Select Date', style: TextStyle(color: Color(0xFF1D2B64))),
            content: SizedBox(
              width: 350,
              height: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TableCalendar(
                    firstDay: DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 365 * 5)),
                    focusedDay: tempDate,
                    selectedDayPredicate: (day) => isSameDay(tempDate, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setDialogState(() {
                        tempDate = selectedDay;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF7A6CF5),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF7A6CF5).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        for (var busyDate in _busyDates.keys) {
                          if (isSameDay(day, busyDate)) {
                            return Container(
                              margin: const EdgeInsets.all(4.0),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }
                        }
                        return null;
                      },
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                  ),
                  const Spacer(),
                  if (busyNote != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 20, color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              busyNote,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _dueDate = tempDate;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A6CF5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.name.isNotEmpty) {
        setState(() {
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            //just for coloring
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7A6CF5), // top purple
              Color(0xFF1D2B64), // bottom blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar -------------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Container(
                      //Back button
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/courses');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      //The top 2 texts (Create content, ...)
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Content',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Share knowledge with your students',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Card body -----------------------------------------------------
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F6FF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                       children: [
                        _buildContentTypeSection(),
                        const SizedBox(height: 16),
                        if (_isExam) ...[
                          _buildExamTypeSection(),
                          const SizedBox(height: 16),
                        ],
                        _buildDetailsSection(theme),
                        const SizedBox(height: 16),

                        // show or hide Deadline depending on type
                        if (_showDeadlineSection) ...[
                          _buildDeadlineSection(theme),
                          const SizedBox(height: 16),
                        ],

                        if ((!_isExam && _selectedType != ContentType.announcement) || _isOnlineExam) ...[
                          _buildAttachmentSection(),
                          const SizedBox(height: 16),
                        ],
                        _buildBottomButtons(theme),
                        const SizedBox(height: 120), // Significant padding at the bottom for better visibility
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

  // ---------- SECTIONS -------------------------------------------------------

  Widget _buildContentTypeSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration:
          _whiteCardDecoration, //just because this same decoration will be used a lot.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Content Type',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _contentTypeLabels.entries.map((entry) {
              final type = entry.key;
              final label = entry.value;
              final bool selected = type == _selectedType;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedType = type;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFE7E5FF)
                        : const Color(0xFFF5F6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF7A6CF5)
                          : Colors.grey.shade300,
                      width: selected ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _contentTypeIcons[type],
                        size: 18,
                        color: selected
                            ? const Color(0xFF7A6CF5)
                            : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: selected ? Colors.black : Colors.black87,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExamTypeSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _whiteCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Exam Type',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTypeChip(
                'Online',
                Icons.computer,
                _selectedExamType == ExamType.online,
                () => setState(() => _selectedExamType = ExamType.online),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                'Offline',
                Icons.location_on_outlined,
                _selectedExamType == ExamType.offline,
                () => setState(() => _selectedExamType = ExamType.offline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE7E5FF) : const Color(0xFFF5F6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF7A6CF5) : Colors.grey.shade300,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? const Color(0xFF7A6CF5) : Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.black87,
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _whiteCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.description_outlined,
                size: 18,
                color: Color(0xFF26C2FF),
              ),
              SizedBox(width: 6),
              Text(
                'Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            decoration: _roundedFieldDecoration.copyWith(
              labelText: 'Title *',
              hintText: 'e.g., Week 5 Assignment - Data Structures',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: _roundedFieldDecoration.copyWith(
              labelText: 'Description',
              hintText: 'Provide detailed instructions or information...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineSection(ThemeData theme) {
    final dateText = _dueDate == null
        ? 'Insert Date'
        : '${_dueDate!.day.toString().padLeft(2, '0')}/'
              '${_dueDate!.month.toString().padLeft(2, '0')}/'
              '${_dueDate!.year}';

    final busyInfo = _dueDate != null ? _busyDates[_dueDate] : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _yellowCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.calendar_month, size: 18, color: Color(0xFFF6A400)),
              SizedBox(width: 6),
              Text(
                'Scheduling',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _pickDueDate(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Color(0xFF7A6CF5)),
                    const SizedBox(width: 12),
                    Text(
                      dateText,
                      style: TextStyle(
                        color: _dueDate == null ? Colors.grey.shade600 : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          
          // Display conflict note if selected date is busy
          if (busyInfo != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      busyInfo,
                      style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          if (_isOnlineExam) ...[
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _pickDueTime(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 20, color: Color(0xFF7A6CF5)),
                            const SizedBox(width: 12),
                            Text(
                              _dueTime == null ? 'Start Time' : _dueTime!.format(context),
                              style: TextStyle(
                                color: _dueTime == null ? Colors.grey.shade600 : Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: _roundedFieldDecoration.copyWith(
                      labelText: 'Duration (Min)',
                      hintText: 'e.g., 60',
                      prefixIcon: const Icon(Icons.timer_outlined, color: Color(0xFF7A6CF5), size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (_isAssignment) ...[
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _pickStartTime(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.start, size: 20, color: Color(0xFF7A6CF5)),
                            const SizedBox(width: 12),
                            Text(
                              _startTime == null ? 'Start Time' : _startTime!.format(context),
                              style: TextStyle(
                                color: _startTime == null ? Colors.grey.shade600 : Colors.black,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _pickEndTime(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_busy, size: 20, color: Color(0xFF7A6CF5)),
                            const SizedBox(width: 12),
                            Text(
                              _endTime == null ? 'End Time' : _endTime!.format(context),
                              style: TextStyle(
                                color: _endTime == null ? Colors.grey.shade600 : Colors.black,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _pickDueTime(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20, color: Color(0xFF7A6CF5)),
                      const SizedBox(width: 12),
                      Text(
                        _dueTime == null ? 'Time' : _dueTime!.format(context),
                        style: TextStyle(
                          color: _dueTime == null ? Colors.grey.shade600 : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            decoration: _roundedFieldDecoration.copyWith(
              labelText: 'Total Points',
              hintText: 'e.g., 100',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _whiteCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.attach_file, size: 18, color: Color(0xFF26C2FF)),
              SizedBox(width: 6),
              Text(
                'Attachments',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedFileName != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7A6CF5).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Color(0xFF7A6CF5)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedFileName!,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.red),
                    onPressed: _removeFile,
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: _pickFile,
              behavior: HitTestBehavior.opaque,
              child: DottedBorderBox(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 34,
                      color: Color(0xFF7A6CF5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Click to upload or drag and drop',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'PDF, DOC, DOCX, PPT, PPTX (max 10MB)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              foregroundColor: Colors.black87,
            ),
            onPressed: () {
              Navigator.of(context).maybePop();
            },
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
           child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A6CF5),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (_titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a title')),
                );
                return;
              }

              final String id = DateTime.now().millisecondsSinceEpoch.toString();
              final String typeLabel = _contentTypeLabels[_selectedType] ?? 'Content';
              
              final newTask = Task(
                id: id,
                title: '${_titleController.text} ($typeLabel)',
                subject: widget.courseId,
                dueDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                status: TaskStatus.pending,
                priority: TaskPriority.medium,
                description: _descriptionController.text,
                createdAt: DateTime.now(),
              );

              try {
                await ref.read(taskControllerProvider.notifier).createTask(newTask);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully added to your Notes!')),
                  );
                  context.pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text(
              'Send',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- STYLES & SMALL WIDGETS -------------------------------------------

const BoxDecoration _whiteCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  boxShadow: [
    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
  ],
);

const BoxDecoration _yellowCardDecoration = BoxDecoration(
  color: Color(0xFFFFF1C7),
  borderRadius: BorderRadius.all(Radius.circular(16)),
  boxShadow: [
    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
  ],
);

const InputDecoration _roundedFieldDecoration = InputDecoration(
  filled: true,
  fillColor: Color(0xFFF7F8FF),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
    borderSide: BorderSide.none,
  ),
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
);

class DottedBorderBox extends StatelessWidget {
  final Widget child;

  const DottedBorderBox({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // simple "fake dotted" border
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blue.withOpacity(0.4), width: 1.5),
      ),
      child: Center(child: child),
    );
  }
}
