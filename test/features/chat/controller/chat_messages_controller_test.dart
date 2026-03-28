import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:websockets/src/features/chat/controller/chat_messages_controller.dart';

import '../../../fixtures.dart';
import '../../../mocks.dart';

void main() {
  late MockChatRepository mockRepo;
  late ChatMessagesController controller;

  setUp(() {
    mockRepo = MockChatRepository();
    controller = ChatMessagesController(repository: mockRepo);
  });

  tearDown(() => controller.dispose());

  group('ChatMessagesController', () {
    test('starts in idle state', () {
      expect(controller.state, isA<ChatMessages$IdleState>());
    });

    test('send() calls repository with correct arguments', () async {
      when(() => mockRepo.sendMessage(roomCode: 'ABC123', content: 'hello'))
          .thenAnswer((_) async {});

      controller.send(roomCode: 'ABC123', content: 'hello');
      await pump();

      verify(() => mockRepo.sendMessage(roomCode: 'ABC123', content: 'hello')).called(1);
    });

    test('send() transitions through sending → sent → idle', () async {
      final states = <ChatMessagesState>[];
      controller.addListener(() => states.add(controller.state));

      when(() => mockRepo.sendMessage(
                roomCode: any(named: 'roomCode'),
                content: any(named: 'content'),
              ))
          .thenAnswer((_) async {});

      controller.send(roomCode: 'ABC123', content: 'hello');
      await pump();

      expect(states, [
        isA<ChatMessages$SendingState>(),
        isA<ChatMessages$SentState>(),
        isA<ChatMessages$IdleState>(),
      ]);
    });

    test('send() ends in idle state after success', () async {
      when(() => mockRepo.sendMessage(
                roomCode: any(named: 'roomCode'),
                content: any(named: 'content'),
              ))
          .thenAnswer((_) async {});

      controller.send(roomCode: 'ABC123', content: 'hello');
      await pump();

      expect(controller.state, isA<ChatMessages$IdleState>());
    });

  });
}
