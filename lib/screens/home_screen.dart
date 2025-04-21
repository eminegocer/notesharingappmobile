import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import './chat_screen.dart';
import './add_note_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Note> _notes = [];
  bool _isLoading = false;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  final _apiService = ApiService();
  final _tokenService = TokenService();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _notes.clear(); // Clear existing notes before loading new ones
      });
    }

    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.');
      }

      final notes = await _apiService.getNotes(token);
      if (mounted) {
        setState(() {
          _notes.addAll(notes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notlar yüklenirken hata oluştu: $e'),
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

  @override
  Widget build(BuildContext context) {
    // Boş liste kontrolü
    if (_notes.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            'NOTLARIM',
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B7FD7),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Color(0xFF6B7FD7)),
              onPressed: () {
                // TODO: Implement search
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFF6B7FD7)),
              onPressed: () {
                // TODO: Implement notifications
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7FD7)),
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz not eklenmemiş',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yeni bir not eklemek için + butonuna basın',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddNoteScreen()),
            );
            
            if (result == true) {
              _loadNotes(); // Yeni not eklendiğinde listeyi yenile
            }
          },
          backgroundColor: const Color(0xFF6B7FD7),
          child: const Icon(Icons.add_rounded),
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
          onTap: (index) {
            if (index == 1) { // Chat icon
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            }
            // TODO: Implement other navigation options
          },
        ),
      );
    }
    
    // Normal görünüm
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'NOTLARIM',
          style: GoogleFonts.poppins(
            color: const Color(0xFF6B7FD7),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF6B7FD7)),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF6B7FD7)),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _loadNotes,
        color: const Color(0xFF6B7FD7),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7FD7)),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: NoteCard(note: note),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddNoteScreen()),
          );
          
          if (result == true) {
            _loadNotes(); // Yeni not eklendiğinde listeyi yenile
          }
        },
        backgroundColor: const Color(0xFF6B7FD7),
        child: const Icon(Icons.add_rounded),
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
        onTap: (index) {
          if (index == 1) { // Chat icon
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          }
          // TODO: Implement other navigation options
        },
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final Note note;

  const NoteCard({
    super.key,
    required this.note,
  });

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(note.createdAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else {
      return '${difference.inDays} gün önce';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve Yazar Bilgisi
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF6B7FD7),
                    child: Text(
                      note.ownerUsername[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    note.ownerUsername,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getTimeAgo(),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
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
          // Not İçeriği
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
          // PDF Dosyası ve Sayfa Bilgisi
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
              title: Text('PDF Dosyası'),
              subtitle: Text('Sayfa: ${note.page}'),
              trailing: IconButton(
                icon: const Icon(Icons.download_rounded, color: Color(0xFF6B7FD7)),
                onPressed: () {
                  // TODO: PDF dosyasını indirme işlemi
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
} 