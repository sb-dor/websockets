import 'package:flutter/foundation.dart';
import 'package:websockets/src/features/authentication/model/user.dart';

@immutable
sealed class ChatEvent {
  const ChatEvent();
}

class Message extends ChatEvent {
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
    user: User.fromMap(map['user'] as Map<String, Object?>),
  );

  final int id;
  final String content;
  final DateTime createdAt;
  final User user;

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Message && id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Message{id: $id, user: ${user.name}, content: $content}';
}

class TypingMessage extends ChatEvent {
  const TypingMessage({required this.user, required this.typing});

  factory TypingMessage.fromJson(final Map<String, Object?> json) {
    return TypingMessage(user: User.fromMap(json), typing: json['typing'] as bool);
  }

  final User user;
  final bool typing;
}
