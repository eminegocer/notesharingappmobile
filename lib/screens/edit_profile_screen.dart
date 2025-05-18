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
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Biyografi'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _schoolController,
                decoration: const InputDecoration(labelText: 'Okul'),
              ),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: 'Bölüm'),
              ),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Sınıf'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                icon: const Icon(Icons.save),
                label: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}