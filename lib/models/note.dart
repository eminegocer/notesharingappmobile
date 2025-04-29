class Note {
  final Map<String, dynamic>? noteId;
  final String title;
  final String content;
  final String category;
  final int page;
  final Map<String, dynamic>? ownerId;
  final String ownerUsername;
  final DateTime createdAt;
  final String? pdfFilePath;

  Note({
    this.noteId,
    required this.title,
    required this.content,
    required this.category,
    required this.page,
    this.ownerId,
    required this.ownerUsername,
    required this.createdAt,
    this.pdfFilePath,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    // DateTime parse helper
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Note(
      noteId: json['noteId'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category']?.toString() ?? 'Genel',
      page: json['page'] ?? 0,
      ownerId: json['ownerId'],
      ownerUsername: json['ownerUsername'] ?? 'Bilinmeyen Kullanıcı',
      createdAt: parseDateTime(json['createdAt']),
      pdfFilePath: json['pdfFilePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'page': page,
      'ownerUsername': ownerUsername,
    };
  }

  // ID'lerin timestamp değerlerini kolayca alabilmek için yardımcı metotlar
  String get noteIdTimestamp => noteId != null ? noteId!['timestamp'].toString() : '';
  String get ownerIdTimestamp => ownerId != null ? ownerId!['timestamp'].toString() : '';
} 