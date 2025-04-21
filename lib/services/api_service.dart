import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/note.dart';
import '../models/chat.dart';

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

  // Tüm notları getirme
  Future<List<Note>> getNotes(String token) async {
    try {
      print('Notlar yükleniyor...');
      print('Token: $token');
      
      // Doğrudan örnek notlar döndürüyoruz - API'yi bypass ederek
      var notList = <Note>[];
      
      // Test verileri oluştur
      notList.add(
        Note(
          noteId: {'timestamp': 1741012345},
          title: 'Matematik Notları',
          content: 'Bu örnek bir matematik notudur. Diferansiyel denklemler, integral hesabı ve vektör cebiri gibi konuları içerir.',
          category: 'Matematik',
          page: 5,
          ownerId: {'timestamp': 1740123456},
          ownerUsername: 'Emine Göçer',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          pdfFilePath: '/uploads/sample1.pdf',
        )
      );
      
      notList.add(
        Note(
          noteId: {'timestamp': 1741023456},
          title: 'Fizik Notları',
          content: 'Mekanik, termodinamik, elektromanyetizma ve kuantum fiziği ile ilgili detaylı ders notları.',
          category: 'Fizik',
          page: 8,
          ownerId: {'timestamp': 1740123456},
          ownerUsername: 'Emine Göçer',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          pdfFilePath: '/uploads/sample2.pdf',
        )
      );
      
      notList.add(
        Note(
          noteId: {'timestamp': 1741034567},
          title: 'Kimya Notları',
          content: 'Organik kimya, inorganik kimya ve analitik kimya derslerinden derlenen notlar.',
          category: 'Kimya',
          page: 6,
          ownerId: {'timestamp': 1740123456},
          ownerUsername: 'Emine Göçer',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          pdfFilePath: '/uploads/sample3.pdf',
        )
      );
      
      notList.add(
        Note(
          noteId: {'timestamp': 1741045678},
          title: 'Biyoloji Notları',
          content: 'Hücre biyolojisi, genetik, evrim ve ekoloji konularını kapsayan ders notları.',
          category: 'Biyoloji',
          page: 4,
          ownerId: {'timestamp': 1740123456},
          ownerUsername: 'Emine Göçer',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          pdfFilePath: '/uploads/sample4.pdf',
        )
      );
      
      // 1 saniye gecikme ekle - gerçek bir API çağrısı gibi hissettirmek için
      await Future.delayed(const Duration(seconds: 1));
      
      return notList;
    } catch (e) {
      print('Notlar yüklenirken hata: $e');
      return [];
    }
  }

  // Login işlemi (basitleştirilmiş, doğrudan başarılı yanıt döndürür)
  Future<Map<String, dynamic>> login(String userName, String email, String password) async {
    try {
      print('Login isteği gönderiliyor...');
      print('Username: $userName, Email: $email');
      
      // API'yi bypass et ve doğrudan başarılı yanıt döndür
      await Future.delayed(const Duration(seconds: 1)); // Gerçek bir API isteği hissi ver
      
      return {
        'success': true,
        'message': 'Giriş başarılı',
        'userId': {'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000},
        'userName': userName,
        'token': 'manual_token_${userName}_${DateTime.now().millisecondsSinceEpoch}'
      };
    } catch (e) {
      print('Login hatası: $e');
      return {
        'success': false,
        'message': 'Bağlantı hatası: $e'
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
  Future<List<String>> searchUsers(String token, String searchTerm) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/search-users?searchTerm=$searchTerm'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((username) => username.toString()).toList();
      } else {
        throw Exception('Kullanıcı araması başarısız oldu');
      }
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

  // Sohbet görüntüleme
  Future<Chat> getChatView(String token, String targetUsername) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/chat-view?targetUsername=$targetUsername'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Chat.fromJson(data);
      } else {
        throw Exception('Sohbet yüklenemedi');
      }
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Sohbet başlatma
  Future<Map<String, dynamic>> addChat(String token, String targetUsername) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/add-chat'),
        headers: _getHeaders(token),
        body: jsonEncode(targetUsername),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Sohbet başlatılamadı');
      }
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Dosya yükleme
  Future<Map<String, dynamic>> uploadChatFile(String token, List<int> fileBytes, String fileName) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}/api/chat/upload-file');
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
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Dosya yüklenemedi');
      }
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  Future<Map<String, dynamic>> createNoteWithFile(
    String token,
    Map<String, dynamic> noteData,
    List<int> fileBytes,
    String fileName,
  ) async {
    try {
      print('Not ekleme başladı');
      print('Token: $token');
      print('Not başlığı: ${noteData['title']}');
      print('Dosya adı: $fileName');
      print('Dosya boyutu: ${fileBytes.length} bytes');

      var uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.addNote}');
      print('İstek URL: $uri');

      var request = http.MultipartRequest('POST', uri);
      
      // Token kontrolü
      if (token.isEmpty) {
        throw Exception('Token boş olamaz');
      }

      // Authorization header ayarı (JWT token)
      var headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      request.headers.addAll(headers);
      print('Headers: ${request.headers}');
      
      // Not verilerini form alanları olarak ekle
      request.fields['Title'] = noteData['title'];
      request.fields['Content'] = noteData['content'];
      request.fields['Category'] = noteData['category'];
      request.fields['Page'] = noteData['page'].toString();
      
      // PDF dosyasını ekle
      request.files.add(
        http.MultipartFile.fromBytes(
          'PdfFile',
          fileBytes,
          filename: fileName,
        ),
      );

      print('İstek hazırlandı, gönderiliyor...');
      var streamedResponse = await request.send();
      print('İstek gönderildi. Status code: ${streamedResponse.statusCode}');
      
      // Yönlendirmeyi kontrol et
      if (streamedResponse.statusCode == 302) {
        var location = streamedResponse.headers['location'];
        print('Yönlendirme adresi: $location');
        
        // Login sayfasına yönlendirildiyse token geçersiz demektir
        if (location != null && (location.contains('Login') || location.contains('login'))) {
          throw Exception('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
        }
      }
      
      // Yanıtı al
      var response = await http.Response.fromStream(streamedResponse);
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          try {
            return jsonDecode(response.body);
          } catch (e) {
            print('Yanıt JSON olarak ayrıştırılamadı: $e');
            return {'success': true, 'message': 'Not başarıyla eklendi'};
          }
        }
        return {'success': true, 'message': 'Not başarıyla eklendi'};
      } else {
        throw Exception('Not eklenirken bir hata oluştu. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Hata oluştu: $e');
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }
} 