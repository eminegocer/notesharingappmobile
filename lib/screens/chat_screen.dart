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

  // Modern kart ve renk şeması
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color cardShadow = Color(0x11000000);
  static const Color screenBackground = Color(0xFFF5F6FA);
  static const Color mainTitleColor = Color(0xFF6B7FD7);
  static const Color nameTextColor = Color(0xFF222222);
  static const Color subtitleTextColor = Color(0xFF868686);

  // Gri tonları güncellendi
  static const List<Color> grayColors = [
    Color(0xFFF8F9FA), // Çok açık gri
    Color(0xFFF1F3F5), // Açık gri
    Color(0xFFE9ECEF), // Orta gri
    Color(0xFFDEE2E6), // Koyu gri
    Color(0xFFCED4DA), // En koyu gri
  ];

  static const Color personalChatColor = Color(0xFFF1F3F5); // Kişisel sohbet rengi
  static const Color groupChatColor = Color(0xFFE9ECEF); // Grup sohbet rengi
  static const Color schoolChatColor = Color(0xFFDEE2E6); // Okul topluluğu rengi

  Color getGrayColor(String key) {
    final hash = key.codeUnits.fold(0, (prev, elem) => prev + elem);
    return grayColors[hash % grayColors.length];
  }

  // Kategori durumlarını tutmak için
  bool _isPersonalChatsExpanded = true;
  bool _isGroupChatsExpanded = true;
  bool _isSchoolChatsExpanded = true;

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
      backgroundColor: screenBackground,
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
            color: mainTitleColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: mainTitleColor),
            onPressed: _showUserSearchDialog,
          ),
        ],
        leading: _selectedUsername != null || _selectedGroupId != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: mainTitleColor),
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
          _buildCollapsibleSection(
            title: 'Kişisel Sohbetler',
            isExpanded: _isPersonalChatsExpanded,
            onToggle: () => setState(() => _isPersonalChatsExpanded = !_isPersonalChatsExpanded),
            chats: _personalChats,
            isGroup: false,
            color: personalChatColor,
          ),
          _buildCollapsibleSection(
            title: 'Grup Sohbetleri',
            isExpanded: _isGroupChatsExpanded,
            onToggle: () => setState(() => _isGroupChatsExpanded = !_isGroupChatsExpanded),
            chats: _groupChats.where((g) => g['type'] != 'school').toList(),
            isGroup: true,
            color: groupChatColor,
          ),
          _buildCollapsibleSection(
            title: 'Okul Toplulukları',
            isExpanded: _isSchoolChatsExpanded,
            onToggle: () => setState(() => _isSchoolChatsExpanded = !_isSchoolChatsExpanded),
            chats: _groupChats.where((g) => g['type'] == 'school').toList(),
            isGroup: true,
            color: schoolChatColor,
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
                  final color = getGrayColor(message['senderUsername'] ?? '');
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

  Widget _buildCollapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<dynamic> chats,
    required bool isGroup,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: mainTitleColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: mainTitleColor,
                    letterSpacing: 0.5,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: mainTitleColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              if (isGroup) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: cardShadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: mainTitleColor.withOpacity(0.15),
                      child: Icon(Icons.group, color: mainTitleColor, size: 18),
                    ),
                    title: Text(
                      chat['groupName'] ?? 'Unnamed Group',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: nameTextColor,
                      ),
                    ),
                    subtitle: Text(
                      '${chat['memberCount'] ?? 0} üye',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: subtitleTextColor,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => _loadGroupChat(chat['id']),
                  ),
                );
              } else {
                final personalChat = chat as Chat;
                final lastMessage = personalChat.messages.isNotEmpty 
                  ? personalChat.messages.last.content 
                  : 'Henüz mesaj yok';
                final isMe = personalChat.messages.isNotEmpty && 
                  personalChat.messages.last.senderUsername == _currentUsername;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: cardShadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: mainTitleColor.withOpacity(0.15),
                      child: Icon(Icons.person, color: mainTitleColor, size: 18),
                    ),
                    title: Text(
                      personalChat.receiverUsername,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: nameTextColor,
                      ),
                    ),
                    subtitle: Text(
                      lastMessage,
                      style: GoogleFonts.nunito(
                        fontStyle: isMe ? FontStyle.italic : FontStyle.normal,
                        color: subtitleTextColor,
                        fontSize: 12,
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

  void _showUserSearchDialog() {
    bool dialogOpen = true;
    final TextEditingController _searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        String searchTerm = '';
        List<String> userSuggestions = [];
        List<Map<String, dynamic>> groupSuggestions = [];
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _onSearchChanged(String value) async {
              if (!dialogOpen) return;
              setState(() {
                searchTerm = value;
                isLoading = true;
              });
              if (value.length < 2) {
                if (!dialogOpen) return;
                setState(() {
                  userSuggestions = [];
                  groupSuggestions = [];
                  isLoading = false;
                });
                return;
              }
              final token = await _tokenService.getToken();
              final userResults = await _apiService.searchUsers(token!, value);
              final groupResults = await _apiService.searchGroups(token, value);
              print('Kullanıcı arama sonuçları: $userResults');
              print('Grup arama sonuçları: $groupResults');
              if (!dialogOpen) return;
              setState(() {
                userSuggestions = userResults;
                groupSuggestions = groupResults;
                isLoading = false;
              });
            };

            return WillPopScope(
              onWillPop: () async {
                dialogOpen = false;
                return true;
              },
              child: AlertDialog(
                backgroundColor: const Color(0xFFF5F6FA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text(
                  'Kullanıcı veya Grup Ara',
                  style: TextStyle(
                    color: Color(0xFF6B7FD7),
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 1.1,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, color: Color(0xFF6B7FD7)),
                            hintText: 'Grup adı veya kişi adı girin',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: TextStyle(fontSize: 16, color: Color(0xFF3A3A3A)),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isLoading)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7FD7))),
                        ),
                      if (!isLoading && userSuggestions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Kişiler', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B7FD7))),
                          ),
                        ),
                      if (!isLoading && userSuggestions.isNotEmpty)
                        ...userSuggestions.map((s) => Card(
                          color: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(0xFF6B7FD7).withOpacity(0.15),
                              child: Text(
                                s.isNotEmpty ? s[0].toUpperCase() : '?',
                                style: TextStyle(color: Color(0xFF6B7FD7), fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              s,
                              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3A3A3A)),
                            ),
                            hoverColor: Color(0xFF6B7FD7).withOpacity(0.08),
                            onTap: () async {
                              dialogOpen = false;
                              Navigator.of(context).pop();
                              await _startChatWithUser(s);
                            },
                          ),
                        )),
                      if (!isLoading && groupSuggestions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Gruplar', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B7FD7))),
                          ),
                        ),
                      if (!isLoading && groupSuggestions.isNotEmpty)
                        ...groupSuggestions.map((g) => Card(
                          color: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(0xFF6B7FD7).withOpacity(0.15),
                              child: Icon(Icons.group, color: Color(0xFF6B7FD7)),
                            ),
                            title: Text(
                              g['groupName'] ?? '-',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3A3A3A)),
                            ),
                            subtitle: Text(g['schoolName'] ?? ''),
                            hoverColor: Color(0xFF6B7FD7).withOpacity(0.08),
                            onTap: () async {
                              dialogOpen = false;
                              Navigator.of(context).pop();
                              // Grup sohbetine yönlendirme fonksiyonu eklemeniz gerekir
                              await _loadGroupChat(g['id']);
                              setState(() {
                                _selectedGroupId = g['id'];
                                _selectedUsername = null;
                              });
                            },
                          ),
                        )),
                      if (!isLoading && userSuggestions.isEmpty && groupSuggestions.isEmpty && searchTerm.length >= 2)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Sonuç bulunamadı.', style: TextStyle(color: Colors.grey)),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      dialogOpen = false;
    });
  }

  Future<void> _startChatWithUser(String username) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) throw Exception('Oturum bulunamadı');
      final response = await _apiService.addChat(token, username);
      if (response['success'] == true || response['success'] == null) {
        // Sohbeti yükle ve ekrana getir
        await _loadPersonalChat(username);
        setState(() {
          _selectedUsername = username;
          _selectedGroupId = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Sohbet başlatılamadı')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sohbet başlatılırken hata: $e')),
      );
    }
  }
} 