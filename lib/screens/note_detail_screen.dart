import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import 'pdf_view_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  final String? searchTerm;

  const NoteDetailScreen({
    super.key,
    required this.note,
    this.searchTerm,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();
  bool _isLoading = false;
  String? _summary;
  String? _errorMessage;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _trackNoteView();
  }

  Future<void> _trackNoteView() async {
    final token = await _tokenService.getToken();
    if (token != null && widget.note.noteId != null) {
      await _apiService.trackNoteView(token, widget.note.noteId!);
    }
  }

  Future<void> _getSummary() async {
    if (widget.note.pdfFilePath == null || widget.note.pdfFilePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF dosyası bulunamadı.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _summary = null;
    });

    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Oturum bilgisi bulunamadı');
      }

      final fileName = widget.note.pdfFilePath!.split('/').last;
      final summary = await _apiService.summarizeNote(token, fileName);

      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Özet alınırken hata oluştu: $e';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    }
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

  Future<String?> _downloadAndGetLocalPdfPath(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${url.split('/').last}');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleDownload() async {
    if (_isDownloading) return;
    setState(() { _isDownloading = true; });
    final token = await _tokenService.getToken();
    if (token == null || widget.note.noteId == null) {
      setState(() { _isDownloading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş yapmalısınız!')),
      );
      return;
    }
    final success = await _apiService.trackNoteDownload(token, widget.note.noteId!);
    setState(() { _isDownloading = false; });
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not başarıyla indirildi ve kaydedildi!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İndirme başarısız!')), 
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
          'NOT DETAYI',
          style: GoogleFonts.poppins(
            color: const Color(0xFF6B7FD7),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7FD7)),
          onPressed: () => Navigator.pop(context, widget.searchTerm),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              widget.note.title,
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
                    widget.note.ownerUsername.isNotEmpty
                        ? widget.note.ownerUsername[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.note.ownerUsername.isNotEmpty ? widget.note.ownerUsername : 'Bilinmeyen',
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
                  _getTimeAgo(widget.note.createdAt),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Kategori
            if (widget.note.category.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7FD7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.note.category,
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
              widget.note.content,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // PDF Dosyası
            if (widget.note.pdfFilePath != null && widget.note.pdfFilePath!.isNotEmpty)
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
                  title: GestureDetector(
                    child: Text('PDF Dosyası (${widget.note.page} sayfa)', style: TextStyle(decoration: TextDecoration.underline, color: Color(0xFF6B7FD7))),
                    onTap: () async {
                      final baseUrl = 'http://10.0.2.2:5000'; // Gerekirse değiştirin
                      final url = widget.note.pdfFilePath!.startsWith('http')
                        ? widget.note.pdfFilePath!
                        : baseUrl + widget.note.pdfFilePath!;
                      final localPath = await _downloadAndGetLocalPdfPath(url);
                      if (localPath != null && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfViewScreen(
                              pdfPath: localPath,
                              title: widget.note.title,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PDF dosyası açılamadı.')),
                        );
                      }
                    },
                  ),
                  trailing: IconButton(
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7FD7))),
                          )
                        : const Icon(Icons.download_rounded, color: Color(0xFF6B7FD7)),
                    onPressed: _isDownloading ? null : _handleDownload,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // AI Özetleme Butonu
            if (widget.note.pdfFilePath != null && widget.note.pdfFilePath!.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft, // Butonu sola hizala
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _getSummary,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isLoading ? 'Özetleniyor...' : 'AI ile Özetle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7FD7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // İç padding
                  ),
                ),
              ),

            // AI Özeti
            if (_summary != null) ...[
              const SizedBox(height: 16), // Buton ile özet arasına biraz boşluk ekleyelim
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF6B7FD7)),
                        const SizedBox(width: 8),
                        Text(
                          'AI Özeti',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6B7FD7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _summary!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 