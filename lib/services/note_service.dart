import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:notesharingappmobile/models/note.dart';
import 'package:notesharingappmobile/config/api_config.dart';

class NoteService {
  Future<List<Note>> getNotes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notes}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Note.fromJson(json)).toList();
      } else {
        throw Exception('Notlar yüklenirken bir hata oluştu');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  Future<void> addNote(String title, String description, String category, String filePath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.addNote}'),
      );

      // Form alanlarını ekle
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['category'] = category;

      // PDF dosyasını ekle
      request.files.add(await http.MultipartFile.fromPath(
        'PdfFile',
        filePath,
      ));

      var response = await request.send();
      if (response.statusCode != 201) {
        throw Exception('Not eklenirken bir hata oluştu');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }
} 