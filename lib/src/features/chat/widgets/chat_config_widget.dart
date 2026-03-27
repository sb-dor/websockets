import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/material.dart';
import 'package:websockets/src/common/util/pusher_client.dart';
import 'package:websockets/src/features/chat/controller/chat_controller.dart';
import 'package:websockets/src/features/chat/controller/chat_messages_controller.dart';
import 'package:websockets/src/features/chat/data/chat_repository.dart';
import 'package:websockets/src/features/chat/models/message.dart';
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
  late final ChatMessagesController messagesController;
  late final PusherClient _pusherClient;

  /// Bridges incoming WebSocket events to [ChatController].
  /// Closed in [dispose] to automatically cancel the channel subscription.
  final StreamController<Message> messagesStreamController = StreamController<Message>.broadcast();
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
    );

    messagesController = ChatMessagesController(repository: chatrepository);

    chatController.connect(room: widget.room);
    _subscribeToRoom(room: widget.room);
  }

  @override
  void dispose() {
    chatController.dispose();
    messagesController.dispose();
    _presenceChannel?.unsubscribe();
    messagesStreamController.close();
    super.dispose();
  }

  /// Subscribes to the presence channel for [room] and forwards
  /// incoming `message.sent` events into [_messagesStreamController].
  Future<void> _subscribeToRoom({required Room room}) async {
    Future<void> initialize() async {
      if (messagesStreamController.isClosed) return;
      _presenceChannel = _pusherClient.client.presenceChannel(
        'presence-room.${room.code}',
        authorizationDelegate: _pusherClient.authDelegate,
      );
      _presenceChannel!.subscribe();
      _presenceChannel!.bind('message.sent').listen((event) {
        if (messagesStreamController.isClosed) return;
        final data = event.tryGetDataAsMap();
        if (data != null) messagesStreamController.add(Message.fromMap(data));
      });
    }

    await initialize();
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
