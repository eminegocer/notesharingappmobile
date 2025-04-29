import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _pageController = TextEditingController();
  final _apiService = ApiService();
  final _tokenService = TokenService();
  
  String? _selectedCategory;
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _categories = [];
  bool _isCategoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isCategoriesLoading = true;
      _errorMessage = null;
    });

    try {
      print('Kategoriler yükleniyor...');
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Token bulunamadı. Lütfen tekrar giriş yapın.');
      }

      print('Token alındı, kategoriler getiriliyor...');
      final categories = await _apiService.getNoteCategories(token);
      print('Kategoriler başarıyla alındı: ${categories.length} adet');

      if (mounted) {
        setState(() {
          _categories = categories;
          _isCategoriesLoading = false;
        });
      }
    } catch (e) {
      print('Kategoriler yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Kategoriler yüklenirken hata oluştu: $e';
          _isCategoriesLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      print('Dosya seçme işlemi başladı');
      
      // Mevcut seçiciyi temizle
      await FilePicker.platform.clearTemporaryFiles();
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true, // Dosya verilerini direkt alalım
      );

      print('Dosya seçici sonucu: ${result != null ? "Başarılı" : "İptal edildi"}');

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
        print('Seçilen dosya: ${_selectedFile?.name}, Boyut: ${_selectedFile?.size} bytes');
      }
    } catch (e) {
      print('Dosya seçme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya seçilirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedFile != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Token al
        final token = await _tokenService.getToken();
        if (token == null || token.isEmpty) {
          throw Exception('Token bulunamadı. Lütfen tekrar giriş yapın.');
        }

        print('Not gönderiliyor...');
        print('Dosya: ${_selectedFile!.name} (${_selectedFile!.bytes!.length} bytes)');
        
        // Not verilerini hazırla
        final noteData = {
          'title': _titleController.text,
          'content': _contentController.text,
          'category': _selectedCategory,
          'page': int.tryParse(_pageController.text) ?? 0,
        };
        
        // API isteği gönder
        final response = await _apiService.createNoteWithFile(
          token,
          noteData,
          _selectedFile!.bytes!,
          _selectedFile!.name,
        );
        
        print('API yanıtı: $response');
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Başarılı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Not başarıyla eklendi'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Önceki sayfaya dön ve güncelleme yap
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        print('Hata: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Not eklenirken bir hata oluştu: $e';
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Not eklenirken bir hata oluştu: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else if (_selectedFile == null) {
      setState(() {
        _errorMessage = 'Lütfen bir PDF dosyası seçin.';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir PDF dosyası seçin.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'YENİ NOT EKLE',
          style: GoogleFonts.poppins(
            color: const Color(0xFF6B7FD7),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7FD7)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7FD7)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Başlık
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Not Başlığı',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen bir başlık girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // İçerik
                    TextFormField(
                      controller: _contentController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Not İçeriği',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen not içeriğini girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Kategori
                    _isCategoriesLoading
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Kategori',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen bir kategori seçin';
                            }
                            return null;
                          },
                        ),
                    const SizedBox(height: 16),
                    
                    // Sayfa Sayısı
                    TextFormField(
                      controller: _pageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Sayfa Sayısı',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen sayfa sayısını girin';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Geçerli bir sayı girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // PDF Dosyası Seçme
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_selectedFile != null 
                        ? 'Seçilen Dosya: ${_selectedFile!.name}'
                        : 'PDF Dosyası Seç'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7FD7),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Kaydet Butonu
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7FD7),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'NOTU KAYDET',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 