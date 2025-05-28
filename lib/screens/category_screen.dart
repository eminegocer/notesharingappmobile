import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import 'home_screen.dart';
import '../models/user.dart';
import '../models/note.dart';
import '../widgets/recently_visited_notes_section.dart';
import '../widgets/recently_visited_notes_section.dart' show TopDownloadedNotesSection;
import '../widgets/test_banner.dart';
import '../screens/chat_screen.dart';
import '../screens/profile_screen.dart';
import 'test_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();
  bool _isLoading = true;
  List<String> _categories = [];
  String? _errorMessage;
  List<VisitedNote> _visitedNotes = [];
  List<Note> _topDownloadedNotes = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadVisitedNotes();
    _loadTopDownloadedNotes();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Oturum bilgisi bulunamadı');
      }

      final categories = await _apiService.getCategories(token);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kategoriler yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVisitedNotes() async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) return;
      final notes = await _apiService.getVisitedNotes(token);
      setState(() {
        _visitedNotes = notes.take(4).toList();
      });
    } catch (e) {
      // ignore error for now
    }
  }

  Future<void> _loadTopDownloadedNotes() async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) return;
      final notes = await _apiService.getTopDownloadedNotes(token);
      setState(() {
        _topDownloadedNotes = notes.take(4).toList();
      });
    } catch (e) {
      // ignore error for now
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
          'KATEGORİLER',
          style: GoogleFonts.poppins(
            color: const Color(0xFF6B7FD7),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          TestBanner(
            onStartTest: () async {
              final rootContext = context;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Test Hakkında', style: TextStyle(color: Color(0xFF3A7BD5), fontWeight: FontWeight.bold)),
                    content: const Text(
                      'Bu test, sana en uygun notları bulmana yardımcı olacak. 10 soruluk bir test çözeceksin.',
                      style: TextStyle(fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Vazgeç'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3A7BD5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final token = await _tokenService.getToken();
                          if (token == null) {
                            Future.delayed(Duration.zero, () {
                              ScaffoldMessenger.of(rootContext).showSnackBar(
                                const SnackBar(content: Text('Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.')),
                              );
                            });
                            return;
                          }
                          try {
                            final questions = await _apiService.generateTestQuestions(token);
                            if (!mounted) return;
                            Navigator.push(
                              rootContext,
                              MaterialPageRoute(
                                builder: (context) => TestScreen(questions: questions, token: token),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            Future.delayed(Duration.zero, () {
                              ScaffoldMessenger.of(rootContext).showSnackBar(
                                SnackBar(content: Text('Test soruları alınamadı: $e')),
                              );
                            });
                          }
                        },
                        child: const Text('Teste Başla'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildCategoryGrid(),
          ),
          RecentlyVisitedNotesSection(
            notes: _visitedNotes,
            onRefresh: _loadVisitedNotes,
          ),
          TopDownloadedNotesSection(notes: _topDownloadedNotes),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF6B7FD7),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Sohbet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profil',
          ),
        ],
        onTap: (index) async {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          } else if (index == 2) {
            final token = await _tokenService.getToken();
            if (token != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(token: token),
                ),
              );
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.')),
                );
              }
            }
          }
        },
      ),
    );
  }

  Widget _buildCategoryGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7FD7)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text('Hata Oluştu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                onPressed: _loadCategories,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7FD7),
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz Kategori Yok',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kategoriler eklendiğinde burada görünecek',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(String category) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(selectedCategory: category),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                Color(0xFF6B7FD7),
                Color(0xFF86A8E7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                size: 28,
                color: Colors.white,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('matematik')) {
      return Icons.calculate;
    } else if (lowerCategory.contains('fizik')) {
      return Icons.science;
    } else if (lowerCategory.contains('kimya')) {
      return Icons.science;
    } else if (lowerCategory.contains('biyoloji')) {
      return Icons.biotech;
    } else if (lowerCategory.contains('tarih')) {
      return Icons.history;
    } else if (lowerCategory.contains('coğrafya')) {
      return Icons.public;
    } else if (lowerCategory.contains('edebiyat')) {
      return Icons.menu_book;
    } else if (lowerCategory.contains('ingilizce')) {
      return Icons.language;
    } else if (lowerCategory.contains('programlama')) {
      return Icons.code;
    } else {
      return Icons.category;
    }
  }
} 