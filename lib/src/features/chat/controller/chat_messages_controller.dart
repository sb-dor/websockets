import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:websockets/src/features/chat/data/chat_repository.dart';

@immutable
sealed class ChatMessagesState {
  const ChatMessagesState();

  const factory ChatMessagesState.idle() = ChatMessages$IdleState;
  const factory ChatMessagesState.sending() = ChatMessages$SendingState;
  const factory ChatMessagesState.error(String message) = ChatMessages$ErrorState;
  const factory ChatMessagesState.sent() = ChatMessages$SentState;
}

final class ChatMessages$IdleState extends ChatMessagesState {
  const ChatMessages$IdleState();
}

final class ChatMessages$SendingState extends ChatMessagesState {
  const ChatMessages$SendingState();
}

final class ChatMessages$ErrorState extends ChatMessagesState {
  const ChatMessages$ErrorState(this.message);
  final String message;
}

final class ChatMessages$SentState extends ChatMessagesState {
  const ChatMessages$SentState();
}

class ChatMessagesController extends StateController<ChatMessagesState>
    with DroppableControllerHandler {
  ChatMessagesController({
    required IChatRepository repository,
    super.initialState = const ChatMessagesState.idle(),
  }) : _repository = repository;

  final IChatRepository _repository;

  void send({required String roomCode, required String content}) => handle(() async {
    setState(const ChatMessagesState.sending());
    await _repository.sendMessage(roomCode: roomCode, content: content);
    setState(const ChatMessagesState.sent());
    // Reset to idle so the send button re-enables
    setState(const ChatMessagesState.idle());
  });
}
