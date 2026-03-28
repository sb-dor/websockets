import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:websockets/src/features/chat/controller/chat_controller.dart';
import 'package:websockets/src/features/chat/models/chat_event.dart';

import '../../../fixtures.dart';
import '../../../mocks.dart';

void main() {
  late MockChatRepository mockRepo;
  late StreamController<ChatEvent> streamCtrl;
  late ChatController controller;

  setUp(() {
    mockRepo = MockChatRepository();
    streamCtrl = StreamController<ChatEvent>.broadcast();
    controller = ChatController(
      repository: mockRepo,
      streamMessages: streamCtrl.stream,
      room: fakeRoom,
    );
  });

  tearDown(() {
    controller.dispose();
    streamCtrl.close();
  });

  group('ChatController', () {
    test('starts in initial state', () {
      expect(controller.state, isA<Chat$InitialState>());
    });

    test('connect() transitions to connected state', () async {
      when(() => mockRepo.getHistory(roomCode: any(named: 'roomCode')))
          .thenAnswer((_) async => []);

      controller.connect();
      await pump();

      expect(controller.state, isA<Chat$ConnectedState>());
    });

    test('connect() loads history into state', () async {
      final messages = [fakeMessage(id: 1), fakeMessage(id: 2)];
      when(() => mockRepo.getHistory(roomCode: 'ABC123'))
          .thenAnswer((_) async => messages);

      controller.connect();
      await pump();

      final state = controller.state as Chat$ConnectedState;
      expect(state.messages, messages);
      expect(state.room, fakeRoom);
    });

    test('incoming Message is appended to messages', () async {
      when(() => mockRepo.getHistory(roomCode: 'ABC123'))
          .thenAnswer((_) async => []);

      controller.connect();
      await pump();

      final incoming = fakeMessage(id: 99, content: 'world');
      streamCtrl.add(incoming);
      await pump();

      final state = controller.state as Chat$ConnectedState;
      expect(state.messages, contains(incoming));
    });

    test('multiple incoming messages are appended in order', () async {
      when(() => mockRepo.getHistory(roomCode: 'ABC123'))
          .thenAnswer((_) async => []);

      controller.connect();
      await pump();

      streamCtrl
        ..add(fakeMessage(id: 1, content: 'first'))
        ..add(fakeMessage(id: 2, content: 'second'));
      await pump();

      final state = controller.state as Chat$ConnectedState;
      expect(state.messages.map((m) => m.id), containsAllInOrder([1, 2]));
    });

    test('TypingMessage events are ignored — do not change messages', () async {
      when(() => mockRepo.getHistory(roomCode: 'ABC123'))
          .thenAnswer((_) async => []);

      controller.connect();
      await pump();

      streamCtrl.add(const TypingMessage(user: fakeUser, typing: true));
      await pump();

      final state = controller.state as Chat$ConnectedState;
      expect(state.messages, isEmpty);
    });
  });
}
