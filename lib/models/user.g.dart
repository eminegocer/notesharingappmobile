// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  userId: json['userId'] as String,
  userName: json['userName'] as String,
  email: json['email'] as String,
  visitedNotes:
      (json['visitedNotes'] as List<dynamic>?)
          ?.map((e) => VisitedNote.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  sharedNotes:
      (json['sharedNotes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  sharedNotesCount: (json['sharedNotesCount'] as num?)?.toInt() ?? 0,
  receivedNotes:
      (json['receivedNotes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  receivedNotesCount: (json['receivedNotesCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'userId': instance.userId,
  'userName': instance.userName,
  'email': instance.email,
  'visitedNotes': instance.visitedNotes,
  'sharedNotes': instance.sharedNotes,
  'sharedNotesCount': instance.sharedNotesCount,
  'receivedNotes': instance.receivedNotes,
  'receivedNotesCount': instance.receivedNotesCount,
};

VisitedNote _$VisitedNoteFromJson(Map<String, dynamic> json) => VisitedNote(
  noteId: json['noteId'] as String,
  title: json['title'] as String,
  category: json['category'] as String,
  author: json['ownerUsername'] as String,
  visitedAt: DateTime.parse(json['visitedAt'] as String),
);

Map<String, dynamic> _$VisitedNoteToJson(VisitedNote instance) =>
    <String, dynamic>{
      'noteId': instance.noteId,
      'title': instance.title,
      'category': instance.category,
      'ownerUsername': instance.author,
      'visitedAt': instance.visitedAt.toIso8601String(),
    };
