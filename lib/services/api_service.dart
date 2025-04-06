import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/note.dart';

class ApiService {
  final client = http.Client();

  // ASP.NET Core API için header'ları hazırlama
  Map<String, String> _getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': '*/*',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Multipart request için header'ları hazırlama
  Map<String, String> _getMultipartHeaders(String token) {
    final headers = {
      'Content-Type': 'multipart/form-data',
      'Accept': '*/*',
    };

    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Hata işleme yardımcı metodu
  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case ApiConfig.statusOk:
      case ApiConfig.statusCreated:
        return jsonDecode(response.body);
      case ApiConfig.statusUnauthorized:
        throw Exception(ApiConfig.unauthorizedError);
      case ApiConfig.statusNotFound:
        throw Exception(ApiConfig.notFoundError);
      case ApiConfig.statusBadRequest:
        throw Exception(ApiConfig.badRequestError);
      case ApiConfig.statusServerError:
        throw Exception(ApiConfig.serverError);
      default:
        throw Exception('Error: ${response.body}');
    }
  }

  // Login işlemi
  Future<Map<String, dynamic>> login(String userName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: _getHeaders(null),
        body: jsonEncode({
          'UserName': userName,
          'Email': email,
          'Password': password
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // HTML veya boş yanıt kontrolü
      if (response.body.trim().toLowerCase().startsWith('<!doctype html') ||
          response.body.trim().toLowerCase().startsWith('<html') ||
          response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Sunucudan beklenmeyen yanıt alındı. Lütfen API URLsini kontrol edin.'
        };
      }

      try {
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'Giriş başarılı',
            'userId': responseData['userId'],
            'userName': responseData['userName'],
            'token': responseData['token'] ?? responseData['accessToken'] ?? ''
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Giriş başarısız'
          };
        }
      } on FormatException {
        return {
          'success': false,
          'message': 'Sunucudan geçersiz veri alındı. JSON formatı hatalı olabilir.'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: Lütfen internet bağlantınızı veya API adresini kontrol edin.'
      };
    }
  }

  // Kayıt işlemi
  Future<Map<String, dynamic>> register(String email, String password, String username) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}'),
        headers: _getHeaders(null),
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Çıkış işlemi
  Future<void> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.logout}'),
        headers: _getHeaders(token),
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Mevcut kullanıcı bilgilerini getirme
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getCurrentUser}'),
        headers: _getHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Authentication kontrolü
  Future<bool> checkAuth(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.checkAuth}'),
        headers: _getHeaders(token),
      );
      final result = _handleResponse(response);
      return result[ApiConfig.successKey] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Tüm notları getirme
  Future<List<Note>> getNotes(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notes}'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        // JSON array'i parse et
        List<dynamic> jsonList = jsonDecode(response.body);
        // Her bir JSON objesini Note nesnesine dönüştür
        return jsonList.map((json) => Note.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Oturum süresi dolmuş veya geçersiz. Lütfen tekrar giriş yapın.');
      } else {
        throw Exception('Notlar yüklenirken bir hata oluştu. Durum kodu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Kullanıcının kendi notlarını getirme
  Future<List<dynamic>> getMyNotes(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.myNotes}'),
        headers: _getHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Not kategorilerini getirme
  Future<List<dynamic>> getNoteCategories(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.categories}'),
        headers: _getHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Belirli bir notu getirme
  Future<Map<String, dynamic>> getNoteById(String token, String noteId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getNoteById}$noteId'),
        headers: _getHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Yeni not ekleme
  Future<Map<String, dynamic>> createNote(String token, Map<String, dynamic> noteData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.addNote}'),
        headers: _getHeaders(token),
        body: jsonEncode(noteData),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Not silme
  Future<void> deleteNote(String token, String noteId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.deleteNote}$noteId'),
        headers: _getHeaders(token),
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Chat başlatma
  Future<Map<String, dynamic>> startChat(String token, String targetUsername) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.startChat}'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'targetUsername': targetUsername,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Kullanıcı arama
  Future<List<dynamic>> searchUsers(String token, String searchTerm) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.searchUsers}?term=$searchTerm'),
        headers: _getHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Chat geçmişini getirme
  Future<List<dynamic>> getChatHistory(String token, String username) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatHistory}$username'),
        headers: _getHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Chat kullanıcılarını getirme
  Future<List<dynamic>> getChatUsers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatUsers}'),
        headers: _getHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Gruba katılma
  Future<Map<String, dynamic>> joinGroup(String token, String groupId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.joinGroup}'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'groupId': groupId,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Grup arama
  Future<List<dynamic>> searchGroups(String token, String searchTerm) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.searchGroups}?term=$searchTerm'),
        headers: _getHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Okul gruplarını getirme
  Future<List<dynamic>> getSchoolGroups(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.schoolGroups}'),
        headers: _getHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Chat dosyası yükleme
  Future<Map<String, dynamic>> uploadChatFile(String token, List<int> fileBytes, String fileName) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.uploadChatFile}');
      var request = http.MultipartRequest('POST', uri);
      
      request.headers.addAll(_getMultipartHeaders(token));
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }
} 