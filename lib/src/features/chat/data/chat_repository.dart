import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:dio/dio.dart';
import 'package:websockets/src/common/constant/config.dart';
import 'package:websockets/src/common/util/pusher_client.dart';
import 'package:websockets/src/features/chat/models/message.dart';

abstract interface class IChatRepository {
  Future<void> connect({required String authToken});
  Future<List<Message>> getHistory({required String roomCode});
  Future<void> sendMessage({required String roomCode, required String content});

  /// Returns a broadcast stream of incoming [Message]s for the given room.
  /// The stream is closed when [unsubscribe] is called.
  Stream<Message> subscribeToRoom({required String roomCode});

  Future<void> unsubscribe({required String roomCode});
  Future<void> disconnect();
}

class ChatRepositoryImpl implements IChatRepository {
  ChatRepositoryImpl({required final Dio dio, required final PusherClient pusherClient})
    : _dio = dio,
      _pusherClient = pusherClient;

  final Dio _dio;
  final PusherClient _pusherClient;
  StreamSubscription<void>? _connectionSub;
  String? _authToken;
  final Map<String, PresenceChannel> _channels = {};

  @override
  Future<void> connect({required String authToken}) async {
    // Tear down any previous session before starting a new one.
    // This prevents the old disconnect() (fire-and-forget) from racing with
    // the new client created below.
    await _connectionSub?.cancel();
    _connectionSub = null;
    for (final ch in _channels.values) {
      ch.unsubscribe();
    }
    _channels.clear();

    _authToken = authToken;

    // Re-subscribe all channels when connection is (re-)established.
    _connectionSub = _pusherClient.client.onConnectionEstablished.listen((_) {
      for (final ch in _channels.values) {
        ch.subscribeIfNotUnsubscribed();
      }
    });
  }

  @override
  Future<List<Message>> getHistory({required String roomCode}) async {
    final response = await _dio.get<List<Object?>>('/api/rooms/$roomCode/messages');
    return (response.data ?? [])
        .whereType<Map<String, Object?>>()
        .map(Message.fromMap)
        .toList(growable: false);
  }

  @override
  Future<void> sendMessage({required String roomCode, required String content}) async {
    await _dio.post<void>('/api/rooms/$roomCode/messages', data: {'content': content});
  }

  @override
  Stream<Message> subscribeToRoom({required String roomCode}) {
    final streamController = StreamController<Message>.broadcast();

    Future<void> initialize() async {
      if (streamController.isClosed) return;
      try {
        final authDelegate =
            EndpointAuthorizableChannelTokenAuthorizationDelegate.forPresenceChannel(
              authorizationEndpoint: Uri.parse('${Config.apiBaseUrl}/api/broadcasting/auth'),
              headers: {'Authorization': 'Bearer $_authToken'},
            );

        final channel = _pusherClient.client.presenceChannel(
          'presence-room.$roomCode',
          authorizationDelegate: authDelegate,
        );
        _channels[roomCode] = channel;
        channel.subscribeIfNotUnsubscribed();

        final sub = channel.bind('message.sent').listen((event) {
          if (streamController.isClosed) return;
          try {
            final data = event.tryGetDataAsMap();
            if (data != null) streamController.add(Message.fromMap(data));
          } on Object {
            // ignore malformed event
          }
        });

        await streamController.done;
        await sub.cancel();
      } on Object catch (e, s) {
        if (!streamController.isClosed) streamController.addError(e, s);
      } finally {
        _channels.remove(roomCode)?.unsubscribe();
        if (!streamController.isClosed) await streamController.close();
      }
    }

    initialize();

    return streamController.stream;
  }

  @override
  Future<void> unsubscribe({required String roomCode}) async {
    _channels.remove(roomCode)?.unsubscribe();
  }

  @override
  Future<void> disconnect() async {
    await _connectionSub?.cancel();
    _connectionSub = null;
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
  }
}
