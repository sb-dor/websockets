import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/material.dart';
import 'package:websockets/src/common/util/pusher_client.dart';
import 'package:websockets/src/features/chat/controller/chat_controller.dart';
import 'package:websockets/src/features/chat/controller/chat_messages_controller.dart';
import 'package:websockets/src/features/chat/controller/chat_typing_controller.dart';
import 'package:websockets/src/features/chat/data/chat_repository.dart';
import 'package:websockets/src/features/chat/models/chat_event.dart';
import 'package:websockets/src/features/chat/widgets/chat_screen_widget.dart';
import 'package:websockets/src/features/initialization/models/dependencies.dart';
import 'package:websockets/src/features/lobby/models/room.dart';

/// {@template chat_config_widget}
/// Owns [ChatController] and [ChatMessagesController].
/// Connects to WebSocket on init and disconnects on dispose.
/// {@endtemplate}
class ChatConfigWidget extends StatefulWidget {
  /// {@macro chat_config_widget}
  const ChatConfigWidget({required this.room, super.key});

  final Room room;

  @override
  State<ChatConfigWidget> createState() => ChatConfigWidgetState();
}

class ChatConfigWidgetState extends State<ChatConfigWidget> {
  /// Controllers and the shared Pusher client, initialised once in [initState].
  late final ChatController chatController;
  late final ChatTypingController chatTypingController;
  late final ChatMessagesController messagesController;
  late final PusherClient _pusherClient;

  /// Bridges incoming WebSocket events to [ChatController].
  /// Closed in [dispose] to automatically cancel the channel subscription.
  /// More information about why I did this way you can find in this telegram conversion (read all messages starting from first link)
  /// 1. https://t.me/ru_dart/278066
  /// 2. https://t.me/ru_dart/278116
  final StreamController<ChatEvent> messagesStreamController =
      StreamController<ChatEvent>.broadcast();
  StreamSubscription<ChannelReadEvent>? _messageSendSubs;
  StreamSubscription<ChannelReadEvent>? _messageTypingSubs;
  PresenceChannel? _presenceChannel;

  @override
  void initState() {
    super.initState();
    final deps = Dependencies.of(context);
    _pusherClient = deps.pusherClient;

    final chatrepository = ChatRepositoryImpl(dio: deps.dio);

    chatController = ChatController(
      repository: chatrepository,
      streamMessages: messagesStreamController.stream,
      room: widget.room,
    );
    chatTypingController = ChatTypingController(
      chatEvents: messagesStreamController.stream,
      chatRepository: chatrepository,
      room: widget.room,
    );
    messagesController = ChatMessagesController(repository: chatrepository);

    chatController.connect();
    chatTypingController.connect();
    _subscribeToRoom();
  }

  @override
  void dispose() {
    chatController.dispose();
    messagesController.dispose();
    _presenceChannel?.unsubscribe();
    messagesStreamController.close();
    _messageSendSubs?.cancel();
    _messageTypingSubs?.cancel();
    super.dispose();
  }

  /// Subscribes to the presence channel for [room] and forwards
  /// incoming `message.sent` events into [_messagesStreamController].
  /// Read more about this
  /// https://pub.dev/packages/dart_pusher_channels#binding-to-events
  Future<void> _subscribeToRoom() async {
    if (messagesStreamController.isClosed) return;

    _presenceChannel = _pusherClient.client.presenceChannel(
      'presence-room.${widget.room.code}',
      authorizationDelegate: _pusherClient.authDelegate,
    );
    _presenceChannel!.subscribe();
    _messageSendSubs = _presenceChannel!.bind('message.sent').listen((event) {
      if (messagesStreamController.isClosed) return;
      final data = event.tryGetDataAsMap();
      if (data != null) messagesStreamController.add(Message.fromMap(data));
    });
    _messageSendSubs = _presenceChannel!.bind('message.typing').listen((event) {
      final data = event.tryGetDataAsMap();
      print('typing: $data');
      if (data != null) messagesStreamController.add(TypingMessage.fromJson(data));
    });
  }

  @override
  Widget build(BuildContext context) => ChatScope(
    state: this,
    child: ChatScreenWidget(room: widget.room),
  );
}

// ---------------------------------------------------------------------------

class ChatScope extends InheritedWidget {
  const ChatScope({super.key, required this.state, required super.child});

  static ChatConfigWidgetState of(BuildContext context) {
    final widget = context.getElementForInheritedWidgetOfExactType<ChatScope>()?.widget;
    assert(widget != null, 'No ChatScope found in context');
    return (widget as ChatScope).state;
  }

  final ChatConfigWidgetState state;

  @override
  bool updateShouldNotify(covariant ChatScope oldWidget) => false;
}
