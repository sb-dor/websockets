import 'dart:async';

import 'package:control/control.dart';
import 'package:meta/meta.dart';
import 'package:websockets/src/features/chat/data/chat_repository.dart';
import 'package:websockets/src/features/chat/models/chat_event.dart';
import 'package:websockets/src/features/lobby/models/room.dart';

/// {@template chat_typing_state}
/// ChatTypingState.
/// {@endtemplate}
@immutable
sealed class ChatTypingState {
  /// {@macro chat_typing_state}
  const ChatTypingState();

  /// Idle
  /// {@macro chat_typing_state}
  const factory ChatTypingState.idle() = ChatTypingState$Idle;

  /// Processing
  /// {@macro chat_typing_state}
  const factory ChatTypingState.processing({required final List<TypingMessage> typingMessages}) =
      ChatTypingState$Processing;
}

/// Idle
final class ChatTypingState$Idle extends ChatTypingState {
  const ChatTypingState$Idle();
}

/// Processing
final class ChatTypingState$Processing extends ChatTypingState {
  const ChatTypingState$Processing({required this.typingMessages});

  final List<TypingMessage> typingMessages;

  @override
  int get hashCode => typingMessages.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatTypingState$Processing &&
          runtimeType == other.runtimeType &&
          identical(typingMessages, other.typingMessages));
}

class ChatTypingController extends StateController<ChatTypingState>
    with SequentialControllerHandler {
  ChatTypingController({
    required final Stream<ChatEvent> chatEvents,
    required final IChatRepository chatRepository,
    required final Room room,
    super.initialState = const ChatTypingState.idle(),
  }) : _chatEvents = chatEvents,
       _chatRepository = chatRepository,
       _room = room;

  final Stream<ChatEvent> _chatEvents;
  final IChatRepository _chatRepository;
  final Room _room;

  StreamSubscription<ChatEvent>? _chatEventsSubs;

  void connect() => handle(() async {
    _chatEventsSubs = _chatEvents.listen((chatEvent) {
      if (chatEvent is TypingMessage) {
        var typingMessages = <TypingMessage>[];
        final currentState = state;
        if (currentState is ChatTypingState$Processing) {
          typingMessages.addAll(currentState.typingMessages);
        }

        final userIndex = typingMessages.indexWhere((el) => el.user.id == chatEvent.user.id);

        if (chatEvent.typing) {
          if (userIndex == -1) typingMessages.add(chatEvent);
        } else {
          if (userIndex != -1) typingMessages.removeAt(userIndex);
        }

        if (typingMessages.isEmpty) {
          setState(const ChatTypingState.idle());
        } else {
          setState(ChatTypingState.processing(typingMessages: typingMessages));
        }
      }
    });
  });

  void typing() => handle(() async => await _chatRepository.typing(roomCode: _room.code));

  void stopTyping() => handle(() async => await _chatRepository.stopTyping(roomCode: _room.code));

  @override
  void dispose() {
    _chatEventsSubs?.cancel();
    super.dispose();
  }
}
