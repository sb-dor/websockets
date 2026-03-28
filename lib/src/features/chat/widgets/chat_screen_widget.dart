import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:websockets/src/features/authentication/widget/authentication_scope.dart';
import 'package:websockets/src/features/chat/controller/chat_controller.dart';
import 'package:websockets/src/features/chat/controller/chat_messages_controller.dart';
import 'package:websockets/src/features/chat/controller/chat_typing_controller.dart';
import 'package:websockets/src/features/chat/models/chat_event.dart';
import 'package:websockets/src/features/chat/widgets/chat_config_widget.dart';
import 'package:websockets/src/features/lobby/models/room.dart';

/// {@template chat_mobile_widget}
/// Mobile / tablet layout for the chat screen.
/// {@endtemplate}
class ChatScreenWidget extends StatefulWidget {
  /// {@macro chat_mobile_widget}
  const ChatScreenWidget({required this.room, super.key});

  final Room room;

  @override
  State<ChatScreenWidget> createState() => _ChatScreenWidgetState();
}

class _ChatScreenWidgetState extends State<ChatScreenWidget> {
  late final _chatScope = ChatScope.of(context);
  late final _chatController = _chatScope.chatController;
  late final _chatTypingController = _chatScope.chatTypingController;

  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_chatController, _chatTypingController]),
      builder: (context, child) {
        final chatState = _chatController.state;
        final chatTypingState = _chatTypingController.state;
        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: switch (chatTypingState) {
              ChatTypingState$Idle() => Text(widget.room.name),
              ChatTypingState$Processing(:final typingMessages) => Text(
                typingMessages.map((el) => '${el.user.name} is typing...').join(' '),
                style: const TextStyle(color: Colors.blue),
              ),
            },
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.room.code));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Room code copied!')));
                  },
                  child: Chip(label: Text(widget.room.code)),
                ),
              ),
            ],
          ),
          body: switch (chatState) {
            Chat$ConnectingState() || Chat$InitialState() => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Connecting...'),
                ],
              ),
            ),
            Chat$ErrorState(:final message) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      _chatController.connect();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            Chat$ConnectedState(:final messages) => Column(
              children: [
                Expanded(
                  child: _MessageList(messages: messages, scrollController: _scrollController),
                ),
                _InputBar(room: widget.room),
              ],
            ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages, required this.scrollController});

  final List<Message> messages;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(child: Text('No messages yet. Say hello!'));
    }

    final currentUserId = AuthenticationScope.userOf(context, listen: false)?.id;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (_, index) {
        final msg = messages[index];
        final isMe = msg.user.id == currentUserId;
        return _MessageBubble(message: msg, isMe: isMe);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final Message message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.teal : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.user.name ?? '',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.teal.shade200,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(message.content),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  const _InputBar({required this.room});

  final Room room;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  late final _chatScope = ChatScope.of(context);
  late final _chatMessageController = _chatScope.messagesController;
  late final _chatTypingController = _chatScope.chatTypingController;
  final _inputController = TextEditingController();

  bool _messageTyping = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _inputController.dispose();
    _stopTyping();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _chatMessageController.send(roomCode: widget.room.code, content: text);
  }

  void _typing() {
    if (!_messageTyping) {
      _messageTyping = true;
      _chatTypingController.typing();
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    _messageTyping = false;
    _chatTypingController.stopTyping();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _chatMessageController,
    builder: (context, child) {
      final isSending = _chatMessageController.state is ChatMessages$SendingState;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('messageInput'),
                  controller: _inputController,
                  enabled: !isSending,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  onChanged: (_) => _typing(),
                  decoration: const InputDecoration(
                    hintText: 'Type a message…',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const Key('sendButton'),
                onPressed: isSending ? null : _send,
                icon: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                style: IconButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ],
          ),
        ),
      );
    },
  );
}
