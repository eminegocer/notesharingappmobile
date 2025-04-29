import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/note.dart';

class NoteDetailScreen extends StatelessWidget {
  final Note note;
  final String? searchTerm;

  const NoteDetailScreen({
    super.key,
    required this.note,
    this.searchTerm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'NOT DETAYI',
          style: GoogleFonts.poppins(
            color: const Color(0xFF6B7FD7),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7FD7)),
          onPressed: () {
            Navigator.pop(context, searchTerm); // Arama terimini geri döndür
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              note.title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Kullanıcı bilgileri
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
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
                const SizedBox(width: 8),
                Text(
                  note.ownerUsername.isNotEmpty ? note.ownerUsername : 'Bilinmeyen',
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
                  _getTimeAgo(note.createdAt),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Kategori
            if (note.category.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7FD7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  note.category,
                  style: const TextStyle(
                    color: Color(0xFF6B7FD7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // İçerik
            Text(
              note.content,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // PDF Dosyası
            if (note.pdfFilePath != null && note.pdfFilePath!.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
} 