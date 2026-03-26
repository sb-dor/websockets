import 'package:flutter/foundation.dart';

@immutable
class Room {
  const Room({required this.id, required this.code, required this.name, required this.ownerId});

  factory Room.fromMap(Map<String, Object?> map) => Room(
    id: map['id'] as int,
    code: map['code'] as String,
    name: map['name'] as String,
    ownerId: map['owner_id'] as int,
  );

  final int id;
  final String code;
  final String name;
  final int ownerId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Room && id == other.id && code == other.code);

  @override
  int get hashCode => id.hashCode ^ code.hashCode;

  @override
  String toString() => 'Room{id: $id, code: $code, name: $name}';

  Room copyWith({int? id, String? code, String? name, int? ownerId}) => Room(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    ownerId: ownerId ?? this.ownerId,
  );

  Map<String, dynamic> toMap() => {'id': id, 'code': code, 'name': name, 'owner_id': ownerId};
}
