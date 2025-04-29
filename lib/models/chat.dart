class Chat {
  final String? id;
  final List<String> usersId;
  final String senderUsername;
  final String receiverUsername;
  final List<Message> messages;
  final DateTime createdAt;

  Chat({
    this.id,
    required this.usersId,
    required this.senderUsername,
    required this.receiverUsername,
    required this.messages,
    required this.createdAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['_id']?.toString(),
      usersId: (json['usersId'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      senderUsername: json['senderUsername'] as String? ?? '',
      receiverUsername: json['receiverUsername'] as String? ?? '',
      messages: (json['messages'] as List<dynamic>?)?.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class Message {
  final String? id;
  final String senderId;
  final String senderUsername;
  final String content;
  final String? fileUrl;
  final DateTime createdAt;

  Message({
    this.id,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    this.fileUrl,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id']?.toString(),
      senderId: json['senderId']?.toString() ?? '',
      senderUsername: json['senderUsername'] as String? ?? '',
      content: json['content'] as String? ?? '',
      fileUrl: json['fileUrl'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
} 