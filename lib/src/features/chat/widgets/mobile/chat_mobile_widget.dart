import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:websockets/src/features/authentication/widget/authentication_scope.dart';
import 'package:websockets/src/features/chat/controller/chat_controller.dart';
import 'package:websockets/src/features/chat/controller/chat_messages_controller.dart';
import 'package:websockets/src/features/chat/models/message.dart';
import 'package:websockets/src/features/chat/widgets/chat_config_widget.dart';
import 'package:websockets/src/features/lobby/models/room.dart';

/// {@template chat_mobile_widget}
/// Mobile / tablet layout for the chat screen.
/// {@endtemplate}
class ChatMobileWidget extends StatefulWidget {
  /// {@macro chat_mobile_widget}
  const ChatMobileWidget({required this.room, super.key});

  final Room room;

  @override
  State<ChatMobileWidget> createState() => _ChatMobileWidgetState();
}

class _ChatMobileWidgetState extends State<ChatMobileWidget> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    ChatConfigWidget.messagesControllerOf(context).send(
      roomCode: widget.room.code,
      content: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ChatConfigWidget.stateOf(context);
    final isSending =
        ChatConfigWidget.messagesControllerOf(context).state is ChatMessages$SendingState;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.room.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Room code copied!')),
                );
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
                  final token =
                      AuthenticationScope.userOf(context, listen: false)?.token ?? '';
                  ChatConfigWidget.controllerOf(context)
                      .connect(room: widget.room, authToken: token);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        Chat$ConnectedState(:final messages) => Column(
          children: [
            Expanded(child: _MessageList(messages: messages, scrollController: _scrollController)),
            _InputBar(
              controller: _inputController,
              isSending: isSending,
              onSend: _send,
            ),
          ],
        ),
        _ => const SizedBox.shrink(),
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
                message.user.name,
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

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.isSending, required this.onSend});

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSending,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Type a message…',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isSending ? null : onSend,
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
}
