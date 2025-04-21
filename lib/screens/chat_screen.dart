import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _apiService = ApiService();
  final _tokenService = TokenService();
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  List<String> _searchResults = [];
  Chat? _currentChat;
  String? _selectedUser;

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Oturum bilgisi bulunamadı');
      }

      final results = await _apiService.searchUsers(token, query);
      setState(() => _searchResults = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanıcı araması başarısız: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadChat(String username) async {
    setState(() {
      _isLoading = true;
      _selectedUser = username;
      _searchResults = [];
      _searchController.clear();
    });

    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Oturum bilgisi bulunamadı');
      }

      final chat = await _apiService.getChatView(token, username);
      setState(() {
        _currentChat = chat;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sohbet yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedUser == null) return;

    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Oturum bilgisi bulunamadı');
      }

      // TODO: Implement send message functionality
      _messageController.clear();
      await _loadChat(_selectedUser!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesaj gönderilemedi: $e'),
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
          'SOHBETLER',
          style: GoogleFonts.poppins(
            color: const Color(0xFF6B7FD7),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Column(
        children: [
          // Kullanıcı arama alanı
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                hintText: 'Kullanıcı ara...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7FD7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          // Arama sonuçları
          if (_searchResults.isNotEmpty)
            Container(
              color: Colors.white,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final username = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6B7FD7),
                      child: Text(
                        username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(username),
                    onTap: () => _loadChat(username),
                  );
                },
              ),
            ),
          // Sohbet alanı
          if (_selectedUser != null && !_isLoading)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Seçili kullanıcı bilgisi
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF6B7FD7),
                            child: Text(
                              _selectedUser![0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedUser!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Mesaj listesi
                    Expanded(
                      child: _currentChat?.messages.isEmpty ?? true
                          ? Center(
                              child: Text(
                                'Henüz mesaj yok',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : ListView.builder(
                              reverse: true,
                              itemCount: _currentChat!.messages.length,
                              itemBuilder: (context, index) {
                                final message = _currentChat!.messages[index];
                                final isMe = message.senderUsername == _currentChat!.senderUsername;

                                return Align(
                                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isMe ? const Color(0xFF6B7FD7) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (message.fileUrl != null)
                                          IconButton(
                                            icon: const Icon(Icons.attachment),
                                            onPressed: () {
                                              // TODO: Implement file download
                                            },
                                          ),
                                        Text(
                                          message.content,
                                          style: TextStyle(
                                            color: isMe ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    // Mesaj gönderme alanı
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file),
                            onPressed: () {
                              // TODO: Implement file attachment
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Mesajınızı yazın...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            color: const Color(0xFF6B7FD7),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7FD7)),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 