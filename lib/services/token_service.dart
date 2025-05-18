import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  // Token kaydetme
  Future<void> saveToken(String token) async {
    print('Token kaydediliyor: $token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('Token kaydedildi');
  }

  // Token getirme
  Future<String?> getToken() async {
    print('Token alınıyor...');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('Alınan token: $token');
    return token;
  }

  // User ID kaydetme
  Future<void> saveUserId(String userId) async {
    print('UserId kaydediliyor: $userId');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    print('UserId kaydedildi');
  }

  // User ID getirme
  Future<String?> getUserId() async {
    print('UserId alınıyor...');
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    print('Alınan userId: $userId');
    return userId;
  }

  // Token silme (logout için)
  Future<void> deleteToken() async {
    print('Token ve kullanıcı bilgileri siliniyor...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    print('Token ve kullanıcı bilgileri silindi');
  }

  // Token kontrolü
  Future<bool> hasToken() async {
    print('Token kontrolü yapılıyor...');
    final token = await getToken();
    final hasValidToken = token != null && token.isNotEmpty;
    print('Token var mı?: $hasValidToken');
    return hasValidToken;
  }
} 