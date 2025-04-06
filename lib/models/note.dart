class Note {
  final String noteId;  // timestamp değerini kullanacağız
  final int page;
  final String ownerId;  // timestamp değerini kullanacağız
  final String ownerUsername;
  final String title;
  final String content;
  final String category;
  final String pdfFilePath;
  final DateTime createdAt;

  Note({
    required this.noteId,
    required this.page,
    required this.ownerId,
    required this.ownerUsername,
    required this.title,
    required this.content,
    required this.category,
    required this.pdfFilePath,
    required this.createdAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      noteId: (json['noteId'] as Map<String, dynamic>)['timestamp'].toString(),
      page: json['page'] as int? ?? 0,
      ownerId: (json['ownerId'] as Map<String, dynamic>)['timestamp'].toString(),
      ownerUsername: json['ownerUsername'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? '',
      pdfFilePath: json['pdfFilePath'] as String? ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noteId': {'timestamp': int.parse(noteId)},
      'page': page,
      'ownerId': {'timestamp': int.parse(ownerId)},
      'ownerUsername': ownerUsername,
      'title': title,
      'content': content,
      'category': category,
      'pdfFilePath': pdfFilePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 