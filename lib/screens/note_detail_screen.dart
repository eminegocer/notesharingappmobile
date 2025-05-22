import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  final String? searchTerm;

  const NoteDetailScreen({
    super.key,
    required this.note,
    this.searchTerm,
  });

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();
  bool _isSummarizing = false;
  String? _summaryText;
  bool _isDownloading = false;

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
            Navigator.pop(context, widget.searchTerm);
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
                    widget.note.ownerUsername.isNotEmpty ? widget.note.ownerUsername[0].toUpperCase() : '?',
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
                  title: Text('PDF Dosyası (${widget.note.page} sayfa)'),
                  trailing: IconButton(
                    icon: _isDownloading ?
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7FD7)),
                            ),
                          )
                        : const Icon(Icons.download_rounded, color: Color(0xFF6B7FD7)),
                    onPressed: _isDownloading ? null : () async {
                      print('Download tıklandı: ${widget.note.pdfFilePath}');

                      if (widget.note.pdfFilePath == null || widget.note.pdfFilePath!.isEmpty) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bu not için PDF dosyası bulunamadı.'))
                        );
                        return;
                      }

                      setState(() {
                        _isDownloading = true;
                      });

                      try {
                        final token = await _tokenService.getToken();
                        if (token == null) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.'))
                          );
                           setState(() {
                            _isDownloading = false;
                          });
                          return;
                        }

                        final String pdfUrl = '${ApiConfig.baseUrl}${widget.note.pdfFilePath}';
                        // Extract file name from the URL
                        final fileName = widget.note.pdfFilePath!.split('/').last;

                        print('PDF indiriliyor: $pdfUrl');
                        final localFilePath = await _apiService.downloadFile(pdfUrl, fileName, token);
                        print('PDF indirildi, yerel yol: $localFilePath');

                        // Open the downloaded file using url_launcher
                        final fileUri = Uri.file(localFilePath);
                        if (await canLaunchUrl(fileUri)) {
                          await launchUrl(fileUri);
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('İndirilen dosya açılamadı: $localFilePath'))
                          );
                           print('Hata: İndirilen dosya açılamadı: $localFilePath');
                        }

                      } catch (e) {
                        print('İndirme veya açma hatası: $e');
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Dosya indirilirken bir hata oluştu: ${e.toString()}'))
                        );
                      } finally {
                         setState(() {
                          _isDownloading = false;
                        });
                      }
                    },
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Yapay Zeka Özetleme Butonu
            ElevatedButton.icon(
              onPressed: _isSummarizing ? null : _summarizeNote,
              icon: _isSummarizing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(_isSummarizing ? 'Özetleniyor...' : 'Yapay Zeka ile Özetle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B7FD7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 5,
              ),
            ),

            // Özet metni
            if (_summaryText != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueGrey[200]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yapay Zeka Özeti:',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _summaryText!,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ],
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

  Future<void> _summarizeNote() async {
    setState(() {
      _isSummarizing = true;
      _summaryText = null;
    });

    // PDF dosya yolu yoksa özetleme yapma
    if (widget.note.pdfFilePath == null || widget.note.pdfFilePath!.isEmpty) {
       setState(() {
        _isSummarizing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu not için PDF dosyası bulunamadı.'))
      );
      return;
    }

    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Oturum bilgisi bulunamadı.');
      }

      // PDF dosya yolundan dosya adını al
      final fileName = widget.note.pdfFilePath!.split('/').last;

      // API'den özeti çek
      final fetchedSummary = await _apiService.summarizeNote(token, fileName);

      setState(() {
        _summaryText = fetchedSummary;
        _isSummarizing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not başarıyla özetlendi!'))
      );

    } catch (e) {
      print('Özetleme hatası: $e');
      setState(() {
        _summaryText = 'Özetleme başarısız oldu: ${e.toString()}';
        _isSummarizing = false;
      });
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_summaryText!))
       );
    }
  }
}

extension on DateTime {
  String toShortDateString() {
    return "${day}/${month}/${year}";
  }
} 