import 'package:websockets/src/features/authentication/model/user.dart';
import 'package:websockets/src/features/chat/models/chat_event.dart';
import 'package:websockets/src/features/lobby/models/room.dart';

// ---------------------------------------------------------------------------
// Common test fixtures shared across all test files.
// ---------------------------------------------------------------------------

const fakeUser = User(id: 1, name: 'John', email: 'john@example.com');
const fakeUser2 = User(id: 2, name: 'Jane', email: 'jane@example.com');

const fakeRoom = Room(id: 1, code: 'ABC123', name: 'Test Room', ownerId: 1);

Message fakeMessage({int id = 1, String content = 'Hello'}) => Message(
      id: id,
      content: content,
      createdAt: DateTime(2026, 3, 28),
      user: fakeUser,
    );

/// Pumps the Dart event queue [iterations] times.
/// Needed after calling controller methods that use async [handle()] internally.
Future<void> pump([int iterations = 5]) async {
  for (var i = 0; i < iterations; i++) {
    await Future.delayed(Duration.zero);
  }
}
