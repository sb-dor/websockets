import 'package:flutter/material.dart';
import 'package:websockets/src/features/chat/widgets/mobile/chat_mobile_widget.dart';
import 'package:websockets/src/features/lobby/models/room.dart';

/// {@template chat_desktop_widget}
/// Desktop layout — reuses mobile chat centred with max-width.
/// {@endtemplate}
class ChatDesktopWidget extends StatelessWidget {
  /// {@macro chat_desktop_widget}
  const ChatDesktopWidget({required this.room, super.key});

  final Room room;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: ChatMobileWidget(room: room),
    ),
  );
}
