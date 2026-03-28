import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:websockets/src/common/util/pusher_client.dart';
import 'package:websockets/src/features/authentication/data/authentication_repository.dart';
import 'package:websockets/src/features/chat/data/chat_repository.dart';
import 'package:websockets/src/features/lobby/data/lobby_repository.dart';

// ---------------------------------------------------------------------------
// Pusher
// ---------------------------------------------------------------------------

class MockPusherChannelsClient extends Mock implements PusherChannelsClient {}

class MockPresenceChannel extends Mock implements PresenceChannel {}

class MockAuthDelegate extends Mock
    implements
        EndpointAuthorizableChannelTokenAuthorizationDelegate<
            PresenceChannelAuthorizationData> {}

/// Fallback value for mocktail — never actually called.
/// Register with [registerFallbackValue] in [setUpAll].
class FakeAuthDelegate extends Fake
    implements
        EndpointAuthorizableChannelTokenAuthorizationDelegate<
            PresenceChannelAuthorizationData> {}

/// Minimal fake of [PusherClient] — only exposes [client] and [authDelegate].
class FakePusherClient extends Fake implements PusherClient {
  FakePusherClient({
    required PusherChannelsClient client,
    required EndpointAuthorizableChannelTokenAuthorizationDelegate<
            PresenceChannelAuthorizationData>
        authDelegate,
  })  : _client = client,
        _authDelegate = authDelegate;

  final PusherChannelsClient _client;
  final EndpointAuthorizableChannelTokenAuthorizationDelegate<
      PresenceChannelAuthorizationData> _authDelegate;

  @override
  PusherChannelsClient get client => _client;

  @override
  EndpointAuthorizableChannelTokenAuthorizationDelegate<
      PresenceChannelAuthorizationData> get authDelegate => _authDelegate;
}

// ---------------------------------------------------------------------------
// Dio
// ---------------------------------------------------------------------------

class MockDio extends Mock implements Dio {}

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

class MockChatRepository extends Mock implements IChatRepository {}

class MockLobbyRepository extends Mock implements ILobbyRepository {}

class MockAuthenticationRepository extends Mock
    implements IAuthenticationRepository {}
