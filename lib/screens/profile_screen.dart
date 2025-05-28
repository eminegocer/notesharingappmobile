import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import './edit_profile_screen.dart';
import './note_detail_screen.dart';
import '../models/note.dart';
import '../services/token_service.dart';
import './login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String token;
  const ProfileScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final data = await ApiService().getUserProfile(widget.token);
      setState(() {
        profileData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Hata yönetimi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil yüklenemedi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = profileData?['user'] ?? {};
    return Scaffold(
      backgroundColor: const Color(0xFFEAF1FB),
      appBar: AppBar(
        title: const Text('Profilim'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3A7BD5),
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              await TokenService().deleteToken();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileData == null
              ? const Center(child: Text('Profil bilgisi bulunamadı.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      // Profil Fotoğrafı
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade100,
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: (user['profilePicture'] ?? '').toString().isNotEmpty
                            ? CircleAvatar(
                                radius: 60,
                                backgroundImage: CachedNetworkImageProvider(user['profilePicture']),
                              )
                            : CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.blue.shade200,
                                child: const Icon(Icons.person, size: 60, color: Colors.white),
                              ),
                      ),
                      const SizedBox(height: 18),
                      // Kullanıcı Adı
                      Text(
                        user['userName'] ?? '-',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3A7BD5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // E-posta
                      Text(
                        user['email'] ?? '-',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Biyografi
                      if ((user['bio'] ?? '').toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFF3A7BD5)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  user['bio'],
                                  style: const TextStyle(fontSize: 15, color: Color(0xFF3A7BD5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Okul, Bölüm, Sınıf, Not Sayısı
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                          child: Column(
                            children: [
                              _profileInfoRow(Icons.school, 'Okul', user['schoolName']),
                              const Divider(),
                              _profileInfoRow(Icons.account_balance, 'Bölüm', user['department']),
                              const Divider(),
                              _profileInfoRow(Icons.calendar_today, 'Sınıf', user['year']?.toString()),
                              const Divider(),
                              _profileInfoRow(Icons.note, 'Paylaşılan Not', user['sharedNotesCount']?.toString()),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Notlar Kartları
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NotesListScreen(
                                      title: 'Paylaşılan Notlar',
                                      notes: profileData?['sharedNotes'] ?? [],
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                color: Colors.blue.shade50,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                                  child: Column(
                                    children: [
                                      Icon(Icons.upload_file, color: Colors.blue.shade400, size: 32),
                                      const SizedBox(height: 8),
                                      Text('Paylaşılan Notlar', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                      Text((profileData?['sharedNotes']?.length ?? 0).toString(), style: TextStyle(fontSize: 18, color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NotesListScreen(
                                      title: 'Alınan Notlar',
                                      notes: profileData?['receivedNotes'] ?? [],
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                color: Colors.blue.shade50,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                                  child: Column(
                                    children: [
                                      Icon(Icons.download_rounded, color: Colors.blue.shade400, size: 32),
                                      const SizedBox(height: 8),
                                      Text('Alınan Notlar', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                      Text((profileData?['receivedNotes']?.length ?? 0).toString(), style: TextStyle(fontSize: 18, color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Profili Düzenle Butonu
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Profil düzenleme ekranına yönlendir
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                token: widget.token,
                                user: user,
                              ),
                            ),
                          );
                          if (updated == true) {
                            fetchProfile(); // Profil güncellendiyse tekrar yükle
                          }
                        },
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text('Profili Düzenle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF90CAF9), // Pastel mavi
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF3A7BD5)),
        const SizedBox(width: 14),
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A7BD5))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value ?? '-',
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Yeni: Notlar Listesi Ekranı (Modern ve Hover Efektli)
class NotesListScreen extends StatelessWidget {
  final String title;
  final List notes;
  const NotesListScreen({Key? key, required this.title, required this.notes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF3A7BD5),
      ),
      body: notes.isEmpty
          ? const Center(child: Text('Hiç not yok.'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return _ModernNoteCard(note: note);
              },
            ),
    );
  }
}

class _ModernNoteCard extends StatefulWidget {
  final Map note;
  const _ModernNoteCard({Key? key, required this.note}) : super(key: key);

  @override
  State<_ModernNoteCard> createState() => _ModernNoteCardState();
}

class _ModernNoteCardState extends State<_ModernNoteCard> {
  bool _isHovered = false;

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'biyoloji':
        return Icons.biotech;
      case 'fizik':
        return Icons.science;
      case 'matematik':
        return Icons.calculate;
      case 'kimya':
        return Icons.science;
      case 'tarih':
        return Icons.history_edu;
      case 'edebiyat':
        return Icons.menu_book;
      default:
        return Icons.book;
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(
                note: _mapToNote(note),
                searchTerm: null,
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFE3F2FD) : const Color(0xFFF7FBFF), // Daha açık pastel mavi
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? Colors.blue.shade100 : Colors.grey.withOpacity(0.10),
                blurRadius: _isHovered ? 18 : 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: _isHovered ? const Color(0xFF3A7BD5) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.description, color: Colors.blue.shade700),
            ),
            title: Row(
              children: [
                Icon(Icons.menu_book, color: Color(0xFF3A7BD5), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note['title'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(_getCategoryIcon(note['category']), color: Colors.blueGrey.shade400, size: 18),
                    const SizedBox(width: 6),
                    Text(note['category'] ?? '', style: TextStyle(color: Colors.blueGrey.shade600)),
                  ],
                ),
                if ((note['content'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      note['content'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF3A7BD5)),
          ),
        ),
      ),
    );
  }

  // JSON'dan Note modeline dönüştür
  Note _mapToNote(Map note) {
    return Note.fromJson(Map<String, dynamic>.from(note));
  }
}