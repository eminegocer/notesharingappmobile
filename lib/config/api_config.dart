class ApiConfig {
  // API Base URL - Android Emulator için özel IP adresi
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  // Not: Android Emulator'da localhost yerine 10.0.2.2 kullanılmalıdır
  
  // Authentication endpoints
  static const String login = '/home/login';
  static const String register = '/home/register';
  static const String logout = '/home/logout';
  static const String getCurrentUser = '/home/current-user';
  static const String checkAuth = '/home/check';
  
  // Note endpoints
  static const String notes = '/notes';
  static const String myNotes = '/notes/my-notes';
  static const String categories = '/notes/categories';
  static const String addNote = '/notes';
  static const String getNoteById = '/notes/';  // Kullanım: getNoteById + noteId
  static const String deleteNote = '/notes/';    // Kullanım: deleteNote + noteId
  
  // Chat endpoints
  static const String startChat = '/chat/start';
  static const String searchUsers = '/users/search';
  static const String uploadChatFile = '/chat/upload';
  static const String chatHistory = '/chat/history/'; // Kullanım: chatHistory + username
  static const String chatUsers = '/chat/users';
  
  // Group chat endpoints
  static const String joinGroup = '/groups/join';
  static const String searchGroups = '/groups/search';
  static const String schoolGroups = '/groups/school';
  
  // HTTP Status Codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusNotFound = 404;
  static const int statusServerError = 500;
  
  // Error messages
  static const String unauthorizedError = 'Yetkisiz erişim';
  static const String networkError = 'Ağ hatası';
  static const String serverError = 'Sunucu hatası';
  static const String badRequestError = 'Geçersiz istek';
  static const String notFoundError = 'Kaynak bulunamadı';
  
  // Success messages
  static const String loginSuccess = 'Giriş başarılı.';
  static const String registerSuccess = 'Kayıt başarılı.';
  static const String logoutSuccess = 'Çıkış başarılı.';
  static const String uploadSuccess = 'Dosya yükleme başarılı.';
  static const String deleteSuccess = 'Silme işlemi başarılı.';
  
  // Request headers
  static Map<String, String> getHeaders([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Connection': 'keep-alive',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
  
  // Multipart request headers
  static Map<String, String> getMultipartHeaders(String token) {
    final headers = {
      'Content-Type': 'multipart/form-data',
      'Accept': 'application/json',
      'Connection': 'keep-alive',
    };

    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
  
  // API Response keys
  static const String successKey = 'success';
  static const String messageKey = 'message';
  static const String dataKey = 'data';
  static const String errorKey = 'error';
  static const String tokenKey = 'token';
} 