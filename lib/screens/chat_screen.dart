import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import 'dart:math';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();
  final _messageController = TextEditingController();
  bool _isLoading = true;
  List<Chat> _personalChats = [];
  List<dynamic> _groupChats = [];
  List<dynamic>? _currentMessages;
  String? _selectedUsername;
  String? _selectedGroupId;
  bool _isChatLoading = false;
  String? _currentUsername;

  // Pastel renk paleti
  static const List<Color> pastelColors = [
    Color(0xFFFFD3D8), // Pembe 
    Color(0xFFFFE680), // Sarı 
    Color(0xFFC3F7D5), // Yeşil 
    Color(0xFFCCE1FF), // Mavi 
    Color(0xFFFFD8A8), // Turuncu
    Color(0xFFFFF7B2), // Açık Sarı
    Color(0xFFCCE1FF), // Mavi (ali)
  ];
  static const Color personalChatColor = Color(0xFFCCE1FF); // Pastel mavi
  static const Color groupChatColor = Color(0xFFFFD8A8); 

  Color getPastelColor(String key) {
    final hash = key.codeUnits.fold(0, (prev, elem) => prev + elem);
    return pastelColors[hash % pastelColors.length];
  }

  @override
  void initState() {
    super.initState();
    _loadChats();
    _getCurrentUsername();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUsername() async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) return;

      final userData = await _apiService.getCurrentUser(token);
      setState(() {
        _currentUsername = userData['username'] ?? userData['userName'];
        print('Current username set to: $_currentUsername');
      });
    } catch (e) {
      print('Error getting current username: $e');
    }
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final personalChats = await _apiService.getPersonalChats(token);
      final groupChats = await _apiService.getGroupChats(token);

      setState(() {
        _personalChats = personalChats;
        _groupChats = groupChats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPersonalChat(String username) async {
    setState(() {
      _isChatLoading = true;
      _selectedUsername = username;
      _selectedGroupId = null;
      _currentMessages = null;
    });

    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Oturum bilgisi bulunamadı');
      }

      final chat = await _apiService.getChatHistory(token, username);
      print('Yüklenen sohbet: ${chat.messages.length} mesaj');

      setState(() {
        _currentMessages = chat.messages.map((msg) => {
          'senderUsername': msg.senderUsername,
          'receiverUsername': chat.senderUsername == msg.senderUsername
              ? chat.receiverUsername
              : chat.senderUsername,
          'content': msg.content,
          'createdAt': msg.createdAt.toIso8601String(),
        }).toList();
        _isChatLoading = false;
      });

      // Mesajları tarihe göre sırala
      _currentMessages?.sort((a, b) {
        final dateA = DateTime.parse(a['createdAt']);
        final dateB = DateTime.parse(b['createdAt']);
        return dateA.compareTo(dateB);
      });
    } catch (e) {
      print('Sohbet yüklenirken hata: $e');
      setState(() => _isChatLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sohbet yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _loadGroupChat(String groupId) async {
    setState(() {
      _isChatLoading = true;
      _selectedGroupId = groupId;
      _selectedUsername = null;
      _currentMessages = null;
    });

    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Oturum bilgisi bulunamadı');
      }

      final messages = await _apiService.getGroupMessages(token, groupId);
      setState(() {
        _currentMessages = messages;
        _isChatLoading = false;
      });
    } catch (e) {
      setState(() => _isChatLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Grup mesajları yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Oturum bilgisi bulunamadı');
      }

      // Önce mevcut kullanıcı bilgilerini al
      final userData = await _apiService.getCurrentUser(token);
      if (userData == null || (userData['username'] == null && userData['userName'] == null)) {
        throw Exception('Kullanıcı bilgileri alınamadı');
      }

      setState(() {
        _currentUsername = userData['username'] ?? userData['userName'];
      });

      if (_selectedUsername != null) {
        // Önce sohbeti başlat
        final chatResponse = await _apiService.startChat(token, _selectedUsername!, _messageController.text);
        if (chatResponse['success'] == false) {
          throw Exception(chatResponse['message'] ?? 'Sohbet başlatılamadı');
        }

        // Sonra mesajı gönder
        final messageResponse = await _apiService.sendMessage(token, _selectedUsername!, _messageController.text);
        if (messageResponse['success'] == false) {
          throw Exception(messageResponse['message'] ?? 'Mesaj gönderilemedi');
        }
        
        // Mesaj gönderildikten sonra sohbeti yenile
        await _loadPersonalChat(_selectedUsername!);
      } else if (_selectedGroupId != null) {
        // Grup mesajı gönderme
        final messageResponse = await _apiService.sendGroupMessage(token, _selectedGroupId!, _messageController.text, _currentUsername!);
        if (messageResponse['success'] == false) {
          throw Exception(messageResponse['message'] ?? 'Grup mesajı gönderilemedi');
        }
        await _loadGroupChat(_selectedGroupId!);
      }

      setState(() {
        _messageController.clear();
      });
    } catch (e) {
      print('Mesaj gönderme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesaj gönderilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          _selectedUsername != null 
              ? _selectedUsername! 
              : _selectedGroupId != null 
                  ? _groupChats.firstWhere((g) => g['id'] == _selectedGroupId)['groupName'] 
                  : 'SOHBETLER',
          style: GoogleFonts.poppins(
            color: const Color(0xFF6B7FD7),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: _selectedUsername != null || _selectedGroupId != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7FD7)),
              onPressed: () {
                setState(() {
                  _selectedUsername = null;
                  _selectedGroupId = null;
                  _currentMessages = null;
                });
              },
            )
          : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedUsername != null || _selectedGroupId != null
              ? _buildChatView()
              : _buildChatList(),
    );
  }

  Widget _buildChatList() {
    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView(
        children: [
          if (_personalChats.isNotEmpty)
            _buildSection(
              title: 'Kişisel Sohbetler',
              chats: _personalChats,
              isGroup: false,
            ),
          if (_groupChats.isNotEmpty)
            _buildSection(
              title: 'Grup Sohbetleri',
              chats: _groupChats,
              isGroup: true,
            ),
          if (_personalChats.isEmpty && _groupChats.isEmpty)
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    if (_isChatLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: _currentMessages == null || _currentMessages!.isEmpty
            ? Center(
                child: Text(
                  'Henüz mesaj yok',
                  style: GoogleFonts.nunito(color: Colors.grey[600], fontSize: 16),
                ),
              )
            : ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: _currentMessages!.length,
                itemBuilder: (context, index) {
                  final message = _currentMessages![_currentMessages!.length - 1 - index];
                  final isMe = message['senderUsername'] == _currentUsername;
                  final color = getPastelColor(message['senderUsername'] ?? '');
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: isMe ? Radius.circular(18) : Radius.circular(0),
                          bottomRight: isMe ? Radius.circular(0) : Radius.circular(18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.08),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(
                              message['senderUsername'],
                              style: GoogleFonts.rubik(
                                color: Colors.grey[500],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Text(
                            message['content'],
                            style: GoogleFonts.nunito(
                              color: isMe ? Color(0xFF444444) : Color(0xFF444444),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: GoogleFonts.nunito(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Mesajınızı yazın...',
                    hintStyle: GoogleFonts.nunito(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF6B7FD7)),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<dynamic> chats,
    required bool isGroup,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8A98BA),
              letterSpacing: 1.2,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            if (isGroup) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: groupChatColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: groupChatColor.withOpacity(0.10),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: groupChatColor,
                    child: Icon(Icons.group, color: Colors.white),
                  ),
                  title: Text(
                    chat['groupName'] ?? 'Unnamed Group',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF3A3A3A),
                    ),
                  ),
                  subtitle: Text(
                    '${chat['memberCount'] ?? 0} members',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      color: Color(0xFF6B7FD7),
                      fontSize: 13,
                    ),
                  ),
                  onTap: () => _loadGroupChat(chat['id']),
                ),
              );
            } else {
              final personalChat = chat as Chat;
              final lastMessage = personalChat.messages.isNotEmpty 
                ? personalChat.messages.last.content 
                : 'No messages yet';
              final isMe = personalChat.messages.isNotEmpty && 
                personalChat.messages.last.senderUsername == _currentUsername;
              final color = getPastelColor(personalChat.receiverUsername);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: personalChatColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: personalChatColor.withOpacity(0.10),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: personalChatColor,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    personalChat.receiverUsername,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF3A3A3A),
                    ),
                  ),
                  subtitle: Text(
                    lastMessage,
                    style: GoogleFonts.nunito(
                      fontStyle: isMe ? FontStyle.italic : FontStyle.normal,
                      color: Color(0xFF6B7FD7),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _loadPersonalChat(personalChat.receiverUsername),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz Sohbet Yok',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni bir sohbet başlatmak için\nbir kullanıcı veya gruba katılın',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 