import 'package:flutter/material.dart';
import 'package:websockets/src/features/chat/controller/chat_controller.dart';
import 'package:websockets/src/features/chat/controller/chat_messages_controller.dart';
import 'package:websockets/src/features/chat/controller/chat_typing_controller.dart';
import 'package:websockets/src/features/chat/data/chat_repository.dart';
import 'package:websockets/src/features/chat/logic/chat_session.dart';
import 'package:websockets/src/features/chat/widgets/chat_screen_widget.dart';
import 'package:websockets/src/features/initialization/models/dependencies.dart';
import 'package:websockets/src/features/lobby/models/room.dart';

/// {@template chat_config_widget}
/// Owns [ChatController], [ChatTypingController], and [ChatMessagesController].
/// Creates a [ChatSession] on init to manage the Pusher channel and event stream,
/// and disposes everything on widget removal.
/// {@endtemplate}
class ChatConfigWidget extends StatefulWidget {
  /// {@macro chat_config_widget}
  const ChatConfigWidget({required this.room, super.key});

  final Room room;

  @override
  State<ChatConfigWidget> createState() => ChatConfigWidgetState();
}

class ChatConfigWidgetState extends State<ChatConfigWidget> {
  late final ChatController chatController;
  late final ChatTypingController chatTypingController;
  late final ChatMessagesController messagesController;

  /// Manages the Pusher presence channel and exposes a shared [Stream<ChatEvent>].
  /// Read more about why a shared stream is used here (read all messages from first link):
  /// 1. https://t.me/ru_dart/278066
  /// 2. https://t.me/ru_dart/278116
  late final ChatSession _session;

  @override
  void initState() {
    super.initState();
    final deps = Dependencies.of(context);

    _session = ChatSession(pusherClient: deps.pusherClient, roomCode: widget.room.code)
      ..subscribe();

    final repo = ChatRepositoryImpl(dio: deps.dio);

    chatController = ChatController(
      repository: repo,
      streamMessages: _session.events,
      room: widget.room,
    );
    chatTypingController = ChatTypingController(
      chatEvents: _session.events,
      chatRepository: repo,
      room: widget.room,
    );
    messagesController = ChatMessagesController(repository: repo);

    chatController.connect();
    chatTypingController.connect();
  }

  @override
  void dispose() {
    chatController.dispose();
    chatTypingController.dispose();
    messagesController.dispose();
    _session.dispose();
    super.dispose();
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
