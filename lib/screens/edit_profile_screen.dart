import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_session_provider.dart';
import '../providers/app_mode_provider.dart';
import '../models/user.dart';
import '../widgets/user_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _levelController;
  late TextEditingController _deptController;
  late TextEditingController _gpaController;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value;
    _nameController = TextEditingController(text: user?.name ?? '');
    _levelController = TextEditingController(text: user?.level?.toString() ?? '');
    _deptController = TextEditingController(text: user?.department ?? '');
    _gpaController = TextEditingController(text: user?.gpa?.toString() ?? '');
    _avatarUrl = user?.avatar;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _levelController.dispose();
    _deptController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // 5MB Size Limit Check
        final bytes = await image.length();
        const maxSizeBytes = 5 * 1024 * 1024;
        
        if (bytes > maxSizeBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size exceeds 5MB limit. Please choose a smaller image.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _avatarUrl = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      name: _nameController.text,
      level: int.tryParse(_levelController.text),
      department: _deptController.text,
      gpa: double.tryParse(_gpaController.text),
      avatar: _avatarUrl ?? currentUser.avatar,
    );

    final result = await ref.read(appSessionControllerProvider.notifier).updateUser(updatedUser);

    if (mounted) {
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF002147);
    const goldColor = Color(0xFFFDC800);
    const bgColor = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: navyColor, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: navyColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: navyColor)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: navyColor.withValues(alpha: 0.1), width: 4),
                      ),
                      child: UserAvatar(
                        avatarUrl: _avatarUrl ?? '',
                        name: _nameController.text,
                        size: 100,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _changePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: navyColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt, color: goldColor, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildTextField(
                controller: _nameController,
                label: 'Display Name',
                icon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _deptController,
                label: 'Department',
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _levelController,
                      label: 'Level',
                      icon: Icons.grid_view,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _gpaController,
                      label: 'GPA',
                      icon: Icons.star_border,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    const navyColor = Color(0xFF002147);
    const goldColor = Color(0xFFFDC800);
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      style: const TextStyle(color: navyColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: navyColor.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: goldColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: navyColor.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: navyColor.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: navyColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
