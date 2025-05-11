import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import './chat_screen.dart';
import './add_note_screen.dart';
import './note_search_delegate.dart';
import './note_detail_screen.dart';
import './profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentSearchTerm;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  final _apiService = ApiService();
  final _tokenService = TokenService();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes({String? searchTerm}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentSearchTerm = searchTerm;
      if (searchTerm != null || _notes.isEmpty) {
        _notes.clear();
      }
    });

    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.');
      }
      // searchTerm null değilse arama yapar ve ugyun notları yükler null ise tüm notları yükler
      List<Note> fetchedNotes;
      if (searchTerm != null && searchTerm.isNotEmpty) {
        print('Aranıyor: "$searchTerm"');
        fetchedNotes = await _apiService.searchNotes(token, searchTerm);
      } else {
        print('Tüm notlar yükleniyor');
        fetchedNotes = await _apiService.getNotes(token);
      }

      if (mounted) {
        setState(() {
          _notes = fetchedNotes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Notlar yüklenirken hata oluştu: $e';
          _notes = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // ekranı yenileme işlemi için kullanılan fonksiyon
  Future<void> _handleRefresh() async {
    await _loadNotes();
  }

 // ekranın nasıl görüneceğini belirleyen widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // uygulamanın üst kısmında bulunan çubuk
      // Arama butonu ve bildirim butonunu içerir
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: _currentSearchTerm != null && _currentSearchTerm!.isNotEmpty
        // Arama ekranında geri butonu gösterir
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7FD7)),
              onPressed: () => _loadNotes(),
            )
          : null,
          // uygulamanın başlığı
        title: Text(
          _currentSearchTerm != null && _currentSearchTerm!.isNotEmpty
              ? 'ARAMA SONUÇLARI'
              : 'NOTLARIM',
          style: GoogleFonts.poppins(
            color: const Color(0xFF6B7FD7),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          // Arama butonu, tıklandığında notları  arama ekranını açar
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF6B7FD7)),
            tooltip: 'Not Ara',
            onPressed: () async {
              final String? selectedTerm = await showSearch<String?>(
                context: context,
                delegate: NoteSearchDelegate(apiService: _apiService, tokenService: _tokenService),
                query: _currentSearchTerm,
              );

              final termToLoad = selectedTerm?.trim().isEmpty ?? true ? null : selectedTerm;
              if (termToLoad != _currentSearchTerm) {
                _loadNotes(searchTerm: termToLoad);
              }
            },
          ),
          // Bildirim butonu, tıklandığında bildirim ekranını açar
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF6B7FD7)),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      // Ekranın gövdesi, notları listeleyen bir widget içerir
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _handleRefresh,
        color: const Color(0xFF6B7FD7),
        child: _buildBody(),
      ),
      // Yeni not eklemek için kullanılan buton
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddNoteScreen()),
          );

          if (result == true) {
            _loadNotes();
          }
        },
        backgroundColor: const Color(0xFF6B7FD7),
        child: const Icon(Icons.add_rounded),
      ),
      // alt navigasyon çubuğu, tıklandığında ilgili ekranı açar
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
          if (index == 1) {
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
  // Notlar ekranının gövdesini oluşturan widget
  // Notlar yüklendiğinde, hata oluştuğunda veya not yoksa uygun mesajları gösterir
  Widget _buildBody() {
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
              Icon(Icons.error_outline, color: Colors.red, size: 60),
              SizedBox(height: 16),
              Text('Hata Oluştu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text('Tekrar Dene'),
                onPressed: () => _loadNotes(searchTerm: _currentSearchTerm),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6B7FD7), foregroundColor: Colors.white),
              )
            ],
          ),
        ),
      );
    }

    if (_notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _currentSearchTerm != null && _currentSearchTerm!.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.note_alt_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _currentSearchTerm != null && _currentSearchTerm!.isNotEmpty
                ? 'Arama Sonucu Bulunamadı'
                : 'Henüz Not Eklenmemiş',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentSearchTerm != null && _currentSearchTerm!.isNotEmpty
                ? 'Farklı bir terimle aramayı deneyin.'
                : 'Yeni bir not eklemek için + butonuna basın',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (_currentSearchTerm != null && _currentSearchTerm!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.clear_all),
                  label: Text('Tüm Notları Göster'),
                  onPressed: () => _loadNotes(),
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6B7FD7), foregroundColor: Colors.white),
                ),
              ),
          ],
        ),
      );
    }
    // Notlar yüklendiğinde, notları listeleyen bir widget döner
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: NoteCard(note: note, searchTerm: _currentSearchTerm),
        );
      },
    );
  }
}

// Not kartını oluşturan widget
class NoteCard extends StatelessWidget {
  final Note note;
  final String? searchTerm;

  const NoteCard({
    super.key,
    required this.note,
    this.searchTerm,
  });
  // notun oluşturulma zamanı
  String _getTimeAgo() {
    final now = DateTime.now();
    if (note.createdAt == null) return '?';
    final difference = now.difference(note.createdAt!);

    if (difference.inMinutes < 1) {
      return 'şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} sa önce';
    } else {
      return '${difference.inDays} gün önce';
    }
  }
 // Not kartının içeriğini oluşturan widget
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        // not kartına tıklandığında detay ekranına yönlendirir
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(
                note: note,
                searchTerm: searchTerm,
              ),
            ),
          );

          // Eğer geri dönüş değeri bir arama terimi ise, o terimle aramayı yenile
          if (result != null && result is String) {
            if (context.mounted) {
              final homeState = context.findAncestorStateOfType<_HomeScreenState>();
              if (homeState != null) {
                homeState._loadNotes(searchTerm: result);
              }
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                note.title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF6B7FD7),
                      child: Text(
                        note.ownerUsername.isNotEmpty ? note.ownerUsername[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      note.ownerUsername.isNotEmpty ? note.ownerUsername : 'Bilinmeyen',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    Text(
                      _getTimeAgo(),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (note.category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B7FD7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          note.category,
                          style: const TextStyle(
                            color: Color(0xFF6B7FD7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (note.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  note.content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (note.pdfFilePath != null && note.pdfFilePath!.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Color(0xFF6B7FD7)),
                  title: Text('PDF Dosyası (${note.page} sayfa)'),
                  trailing: IconButton(
                    icon: const Icon(Icons.download_rounded, color: Color(0xFF6B7FD7)),
                    onPressed: () {
                      print('Download tıklandı: ${note.pdfFilePath}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('İndirme işlevi henüz eklenmedi.'))
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 