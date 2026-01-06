import 'package:flutter/material.dart';

class DrCourseDetails extends StatelessWidget {
  const DrCourseDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'College Guide',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: const CreateContentScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ---- CONTENT TYPE ENUM ------------------------------------------------------

enum ContentType {
  assignment,
  exam,
  lectureMaterial,
  readingMaterial,
  announcement,
  project,
}

// ---- SCREEN -----------------------------------------------------------------

class CreateContentScreen extends StatefulWidget {
  const CreateContentScreen({Key? key}) : super(key: key);

  @override
  State<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends State<CreateContentScreen> {
  // content types + icons (for the chips)
  final Map<ContentType, String> _contentTypeLabels = {
    ContentType.assignment: 'Assignment',
    ContentType.exam: 'Exam',
    ContentType.lectureMaterial: 'Lecture Material',
    ContentType.readingMaterial: 'Reading Material',
    ContentType.announcement: 'Announcement',
    ContentType.project: 'Project',
  };

  final Map<ContentType, IconData> _contentTypeIcons = {
    ContentType.assignment: Icons.assignment_outlined,
    ContentType.exam: Icons.fact_check_outlined,
    ContentType.lectureMaterial: Icons.menu_book_outlined,
    ContentType.readingMaterial: Icons.chrome_reader_mode_outlined,
    ContentType.announcement: Icons.campaign_outlined,
    ContentType.project: Icons.folder_open_outlined,
  };

  ContentType _selectedType = ContentType.assignment;
  String _selectedCourse = 'MATH101 - Calculus I';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();

  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  // When true we show “Deadline & Grading” section .
  bool get _showDeadlineSection =>
      _selectedType == ContentType.assignment ||
      _selectedType == ContentType.exam;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
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
                        onPressed: () => Navigator.of(context).maybePop(),
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
                        _buildCourseSection(theme),
                        const SizedBox(height: 16),
                        _buildDetailsSection(theme),
                        const SizedBox(height: 16),

                        // show or hide Deadline depending on type
                        if (_showDeadlineSection) ...[
                          _buildDeadlineSection(theme),
                          const SizedBox(height: 16),
                        ],

                        _buildAttachmentSection(),
                        const SizedBox(height: 16),
                        _buildBottomButtons(theme),
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

  Widget _buildCourseSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _whiteCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.menu_book_outlined,
                size: 18,
                color: Color(0xFF26C2FF),
              ),
              SizedBox(width: 6),
              Text(
                'Course',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCourse,
            decoration: _roundedFieldDecoration.copyWith(
              hintText: 'Select course',
            ),
            items: [
              'MATH101 - Calculus I',
              'CS201 - Data Structures',
              'PHY110 - Physics I',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCourse = value);
              }
            },
          ),
        ],
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
        ? 'dd/mm/yyyy'
        : '${_dueDate!.day.toString().padLeft(2, '0')}/'
              '${_dueDate!.month.toString().padLeft(2, '0')}/'
              '${_dueDate!.year}';

    final timeText = _dueTime == null ? '--:--' : _dueTime!.format(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _yellowCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lock_clock, size: 18, color: Color(0xFFF6A400)),
              SizedBox(width: 6),
              Text(
                'Deadline & Grading',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDueDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _roundedFieldDecoration.copyWith(
                        labelText: 'Due Date',
                        hintText: dateText,
                        suffixIcon: const Icon(Icons.calendar_today_rounded),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _pickDueTime,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _roundedFieldDecoration.copyWith(
                        labelText: 'Due Time',
                        hintText: timeText,
                        suffixIcon: const Icon(Icons.access_time_filled),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
          DottedBorderBox(
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
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: const Color(0xFF7A6CF5),
            ),
            onPressed: () {},
            child: const Text(
              'Publish Content',
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
