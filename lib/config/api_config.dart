class ApiConfig {
  // API Base URL - Android Emulator için özel IP adresi
  static const String baseUrl = 'http://10.0.2.2:5000';
  // Not: Android Emulator'da localhost yerine 10.0.2.2 kullanılmalıdır
  // Gerçek cihazda test ederken IP adresini değiştirmelisiniz
  // static const String baseUrl = 'http://YOUR_LOCAL_IP:5000';
  
  // Authentication endpoints - RESTful API için
  static const String login = '/api/home/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String getCurrentUser = '/api/auth/user';
  static const String checkAuth = '/api/auth/check';
  
  // Note endpoints - RESTful API için
  static const String notes = '/api/notes';
  static const String myNotes = '/api/notes/my';
  static const String categories = '/api/notes/categories';
  static const String addNote = '/api/notes';  // Endpoint '/api/notes' olarak güncellendi
  static const String getNoteById = '/api/notes/';  // Kullanım: getNoteById + noteId
  static const String deleteNote = '/api/notes/';    // Kullanım: deleteNote + noteId
  
  // Chat endpoints
  static const String startChat = '/api/chat/start';
  static const String searchUsers = '/api/users/search';
  static const String uploadChatFile = '/api/chat/upload';
  static const String chatHistory = '/api/chat/history/'; // Kullanım: chatHistory + username
  static const String chatUsers = '/api/chat/users';
  
  // Group chat endpoints
  static const String joinGroup = '/api/groups/join';
  static const String searchGroups = '/api/groups/search';
  static const String schoolGroups = '/api/groups/school';
  
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

    // JWT token'ı Authorization header'ına ekleme
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
  
  // Multipart request headers
  static Map<String, String> getMultipartHeaders(String token) {
    final headers = {
      // Content-Type: multipart/form-data yerine,
      // http.MultipartRequest tarafından otomatik olarak boundary ile ayarlanacak
      'Accept': 'application/json',
      'Connection': 'keep-alive',
    };

    // JWT token'ı Authorization header'ına ekleme
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