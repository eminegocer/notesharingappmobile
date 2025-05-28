import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../screens/note_detail_screen.dart';
import '../config/api_config.dart';

class RecentlyVisitedNotesSection extends StatelessWidget {
  final List<VisitedNote> notes;
  final VoidCallback? onRefresh;

  const RecentlyVisitedNotesSection({
    Key? key, 
    required this.notes,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF2F7FF),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.07),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Icon(Icons.history, color: Color(0xFF3578E5)),
              SizedBox(width: 8),
              Text(
                "Son Ziyaret Edilen Notlar",
                style: TextStyle(
                  color: Color(0xFF3578E5),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Kartlar
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: notes.length,
              separatorBuilder: (_, __) => SizedBox(width: 12),
              itemBuilder: (context, index) {
                final note = notes[index];
                return _VisitedNoteCard(
                  note: note,
                  onRefresh: onRefresh,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitedNoteCard extends StatelessWidget {
  final VisitedNote note;
  final VoidCallback? onRefresh;

  const _VisitedNoteCard({
    Key? key, 
    required this.note,
    this.onRefresh,
  }) : super(key: key);

  Future<void> _goToDetail(BuildContext context) async {
    if (note.noteId.isEmpty) return;
    final apiService = ApiService();
    final tokenService = TokenService();
    final token = await tokenService.getToken();
    if (token == null) return;
    try {
      // Ziyaret kaydını backend'e gönder
      await apiService.trackNoteView(token, note.noteId);
      final noteJson = await apiService.getNoteById(token, note.noteId);
      final noteObj = Note.fromJson(noteJson);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoteDetailScreen(note: noteObj),
        ),
      ).then((_) {
        if (context.mounted) {
          onRefresh?.call();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not detayına gidilemedi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd.MM.yyyy').format(note.visitedAt);

    return GestureDetector(
      onTap: () => _goToDetail(context),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Color(0xFFE3EAF2)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.06),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              note.title,
              style: TextStyle(
                color: Color(0xFF3578E5),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            // Yazar ve kategori
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[500]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                  note.author,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              note.category,
              style: TextStyle(color: Colors.grey[400], fontSize: 12, fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            // Tarih ve etiket
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFE6F0FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Color(0xFF3578E5)),
                      SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Color(0xFF3578E5),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "Son Ziyaret",
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// En çok indirilen notlar bölümü
class TopDownloadedNotesSection extends StatelessWidget {
  final List<Note> notes;

  const TopDownloadedNotesSection({Key? key, required this.notes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF2F7FF),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.07),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Icon(Icons.download_rounded, color: Color(0xFF3578E5)),
              SizedBox(width: 8),
              Text(
                "En Çok İndirilen Notlar",
                style: TextStyle(
                  color: Color(0xFF3578E5),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Kartlar
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: notes.length,
              separatorBuilder: (_, __) => SizedBox(width: 12),
              itemBuilder: (context, index) {
                final note = notes[index];
                return _TopDownloadedNoteCard(note: note);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopDownloadedNoteCard extends StatelessWidget {
  final Note note;

  const _TopDownloadedNoteCard({Key? key, required this.note}) : super(key: key);

  Future<void> _goToDetail(BuildContext context) async {
    if (note.noteId == null || note.noteId!.isEmpty) return;
    final apiService = ApiService();
    final tokenService = TokenService();
    final token = await tokenService.getToken();
    if (token == null) return;
    try {
      final noteJson = await apiService.getNoteById(token, note.noteId!);
      final noteObj = Note.fromJson(noteJson);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoteDetailScreen(note: noteObj),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not detayına gidilemedi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _goToDetail(context),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Color(0xFFE3EAF2)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.06),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              note.title,
              style: TextStyle(
                color: Color(0xFF3578E5),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            // Yazar ve kategori
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[500]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                  note.ownerUsername,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                ),
              ],
            ),
            SizedBox(height: 4),
                if (note.category.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFF6B7FD7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      note.category,
                      style: TextStyle(
                        color: Color(0xFF6B7FD7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                    ),
                  ),
            SizedBox(height: 8),
            // İndirme sayısı
            Row(
              children: [
                Icon(Icons.download_rounded, size: 16, color: Color(0xFF3578E5)),
                SizedBox(width: 4),
                Text(
                  (note as dynamic).downloadCount?.toString() ?? '-',
                  style: TextStyle(
                    color: Color(0xFF3578E5),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "İndirme",
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 