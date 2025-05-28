import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String userId;
  final String userName;
  final String email;
  final List<VisitedNote> visitedNotes;
  final List<String> sharedNotes;
  final int sharedNotesCount;
  final List<String> receivedNotes;
  final int receivedNotesCount;

  User({
    required this.userId,
    required this.userName,
    required this.email,
    this.visitedNotes = const [],
    this.sharedNotes = const [],
    this.sharedNotesCount = 0,
    this.receivedNotes = const [],
    this.receivedNotesCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class VisitedNote {
  final String noteId;
  final String title;
  final String category;
  @JsonKey(name: 'ownerUsername')
  final String author;
  @JsonKey(name: 'visitedAt')
  final DateTime visitedAt;

  VisitedNote({
    required this.noteId,
    required this.title,
    required this.category,
    required this.author,
    required this.visitedAt,
  });

  factory VisitedNote.fromJson(Map<String, dynamic> json) => _$VisitedNoteFromJson(json);
  Map<String, dynamic> toJson() => _$VisitedNoteToJson(this);
} 