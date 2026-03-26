import 'dart:async';

import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:websockets/src/features/chat/data/chat_repository.dart';
import 'package:websockets/src/features/chat/models/message.dart';
import 'package:websockets/src/features/lobby/models/room.dart';

@immutable
sealed class ChatState {
  const ChatState();

  const factory ChatState.initial() = Chat$InitialState;
  const factory ChatState.connecting() = Chat$ConnectingState;
  const factory ChatState.connected({required Room room, required List<Message> messages}) =
      Chat$ConnectedState;
  const factory ChatState.error(String message) = Chat$ErrorState;
  const factory ChatState.disconnected() = Chat$DisconnectedState;
}

final class Chat$InitialState extends ChatState {
  const Chat$InitialState();
}

final class Chat$ConnectingState extends ChatState {
  const Chat$ConnectingState();
}

final class Chat$ConnectedState extends ChatState {
  const Chat$ConnectedState({required this.room, required this.messages});
  final Room room;
  final List<Message> messages;

  Chat$ConnectedState copyWith({Room? room, List<Message>? messages}) =>
      Chat$ConnectedState(room: room ?? this.room, messages: messages ?? this.messages);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chat$ConnectedState && room == other.room && messages == other.messages);

  @override
  int get hashCode => room.hashCode ^ messages.hashCode;
}

final class Chat$ErrorState extends ChatState {
  const Chat$ErrorState(this.message);
  final String message;
}

final class Chat$DisconnectedState extends ChatState {
  const Chat$DisconnectedState();
}

class ChatController extends StateController<ChatState> with SequentialControllerHandler {
  ChatController({
    required IChatRepository repository,
    super.initialState = const ChatState.initial(),
  }) : _repository = repository;

  final IChatRepository _repository;
  StreamSubscription<Message>? _messageSub;

  void connect({required Room room, required String authToken}) => handle(() async {
    setState(const ChatState.connecting());
    await _repository.connect(authToken: authToken);
    final history = await _repository.getHistory(roomCode: room.code);
    setState(ChatState.connected(room: room, messages: history));

    _messageSub = _repository
        .subscribeToRoom(roomCode: room.code)
        .listen(
          (message) {
            final current = state;
            if (current is Chat$ConnectedState) {
              setState(current.copyWith(messages: [...current.messages, message]));
            }
          },
          onError: (Object e) {
            if (state is Chat$ConnectedState) {
              setState(ChatState.error(e.toString()));
            }
          },
        );
  });

  void disconnect() => handle(() async {
    await _messageSub?.cancel();
    _messageSub = null;
    await _repository.disconnect();
    setState(const ChatState.disconnected());
  });

  @override
  void dispose() {
    _messageSub?.cancel();
    _messageSub = null;
    // disconnect() is a no-op if connect() is called again first,
    // because connect() cleans up stale state at the start.
    _repository.disconnect().ignore();
    super.dispose();
  }
}
