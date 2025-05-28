import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewScreen extends StatelessWidget {
  final String pdfPath;
  final String? title;

  const PdfViewScreen({Key? key, required this.pdfPath, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'PDF Görüntüleyici'),
        backgroundColor: const Color(0xFF6B7FD7),
      ),
      body: PDFView(
        filePath: pdfPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF yüklenemedi: $error')),
          );
        },
      ),
    );
  }
} 