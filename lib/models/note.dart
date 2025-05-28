class Note {
  final String? noteId;
  final String title;
  final String content;
  final String category;
  final int page;
  final String? ownerId;
  final String ownerUsername;
  final DateTime createdAt;
  final String? pdfFilePath;
  final int? downloadCount;

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
    this.downloadCount,
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
    String parseId(dynamic id) {
      if (id == null) return '';
      if (id is String) return id;
      if (id is Map && id.containsKey('_id')) return id['_id'].toString();
      if (id is Map && id.containsKey('\u0000oid')) return id['\u0000oid'].toString();
      if (id is Map && id.containsKey('\u0000_id')) return id['\u0000_id'].toString();
      if (id is Map && id.containsKey('oid')) return id['oid'].toString();
      if (id is Map && id.containsKey('timestamp')) return '';
      return id.toString();
    }
    final parsedNoteId = parseId(json['noteId'] ?? json['_id'] ?? json['id']);
    print('Note.fromJson -> parsedNoteId: $parsedNoteId, json: $json');
    return Note(
      noteId: parsedNoteId,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category']?.toString() ?? 'Genel',
      page: json['page'] ?? 0,
      ownerId: parseId(json['ownerId']),
      ownerUsername: json['ownerUsername'] ?? 'Bilinmeyen Kullanıcı',
      createdAt: parseDateTime(json['createdAt']),
      pdfFilePath: json['pdfFilePath'],
      downloadCount: json['downloadCount'] is int
          ? json['downloadCount']
          : int.tryParse(json['downloadCount']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noteId': noteId,
      'title': title,
      'content': content,
      'category': category,
      'page': page,
      'ownerId': ownerId,
      'ownerUsername': ownerUsername,
      'pdfFilePath': pdfFilePath,
      'downloadCount': downloadCount,
    };
  }

  // ID'lerin timestamp değerlerini kolayca alabilmek için yardımcı metotlar
  String get noteIdTimestamp => noteId != null ? noteId! : '';
  String get ownerIdTimestamp => ownerId != null ? ownerId! : '';
} 