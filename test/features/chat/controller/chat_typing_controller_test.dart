import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:websockets/src/features/chat/controller/chat_typing_controller.dart';
import 'package:websockets/src/features/chat/models/chat_event.dart';

import '../../../fixtures.dart';
import '../../../mocks.dart';

void main() {
  late MockChatRepository mockRepo;
  late StreamController<ChatEvent> streamCtrl;
  late ChatTypingController controller;

  setUp(() {
    mockRepo = MockChatRepository();
    streamCtrl = StreamController<ChatEvent>.broadcast();
    controller = ChatTypingController(
      chatEvents: streamCtrl.stream,
      chatRepository: mockRepo,
      room: fakeRoom,
    );
  });

  tearDown(() {
    controller.dispose();
    streamCtrl.close();
  });

  group('ChatTypingController', () {
    test('starts in idle state', () {
      expect(controller.state, isA<ChatTypingState$Idle>());
    });

    test('TypingMessage(typing=true) → state becomes processing', () async {
      controller.connect();
      await pump();

      streamCtrl.add(const TypingMessage(user: fakeUser, typing: true));
      await pump();

      expect(controller.state, isA<ChatTypingState$Processing>());
      final state = controller.state as ChatTypingState$Processing;
      expect(state.typingMessages.first.user.id, fakeUser.id);
    });

    test('TypingMessage(typing=false) → state returns to idle', () async {
      controller.connect();
      await pump();

      streamCtrl.add(const TypingMessage(user: fakeUser, typing: true));
      await pump();
      streamCtrl.add(const TypingMessage(user: fakeUser, typing: false));
      await pump();

      expect(controller.state, isA<ChatTypingState$Idle>());
    });

    test('multiple users typing are all tracked in state', () async {
      controller.connect();
      await pump();

      streamCtrl
        ..add(const TypingMessage(user: fakeUser, typing: true))
        ..add(const TypingMessage(user: fakeUser2, typing: true));
      await pump();

      final state = controller.state as ChatTypingState$Processing;
      expect(state.typingMessages.length, 2);
      expect(
        state.typingMessages.map((t) => t.user.id),
        containsAll([fakeUser.id, fakeUser2.id]),
      );
    });

    test('same user typing twice is not duplicated in list', () async {
      controller.connect();
      await pump();

      streamCtrl
        ..add(const TypingMessage(user: fakeUser, typing: true))
        ..add(const TypingMessage(user: fakeUser, typing: true));
      await pump();

      final state = controller.state as ChatTypingState$Processing;
      expect(state.typingMessages.length, 1);
    });

    test('one user stopping typing does not remove others', () async {
      controller.connect();
      await pump();

      streamCtrl
        ..add(const TypingMessage(user: fakeUser, typing: true))
        ..add(const TypingMessage(user: fakeUser2, typing: true));
      await pump();
      streamCtrl.add(const TypingMessage(user: fakeUser, typing: false));
      await pump();

      final state = controller.state as ChatTypingState$Processing;
      expect(state.typingMessages.length, 1);
      expect(state.typingMessages.first.user.id, fakeUser2.id);
    });

    test('Message events are ignored — typing state unchanged', () async {
      controller.connect();
      await pump();

      streamCtrl.add(fakeMessage());
      await pump();

      expect(controller.state, isA<ChatTypingState$Idle>());
    });

    test('typing() calls repository with room code', () async {
      when(() => mockRepo.typing(roomCode: 'ABC123')).thenAnswer((_) async {});

      controller.typing();
      await pump();

      verify(() => mockRepo.typing(roomCode: 'ABC123')).called(1);
    });

    test('stopTyping() calls repository with room code', () async {
      when(() => mockRepo.stopTyping(roomCode: 'ABC123')).thenAnswer((_) async {});

      controller.stopTyping();
      await pump();

      verify(() => mockRepo.stopTyping(roomCode: 'ABC123')).called(1);
    });
  });
}
