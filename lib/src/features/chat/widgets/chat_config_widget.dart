import 'package:flutter/material.dart';
import 'package:websockets/src/common/util/screen_util.dart';
import 'package:websockets/src/features/authentication/widget/authentication_scope.dart';
import 'package:websockets/src/features/chat/controller/chat_controller.dart';
import 'package:websockets/src/features/chat/controller/chat_messages_controller.dart';
import 'package:websockets/src/features/chat/widgets/desktop/chat_desktop_widget.dart';
import 'package:websockets/src/features/chat/widgets/mobile/chat_mobile_widget.dart';
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

  static ChatController controllerOf(BuildContext context) =>
      _InheritedChatConfig.of(context).chatController;

  static ChatMessagesController messagesControllerOf(BuildContext context) =>
      _InheritedChatConfig.of(context).messagesController;

  static ChatState stateOf(BuildContext context) =>
      _InheritedChatConfig.of(context, listen: true).chatState;

  @override
  State<ChatConfigWidget> createState() => _ChatConfigWidgetState();
}

class _ChatConfigWidgetState extends State<ChatConfigWidget> {
  late final ChatController _chatController;
  late final ChatMessagesController _messagesController;

  @override
  void initState() {
    super.initState();
    final deps = Dependencies.of(context);
    _chatController = ChatController(repository: deps.chatRepository)
      ..addListener(_rebuild);
    _messagesController = ChatMessagesController(repository: deps.chatRepository)
      ..addListener(_rebuild);

    final token = AuthenticationScope.userOf(context, listen: false)?.token ?? '';
    _chatController.connect(room: widget.room, authToken: token);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _chatController
      ..removeListener(_rebuild)
      ..dispose();
    _messagesController
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _InheritedChatConfig(
    chatController: _chatController,
    messagesController: _messagesController,
    chatState: _chatController.state,
    child: context.screenSizeWhen(
      phone: () => ChatMobileWidget(room: widget.room),
      tablet: () => ChatMobileWidget(room: widget.room),
      desktop: () => ChatDesktopWidget(room: widget.room),
    ),
  );
}

// ---------------------------------------------------------------------------

class _InheritedChatConfig extends InheritedWidget {
  const _InheritedChatConfig({
    required this.chatController,
    required this.messagesController,
    required this.chatState,
    required super.child,
  });

  final ChatController chatController;
  final ChatMessagesController messagesController;
  final ChatState chatState;

  static _InheritedChatConfig of(BuildContext context, {bool listen = false}) {
    final result = listen
        ? context.dependOnInheritedWidgetOfExactType<_InheritedChatConfig>()
        : context.getInheritedWidgetOfExactType<_InheritedChatConfig>();
    assert(result != null, 'No _InheritedChatConfig found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant _InheritedChatConfig oldWidget) =>
      !identical(oldWidget.chatState, chatState);
}
