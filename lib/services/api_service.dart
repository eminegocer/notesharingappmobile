import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/note.dart';
import '../models/chat.dart';
import '../services/token_service.dart';
import '../models/user.dart';

class ApiService {
  final client = http.Client();
  final TokenService _tokenService = TokenService();
  String? _currentUsername;

  // HTTP GET yardımcı metodu
  Future<http.Response> _get(String url, String token) async {
    return await http.get(
      Uri.parse(url),
      headers: ApiConfig.getHeaders(token),
    );
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
        headers: ApiConfig.getHeaders(token),
      );

      print('Notlar yanıtı alındı. Status: ${response.statusCode}');

      if (response.statusCode == ApiConfig.statusOk) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        print('Alınan not sayısı: ${jsonData.length}');

        List<Note> notes = jsonData.map((noteJson) {
          try {
            return Note.fromJson(noteJson as Map<String, dynamic>);
          } catch (e) {
            print('Not parse edilirken hata: $noteJson, Hata: $e');
            return null;
          }
        }).where((note) => note != null)
          .cast<Note>()
          .toList();

        return notes;
      } else {
        print('Notlar yüklenemedi. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Notlar yüklenirken hata oluştu. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Notlar yüklenirken bir hata oluştu: $e');
      return [];
    }
  }

  // Login işlemi için apiye istek gönderme
  Future<Map<String, dynamic>> login(String userName, String email, String password) async {
    try {
      print('Login isteği gönderiliyor: ${ApiConfig.baseUrl}${ApiConfig.login}');
      print('Username: $userName, Email: $email');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: ApiConfig.getHeaders(null), // No token needed for login
        body: jsonEncode({
          'UserName': userName, 
          'Email': email,      
          'Password': password  
        }),
      );

      print('Login yanıtı alındı. Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == ApiConfig.statusOk) {
        final responseBody = jsonDecode(response.body);
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
        headers: ApiConfig.getHeaders(null),
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
        headers: ApiConfig.getHeaders(token),
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Mevcut kullanıcı bilgilerini getirme
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final response = await _get('${ApiConfig.baseUrl}/api/chat/current', token);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get current user');
    }
  }

  // Authentication kontrolü
  Future<bool> checkAuth(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.checkAuth}'),
        headers: ApiConfig.getHeaders(token),
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
        headers: ApiConfig.getHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Not kategorilerini getirme
  Future<List<String>> getCategories(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.categories}'),
        headers: ApiConfig.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend ["Matematik", "Fizik"] gibi bir liste döndürüyor
        return List<String>.from(data);
      } else {
        throw Exception('Kategoriler alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kategoriler alınırken hata oluştu: $e');
    }
  }

  // Belirli bir notu getirme
  Future<Map<String, dynamic>> getNoteById(String token, String noteId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getNoteById}$noteId'),
        headers: ApiConfig.getHeaders(token),
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
        headers: ApiConfig.getHeaders(token),
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
        headers: ApiConfig.getHeaders(token),
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Chat başlatma
  Future<Map<String, dynamic>> startChat(String token, String targetUsername, String message) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.addChat}'),
        headers: ApiConfig.getHeaders(token),
        body: jsonEncode(targetUsername), // Backend sadece kullanıcı adını bekliyor
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
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.searchUsers}?searchTerm=$searchTerm'),
        headers: ApiConfig.getHeaders(token),
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

  // Kişisel sohbetleri getirme
  Future<List<Chat>> getPersonalChats(String token) async {
    try {
      print('Kişisel sohbetler yükleniyor...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatUsers}'),
        headers: ApiConfig.getHeaders(token),
      );

      print('Kişisel sohbetler yanıtı alındı. Status: ${response.statusCode}');
      
      if (response.statusCode == ApiConfig.statusOk) {
        final List<dynamic> usernames = jsonDecode(response.body);
        print('Alınan kullanıcı sayısı: ${usernames.length}');
        
        List<Chat> chats = [];
        for (String username in usernames) {
          try {
            final chatResponse = await http.get(
              Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatHistory}?targetUsername=$username'),
              headers: ApiConfig.getHeaders(token),
            );
            
            if (chatResponse.statusCode == ApiConfig.statusOk) {
              final chatData = jsonDecode(chatResponse.body)['chatHistory'];
              chats.add(Chat.fromJson(chatData));
            }
          } catch (e) {
            print('Sohbet yüklenirken hata: $e');
          }
        }
        return chats;
      } else {
        print('Kişisel sohbetler yanıt hatası: ${response.body}');
        throw Exception('Kişisel sohbetler yüklenirken hata oluştu');
      }
    } catch (e) {
      print('Kişisel sohbetler yüklenirken hata: $e');
      return [];
    }
  }

  // Grup sohbetlerini getirme
  Future<List<dynamic>> getGroupChats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getUserGroups}'),
        headers: ApiConfig.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> groups = json.decode(response.body);
        print('Retrieved ${groups.length} group chats');
        return groups;
      } else {
        throw Exception('Failed to load group chats');
      }
    } catch (e) {
      print('Error getting group chats: $e');
      return [];
    }
  }

  // Sohbet geçmişini getirme
  Future<Chat> getChatHistory(String token, String targetUsername) async {
    try {
      print('Sohbet geçmişi yükleniyor...');
      print('Hedef kullanıcı: $targetUsername');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatHistory}?targetUsername=$targetUsername'),
        headers: ApiConfig.getHeaders(token),
      );

      print('Sohbet geçmişi yanıtı alındı. Status: ${response.statusCode}');
      print('Yanıt body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parse edilen veri: $data');
        
        if (data['chatHistory'] == null) {
          print('chatHistory null, yeni sohbet oluşturuluyor...');
          return Chat(
            senderUsername: targetUsername,
            receiverUsername: targetUsername,
            messages: [],
            usersId: [],
            createdAt: DateTime.now(),
          );
        }
        
        final chatData = data['chatHistory'];
        print('Chat verisi: $chatData');
        
        final messages = (chatData['messages'] as List?)?.map((msg) => Message(
          senderId: msg['senderId'] ?? '',
          senderUsername: msg['senderUsername'] ?? '',
          content: msg['content'] ?? '',
          fileUrl: msg['fileUrl'],
          createdAt: DateTime.parse(msg['createdAt'] ?? DateTime.now().toIso8601String()),
        )).toList() ?? [];
        
        print('Parse edilen mesaj sayısı: ${messages.length}');
        
        return Chat(
          senderUsername: chatData['senderUsername'] ?? targetUsername,
          receiverUsername: chatData['receiverUsername'] ?? targetUsername,
          messages: messages,
          usersId: [],
          createdAt: DateTime.now(),
        );
      } else {
        print('Sohbet geçmişi yüklenemedi. Status: ${response.statusCode}');
        throw Exception('Sohbet geçmişi yüklenemedi');
      }
    } catch (e) {
      print('Sohbet geçmişi yüklenirken hata: $e');
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Grup mesajlarını getirme
  Future<List<dynamic>> getGroupMessages(String token, String groupId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.groupMessages}?groupId=$groupId'),
        headers: ApiConfig.getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Grup mesajları yüklenemedi');
      }
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Sohbet görüntüleme
  Future<Chat> getChatView(String token, String targetUsername) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatHistory}?targetUsername=$targetUsername'),
        headers: ApiConfig.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['chatHistory'];
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
        headers: ApiConfig.getHeaders(token),
        body: '"$targetUsername"',
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
      
      request.headers.addAll(ApiConfig.getMultipartHeaders(token));
      
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
  // Not ekleme (PDF dosyası ile birlikte)
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

  // Not arama fonksiyonu
  Future<List<Note>> searchNotes(String token, String searchTerm) async {
    // Eğer arama terimi boşsa, tüm notları getir (veya boş liste döndür)
    if (searchTerm.trim().isEmpty) {
      return []; // Boş arama boş sonuç döndürsün
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.searchNotes}')
          .replace(queryParameters: {'term': searchTerm.trim()}); // Sorgu parametresini ekle ve trim et

      print('Notlar API\'den aranıyor: $uri');
      print('Kullanılan Token: $token');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(token),
      );

      print('Arama yanıtı alındı. Status: ${response.statusCode}');
      print('Arama yanıtı: ${response.body}');

      if (response.statusCode == ApiConfig.statusOk) {
        if (response.body.isEmpty) {
          print('Arama yanıtı boş');
          return [];
        }

        final List<dynamic> jsonData = jsonDecode(response.body);
        print('Arama sonucu bulunan not sayısı: ${jsonData.length}');

        List<Note> notes = jsonData.map((noteJson) {
          try {
            return Note.fromJson(noteJson as Map<String, dynamic>);
          } catch (e) {
            print('Arama sonucu not parse edilirken hata: $noteJson, Hata: $e');
            return null;
          }
        }).where((note) => note != null)
          .cast<Note>()
          .toList();

        return notes;
      } else {
        print('Arama başarısız. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Not araması başarısız oldu. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Not arama sırasında hata: $e');
      throw Exception('Not araması sırasında bir hata oluştu: $e');
    }
  }

  // Mesaj gönderme
  Future<Map<String, dynamic>> sendMessage(
    String token,
    String targetUsername,
    String message, {
    String? fileUrl,
  }) async {
    final body = {
      'targetUsername': targetUsername,
      'content': message,
    };
    if (fileUrl != null && fileUrl.isNotEmpty) {
      body['fileUrl'] = fileUrl;
    }
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/chat/send-message'),
      headers: ApiConfig.getHeaders(token),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // Grup mesajı gönderme
  Future<Map<String, dynamic>> sendGroupMessage(
    String token,
    String groupId,
    String message,
    String senderUsername, {
    String? fileUrl,
  }) async {
    final body = {
      'GroupId': groupId,
      'Content': message,
      'SenderUsername': senderUsername,
      'FileUrl': fileUrl ?? '',
    };
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sendGroupMessage}'),
      headers: ApiConfig.getHeaders(token),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // Okul gruplarını arama
  Future<List<Map<String, dynamic>>> searchGroups(String token, String searchTerm) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/search-groups?searchTerm=$searchTerm'),
        headers: ApiConfig.getHeaders(token),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((group) => Map<String, dynamic>.from(group)).toList();
      } else {
        throw Exception('Grup araması başarısız oldu');
      }
    } catch (e) {
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      print('Profil bilgileri yükleniyor...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getProfile}'),
        headers: ApiConfig.getHeaders(token),
      );

      print('Profil yanıtı alındı. Status: ${response.statusCode}');
      print('Yanıt body: ${response.body}');

      if (response.statusCode == ApiConfig.statusOk) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Profil bilgileri yüklenemedi');
      }
    } catch (e) {
      print('Profil yüklenirken hata: $e');
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile(String token, Map<String, dynamic> profileData) async {
    try {
      print('Profil güncelleniyor...');
      print('Güncellenecek veriler: $profileData');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/update'),
        headers: ApiConfig.getHeaders(token),
        body: jsonEncode(profileData),
      );

      print('Profil güncelleme yanıtı alındı. Status: ${response.statusCode}');
      print('Yanıt body: ${response.body}');

      if (response.statusCode == ApiConfig.statusOk) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Profil güncellenemedi');
      }
    } catch (e) {
      print('Profil güncellenirken hata: $e');
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Get user's shared notes
  Future<List<Note>> getUserSharedNotes(String token) async {
    try {
      print('Paylaşılan notlar yükleniyor...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/shared-notes'),
        headers: ApiConfig.getHeaders(token),
      );

      print('Paylaşılan notlar yanıtı alındı. Status: ${response.statusCode}');

      if (response.statusCode == ApiConfig.statusOk) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((noteJson) => Note.fromJson(noteJson as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Paylaşılan notlar yüklenemedi');
      }
    } catch (e) {
      print('Paylaşılan notlar yüklenirken hata: $e');
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Get user's received notes
  Future<List<Note>> getUserReceivedNotes(String token) async {
    try {
      print('Alınan notlar yükleniyor...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/received-notes'),
        headers: ApiConfig.getHeaders(token),
      );

      print('Alınan notlar yanıtı alındı. Status: ${response.statusCode}');

      if (response.statusCode == ApiConfig.statusOk) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((noteJson) => Note.fromJson(noteJson as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Alınan notlar yüklenemedi');
      }
    } catch (e) {
      print('Alınan notlar yüklenirken hata: $e');
      throw Exception('${ApiConfig.networkError}: $e');
    }
  }

  // Kullanıcının dahil olduğu grup sohbetlerini (Groups koleksiyonu) getirme
  Future<List<dynamic>> getUserGroups(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/user-groups'),
        headers: ApiConfig.getHeaders(token),
      );
      if (response.statusCode == 200) {
        final List<dynamic> groups = json.decode(response.body);
        return groups;
      } else {
        throw Exception('Grup sohbetleri alınamadı');
      }
    } catch (e) {
      print('Grup sohbetleri alınırken hata: $e');
      return [];
    }
  }

  Future<String> summarizeNote(String token, String fileName) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/PDFSummary/$fileName'),
        headers: ApiConfig.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['summary'] ?? 'Özet alınamadı.';
      } else {
        throw Exception('Özetleme başarısız oldu. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Özetleme sırasında hata: $e');
      throw Exception('${ApiConfig.networkError}: Özetleme sırasında hata oluştu.');
    }
  }

  Future<List<VisitedNote>> getVisitedNotes(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notes/visited'),
        headers: ApiConfig.getHeaders(token),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => VisitedNote.fromJson(e)).toList();
      } else {
        throw Exception('Son ziyaret edilen notlar alınamadı');
      }
    } catch (e) {
      print('Son ziyaret edilen notlar alınırken hata: $e');
      return [];
    }
  }

  // En çok indirilen notları getirme
  Future<List<Note>> getTopDownloadedNotes(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.topDownloaded}'),
        headers: ApiConfig.getHeaders(token),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Note.fromJson(e)).toList();
      } else {
        throw Exception('En çok indirilen notlar alınamadı');
      }
    } catch (e) {
      throw Exception('En çok indirilen notlar alınırken hata oluştu: $e');
    }
  }

  // Notun son görüntülenme zamanını güncelleyen endpoint
  Future<void> trackNoteView(String token, String noteId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/notes/view');
    final response = await http.post(
      url,
      headers: ApiConfig.getHeaders(token),
      body: '"$noteId"', // JSON string olarak gönder
    );
    if (response.statusCode != 200) {
      throw Exception('Son görüntüleme güncellenemedi: ${response.body}');
    }
  }

  // Kategoriye göre notları getirme
  Future<List<Note>> getNotesByCategory(String token, String category) async {
    try {
      print('Kategoriye göre notlar yükleniyor...');
      print('Kategori: $category');
      // URL'deki özel karakterleri encode et
      final encodedCategory = Uri.encodeComponent(category);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notes}/category/$encodedCategory'),
        headers: ApiConfig.getHeaders(token),
      );
      print('Kategori notları yanıtı alındı. Status: ${response.statusCode}');
      print('Yanıt body: ${response.body}');
      if (response.statusCode == ApiConfig.statusOk) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        print('Kategori notları sayısı: ${jsonData.length}');
        for (var noteJson in jsonData) {
          print('Kategori not JSON: ' + noteJson.toString());
        }
        List<Note> notes = jsonData.map((noteJson) {
          try {
            return Note.fromJson(noteJson as Map<String, dynamic>);
          } catch (e) {
            print('Not parse edilirken hata: $noteJson, Hata: $e');
            return null;
          }
        }).where((note) => note != null)
          .cast<Note>()
          .toList();
        return notes;
      } else {
        print('Kategori notları yüklenemedi. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Kategori notları yüklenirken hata oluştu. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Kategori notları yüklenirken bir hata oluştu: $e');
      return [];
    }
  }

  // Yeni test sorusu çekme
  Future<List<dynamic>> generateTestQuestions(String token) async {
    try {
      print('Test soruları yükleniyor...');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.generateTestQuestions}'),
        headers: ApiConfig.getHeaders(token),
      );
      print('Test soruları yanıtı alındı. Status: ${response.statusCode}');
      print('Yanıt body: ${response.body}');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data']; // List<CategoryQuestion>
      } else {
        throw Exception(data['error'] ?? 'Test soruları alınamadı. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Test soruları yüklenirken hata: $e');
      throw Exception('Test soruları yüklenirken bir hata oluştu: $e');
    }
  }

  // Yeni test sonucu gönderme
  Future<Map<String, dynamic>> submitTest(String token, List<Map<String, dynamic>> answers) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.submitTest}'),
      headers: ApiConfig.getHeaders(token),
      body: jsonEncode(answers),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data']; // {categoryStats: [...], recommendedNotes: [...]}
    } else {
      throw Exception(data['error'] ?? 'Test sonucu gönderilemedi');
    }
  }

  // Not indirme işlemini backend'e bildirir
  Future<bool> trackNoteDownload(String token, String noteId, {String source = 'note_detail'}) async {
    try {
      print('Gönderilen NoteId: $noteId');
      print('KULLANILAN TOKEN: $token');
      print('KULLANILAN HEADER: ${ApiConfig.getHeaders(token)}');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.trackDownload}'),
        headers: ApiConfig.getHeaders(token),
        body: jsonEncode({
          'NoteId': noteId,   // Büyük harfli anahtarlar
          'Source': source,
        }),
      );
      print('YANIT: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      print('trackNoteDownload HATASI: ${e.toString()}');
      return false;
    }
  }
}