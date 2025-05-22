class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:5000';
  
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
  static const String addNote = '/api/notes';
  static const String getNoteById = '/api/notes/';
  static const String deleteNote = '/api/notes/';
  static const String searchNotes = '/api/notes/search';
  
  // Chat endpoints
  static const String addChat = '/api/chat/add-chat';
  static const String searchUsers = '/api/chat/search-users';
  static const String uploadChatFile = '/api/chat/upload-file';
  static const String chatHistory = '/api/chat/chat-history';
  static const String chatUsers = '/api/chat/chat-users';
  
  // Group chat endpoints
  static const String joinGroup = '/api/chat/join-school-group';
  static const String getUserGroups = '/api/chat/user-school-groups';
  static const String createGroup = '/api/chat/create-group';
  static const String groupMessages = '/api/chat/group-messages';
  
  // New endpoint
  static const String sendGroupMessage = '/api/chat/send-group-message';

  // Profile endpoints
  static const String getProfile = '/api/profile';
  static const String updateProfile = '/api/profile/update';
  static const String sharedNotes = '/api/profile/shared-notes';
  static const String receivedNotes = '/api/profile/received-notes';
  
  // Download endpoints
  static const String trackDownload = '/NoteDownload/TrackDownload';
  static const String getDownloadedNotes = '/NoteDownload/GetDownloadedNotes';
  
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