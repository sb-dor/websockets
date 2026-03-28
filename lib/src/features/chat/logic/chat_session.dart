import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:websockets/src/common/util/pusher_client.dart';
import 'package:websockets/src/features/chat/models/chat_event.dart';

/// Owns the Pusher presence channel for one room and exposes
/// a single broadcast [Stream<ChatEvent>] consumed by controllers.
///
/// Call [subscribe] once to start receiving events.
/// Call [dispose] when the room session ends to cancel subscriptions and close the stream.
class ChatSession {
  ChatSession({required PusherClient pusherClient, required String roomCode})
      : _pusherClient = pusherClient,
        _roomCode = roomCode;

  final PusherClient _pusherClient;
  final String _roomCode;

  final StreamController<ChatEvent> _controller = StreamController<ChatEvent>.broadcast();
  PresenceChannel? _channel;
  StreamSubscription<ChannelReadEvent>? _sendSub;
  StreamSubscription<ChannelReadEvent>? _typingSub;

  /// Broadcast stream of all incoming [ChatEvent]s for this room.
  Stream<ChatEvent> get events => _controller.stream;

  /// Subscribes to the presence channel and starts forwarding events into [events].
  void subscribe() {
    if (_controller.isClosed) return;
    _channel = _pusherClient.client.presenceChannel(
      'presence-room.$_roomCode',
      authorizationDelegate: _pusherClient.authDelegate,
    );
    _channel!.subscribe();
    _sendSub = _channel!.bind('message.sent').listen((event) {
      if (_controller.isClosed) return;
      final data = event.tryGetDataAsMap();
      if (data != null) _controller.add(Message.fromMap(data));
    });
    _typingSub = _channel!.bind('message.typing').listen((event) {
      if (_controller.isClosed) return;
      final data = event.tryGetDataAsMap();
      if (data != null) _controller.add(TypingMessage.fromJson(data));
    });
  }

  /// Cancels all subscriptions, unsubscribes the channel, and closes the stream.
  void dispose() {
    _sendSub?.cancel();
    _typingSub?.cancel();
    _channel?.unsubscribe();
    _controller.close();
  }
}
