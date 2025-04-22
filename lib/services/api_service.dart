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
      print("Notlar API'den yukleniyor: ${ApiConfig.baseUrl}${ApiConfig.notes}");
      print('Kullanılan Token: $token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notes}'),
        headers: _getHeaders(token), // Notları getirmek için token gerekli
      );

      print('Notlar yanıtı alındı. Status: ${response.statusCode}');

      if (response.statusCode == ApiConfig.statusOk) {
        // Yanıt gövdesini decode et (bir liste bekleniyor)
        final List<dynamic> jsonData = jsonDecode(response.body);
        print('Alınan not sayısı: ${jsonData.length}');

        // JSON listesini List<Note> listesine dönüştür
        List<Note> notes = jsonData.map((noteJson) {
          try {
            return Note.fromJson(noteJson as Map<String, dynamic>);
          } catch (e) {
            print('Not parse edilirken hata: $noteJson, Hata: $e');
            // Hatalı veriyi atlamak için null döndür ve sonra filtrele
            return null;
          }
        }).where((note) => note != null) // null olanları filtrele
          .cast<Note>() // Tipi List<Note> olarak belirle
          .toList();

        return notes;
      } else {
        // Hata durumunu işle
        print('Notlar yüklenemedi. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Notlar yüklenirken hata oluştu. Status: ${response.statusCode}');
      }

    } catch (e) {
      print('Notlar yüklenirken bir hata oluştu: $e');
      // Hata durumunda boş liste döndür veya hatayı yeniden fırlat
      // throw Exception('${ApiConfig.networkError}: $e'); 
      return []; // Şimdilik boş liste döndürelim
    }
  }

  // Login işlemi
  Future<Map<String, dynamic>> login(String userName, String email, String password) async {
    try {
      print('Login isteği gönderiliyor: ${ApiConfig.baseUrl}${ApiConfig.login}');
      print('Username: $userName, Email: $email');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: _getHeaders(null), // No token needed for login
        body: jsonEncode({
          // Backend'in User modeline göre alan adları eşleşmeli
          // HomeApiController'daki Login metodu [FromBody] User user alıyor.
          // User modelinde hangi alanlar var? Genellikle UserName veya Email ve Password olur.
          // Backend kodu hem UserName hem Password kontrolü yapıyor gibi.
          // E-posta da gönderelim, belki ileride kullanılır.
          'UserName': userName, // Backend User modelindeki özellikle eşleştiğini varsayalım
          'Email': email,       // Backend User modelindeki özellikle eşleştiğini varsayalım
          'Password': password  // Backend User modelindeki özellikle eşleştiğini varsayalım
        }),
      );

      print('Login yanıtı alındı. Status: ${response.statusCode}, Body: ${response.body}');

      // Doğrudan başarılı yanıt döndürmek yerine, gerçek yanıtı işle
      if (response.statusCode == ApiConfig.statusOk) {
        final responseBody = jsonDecode(response.body);
        // Backend'den gelen yanıtı doğrudan döndür (veya gerekli alanları seçerek)
        // Backend yanıtı: { message, userId, userName, token }
        return {
          'success': true, // Başarıyı status code'dan anlıyoruz
          'message': responseBody['message'] ?? 'Giriş başarılı',
          'userId': responseBody['userId'], // Backend'den gelen ID'yi al
          'userName': responseBody['userName'], // Backend'den gelen kullanıcı adını al
          'token': responseBody['token'] // Backend'den gelen GERÇEK token'ı al
        };
      } else {
        // Hata durumunu işle
        String errorMessage = 'Giriş yapılamadı. Status: ${response.statusCode}';
        try {
          // Hata mesajını yanıttan almaya çalış
          final errorBody = jsonDecode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (e) {
          // JSON parse edilemezse veya mesaj yoksa, varsayılan mesajı kullan
          print('Login yanıtı parse edilemedi veya mesaj yok: ${response.body}');
        }
         return {
          'success': false,
          'message': errorMessage
        };
      }

    } catch (e) {
      print('Login hatası: $e');
      return {
        'success': false,
        'message': '${ApiConfig.networkError}: $e' // Daha açıklayıcı hata
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