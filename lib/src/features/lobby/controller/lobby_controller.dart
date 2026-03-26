import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:websockets/src/features/lobby/data/lobby_repository.dart';
import 'package:websockets/src/features/lobby/models/room.dart';

@immutable
sealed class LobbyState {
  const LobbyState();

  const factory LobbyState.initial() = Lobby$InitialState;
  const factory LobbyState.inProgress() = Lobby$InProgressState;
  const factory LobbyState.error(String message) = Lobby$ErrorState;
  const factory LobbyState.loaded(List<Room> rooms) = Lobby$LoadedState;

  /// Emitted after creating/joining a room — widget listens and navigates to chat.
  const factory LobbyState.roomReady(Room room) = Lobby$RoomReadyState;
}

final class Lobby$InitialState extends LobbyState {
  const Lobby$InitialState();
}

final class Lobby$InProgressState extends LobbyState {
  const Lobby$InProgressState();
}

final class Lobby$ErrorState extends LobbyState {
  const Lobby$ErrorState(this.message);
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Lobby$ErrorState && message == other.message);

  @override
  int get hashCode => message.hashCode;
}

final class Lobby$LoadedState extends LobbyState {
  const Lobby$LoadedState(this.rooms);
  final List<Room> rooms;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Lobby$LoadedState && rooms == other.rooms);

  @override
  int get hashCode => rooms.hashCode;
}

final class Lobby$RoomReadyState extends LobbyState {
  const Lobby$RoomReadyState(this.room);
  final Room room;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Lobby$RoomReadyState && room == other.room);

  @override
  int get hashCode => room.hashCode;
}

class LobbyController extends StateController<LobbyState> with SequentialControllerHandler {
  LobbyController({
    required ILobbyRepository repository,
    super.initialState = const LobbyState.initial(),
  }) : _repository = repository;

  final ILobbyRepository _repository;

  void loadRooms() => handle(() async {
    setState(const LobbyState.inProgress());
    final rooms = await _repository.getRooms();
    setState(LobbyState.loaded(rooms));
  });

  void createRoom(String name) => handle(() async {
    setState(const LobbyState.inProgress());
    final room = await _repository.createRoom(name: name);
    setState(LobbyState.roomReady(room));
  });

  void joinRoom(String code) => handle(() async {
    setState(const LobbyState.inProgress());
    final room = await _repository.joinRoom(code: code);
    setState(LobbyState.roomReady(room));
  });
}
