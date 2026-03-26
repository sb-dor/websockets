import 'package:flutter/foundation.dart';

@immutable
class MessageUser {
  const MessageUser({required this.id, required this.name});

  factory MessageUser.fromMap(Map<String, Object?> map) =>
      MessageUser(id: map['id'] as int, name: map['name'] as String);

  final int id;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MessageUser && id == other.id);

  @override
  int get hashCode => id.hashCode;
}

@immutable
class Message {
  const Message({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.user,
  });

  factory Message.fromMap(Map<String, Object?> map) => Message(
    id: map['id'] as int,
    content: map['content'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
    user: MessageUser.fromMap(map['user'] as Map<String, Object?>),
  );

  final int id;
  final String content;
  final DateTime createdAt;
  final MessageUser user;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Message && id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Message{id: $id, user: ${user.name}, content: $content}';
}
