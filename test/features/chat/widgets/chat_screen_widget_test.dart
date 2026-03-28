import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:websockets/src/features/authentication/controller/authentication_controller.dart';
import 'package:websockets/src/features/authentication/data/authentication_repository.dart';
import 'package:websockets/src/features/authentication/widget/authentication_scope.dart';
import 'package:websockets/src/features/chat/widgets/chat_config_widget.dart';
import 'package:websockets/src/features/initialization/models/dependencies.dart';

import '../../../fixtures.dart';
import '../../../mocks.dart';

Widget _buildTree(FakeDependencies deps) => deps.inject(
      child: const MaterialApp(
        home: AuthenticationScope(
          child: ChatConfigWidget(room: fakeRoom),
        ),
      ),
    );

void main() {
  late MockPusherChannelsClient mockChannelsClient;
  late MockPresenceChannel mockChannel;
  late MockAuthDelegate mockAuthDelegate;
  late MockDio mockDio;
  late FakeDependencies deps;

  setUpAll(() {
    registerFallbackValue(FakeAuthDelegate());
  });

  setUp(() {
    mockChannelsClient = MockPusherChannelsClient();
    mockChannel = MockPresenceChannel();
    mockAuthDelegate = MockAuthDelegate();
    mockDio = MockDio();

    when(
      () => mockChannelsClient.presenceChannel(
        any(),
        authorizationDelegate: any(named: 'authorizationDelegate'),
      ),
    ).thenReturn(mockChannel);

    when(() => mockChannel.name).thenReturn('presence-room.ABC123');
    when(() => mockChannel.subscribe()).thenReturn(null);
    when(() => mockChannel.unsubscribe()).thenReturn(null);
    when(() => mockChannel.bind('message.sent')).thenAnswer((_) => const Stream.empty());
    when(() => mockChannel.bind('message.typing')).thenAnswer((_) => const Stream.empty());

    when(() => mockDio.get<List<Object?>>(any())).thenAnswer(
      (_) async => Response(
        data: <Object?>[],
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    deps = FakeDependencies()
      ..dio = mockDio
      ..pusherClient = FakePusherClient(
        client: mockChannelsClient,
        authDelegate: mockAuthDelegate,
      )
      ..authenticationController = AuthenticationController(
        repository: AuthenticationFakeRepositoryImpl(),
      );
  });

  group('ChatScreenWidget', () {
    testWidgets('shows loading indicator before history loads', (tester) async {
      await tester.pumpWidget(_buildTree(deps));

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Connecting...'), findsOneWidget);
    });

    testWidgets('shows room name in AppBar', (tester) async {
      await tester.pumpWidget(_buildTree(deps));

      expect(find.text(fakeRoom.name), findsOneWidget);
    });

    testWidgets('shows room code chip in AppBar', (tester) async {
      await tester.pumpWidget(_buildTree(deps));

      expect(find.byType(Chip), findsOneWidget);
      expect(find.text(fakeRoom.code), findsOneWidget);
    });

    testWidgets('shows empty state after connecting with no messages', (tester) async {
      await tester.pumpWidget(_buildTree(deps));
      await tester.pumpAndSettle();

      expect(find.text('No messages yet. Say hello!'), findsOneWidget);
    });

    testWidgets('shows messages returned by history', (tester) async {
      when(() => mockDio.get<List<Object?>>(any())).thenAnswer(
        (_) async => Response(
          data: <Object?>[
            {
              'id': 1,
              'content': 'Hello from history',
              'created_at': '2026-03-27T10:00:00.000Z',
              'user': fakeUser.toMap(),
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      await tester.pumpWidget(_buildTree(deps));
      await tester.pumpAndSettle();

      expect(find.text('Hello from history'), findsOneWidget);
    });

    testWidgets('shows text input field when connected', (tester) async {
      await tester.pumpWidget(_buildTree(deps));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows send button when connected', (tester) async {
      await tester.pumpWidget(_buildTree(deps));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('send button calls repository when text is entered', (tester) async {
      when(() => mockDio.post<void>(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          data: null,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      await tester.pumpWidget(_buildTree(deps));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      verify(() => mockDio.post<void>(any(), data: any(named: 'data'))).called(1);
    });
  });
}
