import './edit_profile_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;
  const EditProfileScreen({Key? key, required this.token, required this.user}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _userNameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _schoolController;
  late TextEditingController _departmentController;
  late TextEditingController _yearController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController(text: widget.user['userName'] ?? '');
    _emailController = TextEditingController(text: widget.user['email'] ?? '');
    _bioController = TextEditingController(text: widget.user['bio'] ?? '');
    _schoolController = TextEditingController(text: widget.user['schoolName'] ?? '');
    _departmentController = TextEditingController(text: widget.user['department'] ?? '');
    _yearController = TextEditingController(text: widget.user['year']?.toString() ?? '');
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _schoolController.dispose();
    _departmentController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final profileData = {
      'bio': _bioController.text,
      'schoolName': _schoolController.text,
      'department': _departmentController.text,
      'year': int.tryParse(_yearController.text),
    };

    try {
      final api = ApiService();
      await api.updateProfile(widget.token, profileData);
      if (mounted) {
        Navigator.pop(context, true); // Başarıyla güncellendi
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil güncellenemedi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Profili Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6B7FD7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 12),
              _buildModernInput(
                controller: _bioController,
                label: 'Biyografi',
                icon: Icons.person_outline,
                maxLines: 2,
              ),
              const SizedBox(height: 18),
              _buildModernInput(
                controller: _schoolController,
                label: 'Okul',
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 18),
              _buildModernInput(
                controller: _departmentController,
                label: 'Bölüm',
                icon: Icons.apartment_outlined,
              ),
              const SizedBox(height: 18),
              _buildModernInput(
                controller: _yearController,
                label: 'Sınıf',
                icon: Icons.grade_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _isLoading ? 'Kaydediliyor...' : 'Kaydet',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7FD7),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFF6B7FD7).withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16, color: Color(0xFF222222)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF6B7FD7)),
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF6B7FD7), fontWeight: FontWeight.w600, fontSize: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}