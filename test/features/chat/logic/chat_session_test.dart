import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:websockets/src/features/chat/logic/chat_session.dart';
import 'package:websockets/src/features/chat/models/chat_event.dart';

import '../../../mocks.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [ChannelReadEvent] with the given [data] map using the
/// library-internal factory (marked @internal but accessible from tests).
// ignore: invalid_use_of_internal_member
ChannelReadEvent _makeEvent(String name, MockPresenceChannel channel, Map<String, dynamic> data) =>
    // ignore: invalid_use_of_internal_member
    ChannelReadEvent.internalCreate(name: name, channel: channel, data: data);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    // mocktail requires a registered fallback for any() on complex generic types
    registerFallbackValue(FakeAuthDelegate());
  });

  late MockPusherChannelsClient mockChannelsClient;
  late MockPresenceChannel mockChannel;
  late MockAuthDelegate mockAuthDelegate;
  late FakePusherClient fakePusherClient;

  late StreamController<ChannelReadEvent> sendStreamCtrl;
  late StreamController<ChannelReadEvent> typingStreamCtrl;

  late ChatSession session;

  setUp(() {
    mockChannelsClient = MockPusherChannelsClient();
    mockChannel = MockPresenceChannel();
    mockAuthDelegate = MockAuthDelegate();
    fakePusherClient = FakePusherClient(
      client: mockChannelsClient,
      authDelegate: mockAuthDelegate,
    );

    sendStreamCtrl = StreamController<ChannelReadEvent>.broadcast();
    typingStreamCtrl = StreamController<ChannelReadEvent>.broadcast();

    // presenceChannel(...) returns our mock channel
    when(
      () => mockChannelsClient.presenceChannel(
        any(),
        authorizationDelegate: any(named: 'authorizationDelegate'),
      ),
    ).thenReturn(mockChannel);

    // name is used by ChannelReadEvent.internalCreate to build the rootObject
    when(() => mockChannel.name).thenReturn('presence-room.ABC123');

    // subscribe() does nothing in the mock
    when(() => mockChannel.subscribe()).thenReturn(null);

    // bind() returns a controlled stream per event name
    when(() => mockChannel.bind('message.sent')).thenAnswer((_) => sendStreamCtrl.stream);
    when(() => mockChannel.bind('message.typing')).thenAnswer((_) => typingStreamCtrl.stream);

    // unsubscribe() does nothing
    when(() => mockChannel.unsubscribe()).thenReturn(null);

    session = ChatSession(pusherClient: fakePusherClient, roomCode: 'ABC123')..subscribe();
  });

  tearDown(() {
    session.dispose();
    sendStreamCtrl.close();
    typingStreamCtrl.close();
  });

  group('ChatSession', () {
    test('calls subscribe() on the presence channel', () {
      verify(() => mockChannel.subscribe()).called(1);
    });

    test('subscribes to presence-room.<code> channel', () {
      verify(
        () => mockChannelsClient.presenceChannel(
          'presence-room.ABC123',
          authorizationDelegate: any(named: 'authorizationDelegate'),
        ),
      ).called(1);
    });

    test('emits Message when message.sent fires', () async {
      final future = expectLater(
        session.events,
        emits(
          isA<Message>().having((m) => m.id, 'id', 42).having((m) => m.content, 'content', 'hello'),
        ),
      );
      sendStreamCtrl.add(
        _makeEvent('message.sent', mockChannel, {
          'id': 42,
          'content': 'hello',
          'created_at': '2026-03-28T10:00:00.000Z',
          'user': {'id': 1, 'name': 'John', 'email': 'john@example.com'},
        }),
      );
      await future;
    });

    test('emits TypingMessage when message.typing fires with typing=true', () async {
      final future = expectLater(
        session.events,
        emits(
          isA<TypingMessage>()
              .having((t) => t.typing, 'typing', true)
              .having((t) => t.user.name, 'user.name', 'Jane'),
        ),
      );
      typingStreamCtrl.add(
        _makeEvent('message.typing', mockChannel, {
          'id': 2,
          'name': 'Jane',
          'email': 'jane@example.com',
          'typing': true,
        }),
      );
      await future;
    });

    test('emits TypingMessage with typing=false when user stops typing', () async {
      final future = expectLater(
        session.events,
        emits(isA<TypingMessage>().having((t) => t.typing, 'typing', false)),
      );
      typingStreamCtrl.add(
        _makeEvent('message.typing', mockChannel, {
          'id': 2,
          'name': 'Jane',
          'email': 'jane@example.com',
          'typing': false,
        }),
      );
      await future;
    });

    test('events stream is closed after dispose()', () async {
      session.dispose();
      expect(session.events.isEmpty, completion(true));
    });

    test('unsubscribes the channel on dispose()', () {
      session.dispose();
      verify(() => mockChannel.unsubscribe()).called(1);
    });

    test('does nothing if subscribe() is called after dispose()', () {
      session.dispose();
      // Reset call count recorded during setUp so we can assert no new calls
      clearInteractions(mockChannel);
      expect(() => session.subscribe(), returnsNormally);
      verifyNever(() => mockChannel.subscribe());
    });
  });
}
