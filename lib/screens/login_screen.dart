import 'package:flutter/material.dart';
import '../services/api_service.dart'; // API işlemlerini yöneten servis
import '../services/token_service.dart'; // Token işlemleri için servis
import '../config/api_config.dart'; // API ayarları (muhtemelen URL gibi)
import 'package:google_fonts/google_fonts.dart'; // Özel fontlar için paket
import './home_screen.dart'; // Giriş başarılı olunca yönlendireceğimiz ekran
import './category_screen.dart'; // Kategori ekranına yönlendireceğimiz ekran
import './register_screen.dart'; // Kayıt ekranına yönlendireceğimiz ekran

// Login ekranını temsil eden ekranın durumu değişebileceği için StatefulWidget 
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});


  // Login ekranının dinamik davranışları bu sınıf içinde yönetilecek.
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // Form doğrulama için anahtar
  final _formKey = GlobalKey<FormState>();

  // TextField içerisinde kullanıcıların yazdıklarını tutar
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // API'ye istek atıldığında butonu pasif yapar (çift tıklanmasın diye).
  bool _isLoading = false;
  // Şifrenin görünürlüğünü kontrol eden değişken
  bool _isPasswordVisible = false;

  // Sayfa ilk açıldığında logo ve kutular yavaşça aşağıdan yukarıya ve şeffaf bir şekilde ortaya çıkıyor.
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Token ve API işlemleri için servisler
  final _tokenService = TokenService();
  final _apiService = ApiService();

  // Hata mesajı için değişken
  String? _errorMessage;

  // ekran açılınca çalışan ilk fonksiyon
  @override
  void initState() {
    super.initState();

    // Animasyon kontrolcüsünü başlat
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Saydamlık animasyonu (fade in-out)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Kaydırmalı giriş animasyonu
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), // Aşağıdan yarım ekran kadar yukarı kayacak
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    // Animasyonu başlat
    _animationController.forward();
  }

  @override
  void dispose() {
    // Kullanılmayan controllerları yok et
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Giriş işlemlerini yöneten metod
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Login işlemi başlatılıyor...');
      print('Kullanıcı adı: ${_usernameController.text}, Email: ${_emailController.text}');

      // API'ye login isteği gönder
      final response = await _apiService.login(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );

      print('Login yanıtı alındı: $response');

      if (response['success'] == true) {
        // Giriş başarılıysa userId ve token kaydediliyor
        if (response['userId'] != null) {
          await _tokenService.saveUserId(response['userId']['timestamp'].toString());
        }

        if (response['token'] != null) {
          await _tokenService.saveToken(response['token']);
        }

        // Başarılı giriş sonrası kategori ekranına yönlendirme
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const CategoryScreen()),
            (route) => false, // Önceki ekranları temizle
          );
        }
      } else {
        // Başarısız giriş durumunda hata mesajı göster
        setState(() {
          _errorMessage = response['message'] ?? 'Giriş yapılamadı';
        });
      }
    } catch (e) {
      print('Login hatası: $e');
      setState(() {
        _errorMessage = 'Giriş yaparken hata oluştu: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  // Giriş ekranının görsel tasarımını oluşturan metod
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Arka plan için degrade (gradient) renk
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6B7FD7),
              const Color(0xFF86A8E7),
              Colors.blue.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO ve Başlık - Animasyonlu
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 80,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                Positioned(
                                  right: -10,
                                  bottom: -10,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.edit_note_rounded,
                                      size: 24,
                                      color: Color(0xFF6B7FD7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'NOTLARIM',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Öğrenci Dostu Not Paylaşım Platformu',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // GİRİŞ FORMU
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Hoş Geldiniz!',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF6B7FD7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Kullanıcı Adı Alanı
                              TextFormField(
                                controller: _usernameController,
                                decoration: _inputDecoration('Kullanıcı Adı', Icons.person_outline_rounded),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Kullanıcı adı zorunludur';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Email Alanı
                              TextFormField(
                                controller: _emailController,
                                decoration: _inputDecoration('E-posta Adresi', Icons.email_outlined),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'E-posta adresi zorunludur';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Geçerli bir e-posta adresi giriniz';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Şifre Alanı
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: _passwordInputDecoration(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Şifre boş bırakılamaz';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Giriş Yap Butonu
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6B7FD7),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Giriş Yap',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),

                              // Kayıt Ol Butonu
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                  );
                                },
                                child: Text(
                                  'Hesabınız yok mu? Hemen Kayıt Olun',
                                  style: TextStyle(
                                    color: const Color(0xFF6B7FD7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Hata Mesajı Alanı
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Tekrar eden input dekorasyonlarını düzenlemek için yardımcı metod
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF6B7FD7).withOpacity(0.7)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6B7FD7), width: 2.0),
      ),
    );
  }

  // Şifre giriş alanı için özel input dekorasyon
  InputDecoration _passwordInputDecoration() {
    return _inputDecoration('Şifre', Icons.lock_outline_rounded).copyWith(
      suffixIcon: IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          color: const Color(0xFF6B7FD7).withOpacity(0.7),
        ),
        onPressed: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
      ),
    );
  }
}
