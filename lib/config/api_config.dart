class ApiConfig {
  // ASP.NET Core API base URL
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android Emulator için localhost
  // Gerçek cihaz için kendi IP adresinizi kullanın: örn: 'http://192.168.1.100:5000/api'
  
  // Authentication endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String getCurrentUser = '/auth/current-user';
  static const String checkAuth = '/auth/check';
  
  // Note endpoints
  static const String notes = '/notes';
  static const String myNotes = '/notes/my-notes';
  static const String categories = '/notes/categories';
  static const String addNote = '/notes/add';
  static const String getNoteById = '/notes/';  // Kullanım: getNoteById + noteId
  static const String deleteNote = '/notes/';    // Kullanım: deleteNote + noteId
  
  // Chat endpoints
  static const String startChat = '/chat/start';
  static const String searchUsers = '/chat/search';
  static const String uploadChatFile = '/chat/upload';
  static const String chatHistory = '/chat/history/'; // Kullanım: chatHistory + username
  static const String chatUsers = '/chat/users';
  
  // Group chat endpoints
  static const String joinGroup = '/chat/groups/join';
  static const String searchGroups = '/chat/groups/search';
  static const String schoolGroups = '/chat/groups/school';
  
  // HTTP Status Codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusServerError = 500;
  
  // Error messages
  static const String unauthorizedError = 'Unauthorized: Please login again';
  static const String networkError = 'Network connection error';
  static const String serverError = 'Server error occurred';
  static const String badRequestError = 'Invalid request';
  static const String notFoundError = 'Resource not found';
  
  // Success messages
  static const String loginSuccess = 'Giriş başarılı.';
  static const String registerSuccess = 'Kayıt başarılı.';
  static const String logoutSuccess = 'Çıkış başarılı.';
  static const String uploadSuccess = 'Dosya yükleme başarılı.';
  static const String deleteSuccess = 'Silme işlemi başarılı.';
  
  // Request headers
  static Map<String, String> getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  
  static Map<String, String> getMultipartHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
    };
  }
  
  // API Response keys
  static const String successKey = 'success';
  static const String messageKey = 'message';
  static const String dataKey = 'data';
  static const String errorKey = 'error';
  static const String tokenKey = 'token';
} 