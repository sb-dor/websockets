import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:websockets/src/features/initialization/models/dependencies.dart';
import 'package:websockets/src/features/lobby/controller/lobby_controller.dart';
import 'package:websockets/src/features/lobby/widgets/lobby_screen_widget.dart';

/// {@template lobby_config_widget}
/// Owns the [LobbyController] and injects it into the subtree.
/// Navigates to chat when [LobbyState.roomReady] is emitted.
/// {@endtemplate}
class LobbyConfigWidget extends StatefulWidget {
  /// {@macro lobby_config_widget}
  const LobbyConfigWidget({super.key});

  /// Access the nearest [LobbyController] without rebuilding on state change.
  static LobbyController controllerOf(BuildContext context) =>
      _InheritedLobbyConfig.of(context).controller;

  /// Access the current [LobbyState].
  static LobbyState stateOf(BuildContext context) =>
      _InheritedLobbyConfig.of(context, listen: true).state;

  @override
  State<LobbyConfigWidget> createState() => _LobbyConfigWidgetState();
}

class _LobbyConfigWidgetState extends State<LobbyConfigWidget> {
  late final LobbyController _controller;

  @override
  void initState() {
    super.initState();
    final dependencies = Dependencies.of(context);
    _controller = LobbyController(repository: dependencies.lobbyRepository)
      ..addListener(_onStateChanged);

    _controller.loadRooms();
  }

  void _onStateChanged() {
    final state = _controller.state;
    if (state is Lobby$RoomReadyState && mounted) {
      Octopus.of(context).setState(
        (currentState) => currentState
          ..removeWhere((node) => node.name == 'chat')
          ..add(
            OctopusNode.immutable(
              'chat',
              arguments: {
                'id': state.room.id.toString(),
                'code': state.room.code,
                'name': state.room.name,
                'ownerId': state.room.ownerId.toString(),
              },
            ),
          ),
      );
      // Reload rooms so the lobby is ready when the user comes back from chat.
      _controller.loadRooms();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onStateChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _InheritedLobbyConfig(
    controller: _controller,
    state: _controller.state,
    child: const LobbyScreenWidget(),
  );
}

// ---------------------------------------------------------------------------

class _InheritedLobbyConfig extends InheritedWidget {
  const _InheritedLobbyConfig({
    required this.controller,
    required this.state,
    required super.child,
  });

  final LobbyController controller;
  final LobbyState state;

  static _InheritedLobbyConfig of(BuildContext context, {bool listen = false}) {
    final result = listen
        ? context.dependOnInheritedWidgetOfExactType<_InheritedLobbyConfig>()
        : context.getInheritedWidgetOfExactType<_InheritedLobbyConfig>();
    assert(result != null, 'No _InheritedLobbyConfig found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant _InheritedLobbyConfig oldWidget) =>
      !identical(oldWidget.state, state);
}
