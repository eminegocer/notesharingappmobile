import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import 'dart:math';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'pdf_view_screen.dart';
import '../config/api_config.dart';
import 'package:file_picker/file_picker.dart';

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
  List<dynamic> _schoolGroups = [];
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
      final groupChats = await _apiService.getUserGroups(token);
      final schoolGroups = await _apiService.getGroupChats(token);

      setState(() {
        _personalChats = personalChats;
        _groupChats = groupChats;
        _schoolGroups = schoolGroups;
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
      print('Yüklenen sohbet: \\${chat.messages.length} mesaj');
      print('Mesajlar: \\n${chat.messages.map((m) => m.content).toList()}');

      setState(() {
        _currentMessages = chat.messages.map((msg) => {
          'senderUsername': msg.senderUsername,
          'receiverUsername': chat.senderUsername == msg.senderUsername
              ? chat.receiverUsername
              : chat.senderUsername,
          'content': msg.content,
          'fileUrl': msg.fileUrl,
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
      print("_currentMessages: \\n");
      print(_currentMessages);
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
      print('Grup mesajları: \n$messages');
      // Mesajları ekranda beklenen formata dönüştür
      final formattedMessages = (messages as List).map((msg) => {
        'senderUsername': msg['senderUsername'] ?? '',
        'content': msg['content'] ?? '',
        'fileUrl': msg['fileUrl'],
        'createdAt': msg['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      }).toList();

      setState(() {
        _currentMessages = formattedMessages;
        _isChatLoading = false;
      });
      print('_currentMessages: \n');
      print(_currentMessages);
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
        // Oturum yoksa kullanıcıyı login ekranına yönlendir
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.')),
        );
        // TODO: Gerekirse Navigator.pushReplacement ile login ekranına yönlendirin
        return;
      }

      // Eğer _currentUsername zaten doluysa tekrar getCurrentUser çağırmaya gerek yok!
      if (_currentUsername == null) {
        final userData = await _apiService.getCurrentUser(token);
        if (userData == null || (userData['username'] == null && userData['userName'] == null)) {
          throw Exception('Kullanıcı bilgileri alınamadı');
        }
        setState(() {
          _currentUsername = userData['username'] ?? userData['userName'];
        });
      }

      if (_selectedUsername != null) {
        // Sohbet başlat
        final chatResponse = await _apiService.startChat(token, _selectedUsername!, _messageController.text);
        if (chatResponse['success'] == false) {
          throw Exception(chatResponse['message'] ?? 'Sohbet başlatılamadı');
        }

        // Mesajı gönder
        final messageResponse = await _apiService.sendMessage(token, _selectedUsername!, _messageController.text);
        if (messageResponse['success'] == false) {
          throw Exception(messageResponse['message'] ?? 'Mesaj gönderilemedi');
        }
        await _loadPersonalChat(_selectedUsername!);
      } else if (_selectedGroupId != null) {
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
      // Eğer hata oturumla ilgiliyse login ekranına yönlendirin
      if (e.toString().contains('Unauthorized') || e.toString().contains('Oturum')) {
        // TODO: Kullanıcıyı login ekranına yönlendirin
      }
    }
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final token = await _tokenService.getToken();
      if (token == null) return;

      try {
        // Dosyayı backend'e yükle
        final uploadResponse = await _apiService.uploadChatFile(
          token,
          await file.readAsBytes(),
          fileName,
        );
        final fileUrl = uploadResponse['fileUrl'] ?? uploadResponse['url'] ?? uploadResponse['path'];
        if (fileUrl != null) {
          // Sohbete dosya mesajı gönder
          String messageText = '[Dosya] $fileName';
          if (_selectedUsername != null) {
            await _apiService.sendMessage(token, _selectedUsername!, messageText, fileUrl: fileUrl);
            await _loadPersonalChat(_selectedUsername!);
          } else if (_selectedGroupId != null) {
            await _apiService.sendGroupMessage(token, _selectedGroupId!, messageText, _currentUsername!, fileUrl: fileUrl);
            await _loadGroupChat(_selectedGroupId!);
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya gönderilemedi: $e')),
        );
      }
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
                  ? (_groupChats.cast<Map>().firstWhere(
                        (g) => g['id'] == _selectedGroupId,
                        orElse: () => <String, dynamic>{},
                      )['groupName'] ??
                      _schoolGroups.cast<Map>().firstWhere(
                        (g) => g['id'] == _selectedGroupId,
                        orElse: () => <String, dynamic>{},
                      )['groupName'] ??
                      'SOHBETLER')
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
    final List<Map<String, dynamic>> categories = [
      {
        "title": "Kişisel Sohbetler",
        "icon": Icons.person,
        "desc": "1'e 1 özel konuşmalarınızı görün",
        "color": Colors.white,
        "chats": _personalChats,
        "isGroup": false,
      },
      {
        "title": "Grup Sohbetleri",
        "icon": Icons.groups,
        "desc": "Grup konuşmalarınızı görün",
        "color": Colors.white,
        "chats": _groupChats,
        "isGroup": true,
      },
      {
        "title": "Okul Toplulukları",
        "icon": Icons.school,
        "desc": "Okul toplulukları sohbetlerini görün",
        "color": Colors.white,
        "chats": _schoolGroups,
        "isGroup": true,
      },
    ];

    return Container(
      color: const Color(0xFFE6EEFF),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            for (final Map<String, dynamic> cat in categories)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GestureDetector(
                  onTap: () {
                    _showCategoryChatsModal(
                      context,
                      cat['title'] as String,
                      cat['chats'] as List,
                      cat['isGroup'] as bool,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cat['color'] as Color,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF6B7FD7).withOpacity(0.13),
                            radius: 22,
                            child: Icon(cat['icon'] as IconData, size: 24, color: const Color(0xFF6B7FD7)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat['title'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF222B45),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  cat['desc'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7FD7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Color(0xFFB0B0B0), size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_personalChats.isEmpty && _groupChats.isEmpty && _schoolGroups.isEmpty)
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  void _showCategoryChatsModal(BuildContext context, String title, List chats, bool isGroup) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SizedBox(
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: mainTitleColor),
                ),
              ),
              Expanded(
                child: chats.isEmpty
                    ? Center(child: Text('Hiç sohbet yok.', style: TextStyle(color: Colors.grey[600])))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: chats.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          return GestureDetector(
                            onTap: () {
                              if (isGroup) {
                                final groupId = chat['id'];
                                print('Seçilen grup ID: $groupId');
                                Navigator.pop(context);
                                _loadGroupChat(groupId);
                                setState(() {
                                  _selectedGroupId = groupId;
                                  _selectedUsername = null;
                                });
                              } else {
                                final username = chat is Chat ? chat.receiverUsername : (chat['receiverUsername'] ?? chat['username'] ?? '-');
                                Navigator.pop(context);
                                _loadPersonalChat(username);
                                setState(() {
                                  _selectedUsername = username;
                                  _selectedGroupId = null;
                                });
                              }
                            },
                            child: _buildChatCard(chat, isGroup),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatCard(dynamic chat, bool isGroup) {
    String title = '';
    String subtitle = '';
    IconData icon = isGroup ? Icons.group : Icons.person;
    Color iconBg = mainTitleColor.withOpacity(0.12);
    if (isGroup) {
      title = chat['groupName'] ?? chat['name'] ?? '-';
      subtitle = (chat['members']?.length?.toString() ?? chat['memberCount']?.toString() ?? '0') + ' üye';
      // Okul toplulukları için farklı ikonlar
      if ((title.toLowerCase().contains('bilgisayar') || title.toLowerCase().contains('yazılım'))) {
        icon = Icons.computer;
      } else if (title.toLowerCase().contains('elektrik')) {
        icon = Icons.electrical_services;
      } else if (title.toLowerCase().contains('makine')) {
        icon = Icons.precision_manufacturing;
      } else if (title.toLowerCase().contains('kimya')) {
        icon = Icons.science;
      } else if (title.toLowerCase().contains('matematik')) {
        icon = Icons.calculate;
      } else if (title.toLowerCase().contains('tıp')) {
        icon = Icons.local_hospital;
      } else if (title.toLowerCase().contains('hukuk')) {
        icon = Icons.gavel;
      } else if (title.toLowerCase().contains('edebiyat')) {
        icon = Icons.menu_book;
      } else if (title.toLowerCase().contains('fizik')) {
        icon = Icons.science;
      } else {
        icon = Icons.school;
      }
      iconBg = const Color(0xFF6B7FD7).withOpacity(0.13);
    } else {
      title = chat is Chat ? chat.receiverUsername : (chat['receiverUsername'] ?? chat['username'] ?? '-');
      subtitle = chat is Chat && chat.messages.isNotEmpty ? chat.messages.last.content : (chat['lastMessage'] ?? '');
      iconBg = const Color(0xFF6B7FD7).withOpacity(0.13);
    }
    return GestureDetector(
      onTap: () {
        if (isGroup) {
          final groupId = chat['id'];
          print('Seçilen grup ID: $groupId');
          _loadGroupChat(groupId);
          setState(() {
            _selectedGroupId = groupId;
            _selectedUsername = null;
          });
        } else {
          final username = chat is Chat ? chat.receiverUsername : (chat['receiverUsername'] ?? chat['username'] ?? '-');
          _loadPersonalChat(username);
          setState(() {
            _selectedUsername = username;
            _selectedGroupId = null;
          });
        }
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF6B7FD7), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isGroup
                ? CircleAvatar(
                    backgroundColor: iconBg,
                    child: Icon(icon, color: mainTitleColor, size: 22),
                    radius: 20,
                  )
                : CircleAvatar(
                    backgroundColor: iconBg,
                    child: Text(
                      title.isNotEmpty ? title[0].toUpperCase() : '?',
                      style: const TextStyle(color: Color(0xFF6B7FD7), fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    radius: 20,
                  ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: nameTextColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: subtitleTextColor, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _downloadAndSavePdf(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      return file.path;
    } else {
      throw Exception('PDF indirilemedi');
    }
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
                  final fileUrl = message['fileUrl'];
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
                          if (fileUrl != null && fileUrl.toString().isNotEmpty) ...[
                            GestureDetector(
                              onTap: () async {
                                try {
                                  final fullUrl = fileUrl.toString().startsWith('http')
                                      ? fileUrl
                                      : ApiConfig.baseUrl + fileUrl.toString();
                                  final pdfPath = await _downloadAndSavePdf(fullUrl);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PdfViewScreen(
                                        pdfPath: pdfPath,
                                        title: 'PDF Mesajı',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('PDF açılırken hata: $e')),
                                  );
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    getOriginalFileName(fileUrl.toString()),
                                    style: GoogleFonts.nunito(
                                      color: Colors.blue,
                                      fontSize: 15,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (message['content'] != null && message['content'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  message['content'],
                                  style: GoogleFonts.nunito(
                                    color: isMe ? Color(0xFF444444) : Color(0xFF444444),
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                          ] else ...[
                            Text(
                              message['content'],
                              style: GoogleFonts.nunito(
                                color: isMe ? Color(0xFF444444) : Color(0xFF444444),
                                fontSize: 15,
                              ),
                            ),
                          ],
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
              IconButton(
                icon: const Icon(Icons.attach_file, color: Color(0xFF6B7FD7)),
                onPressed: _pickAndSendFile,
              ),
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

  String getOriginalFileName(String fileUrl) {
    final parts = fileUrl.split('_');
    if (parts.length > 1) {
      return parts.sublist(1).join('_');
    }
    return fileUrl.split('/').last;
  }
} 