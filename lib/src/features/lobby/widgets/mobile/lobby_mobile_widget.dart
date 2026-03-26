import 'package:flutter/material.dart';
import 'package:websockets/src/features/lobby/controller/lobby_controller.dart';
import 'package:websockets/src/features/lobby/models/room.dart';
import 'package:websockets/src/features/lobby/widgets/lobby_config_widget.dart';

/// {@template lobby_mobile_widget}
/// Mobile / tablet layout for the lobby screen.
/// {@endtemplate}
class LobbyMobileWidget extends StatelessWidget {
  /// {@macro lobby_mobile_widget}
  const LobbyMobileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final state = LobbyConfigWidget.stateOf(context);
    final controller = LobbyConfigWidget.controllerOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: controller.loadRooms,
          ),
        ],
      ),
      body: switch (state) {
        Lobby$InProgressState() => const Center(child: CircularProgressIndicator()),
        Lobby$ErrorState(:final message) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              FilledButton(onPressed: controller.loadRooms, child: const Text('Retry')),
            ],
          ),
        ),
        Lobby$LoadedState(:final rooms) => _RoomList(rooms: rooms),
        Lobby$RoomReadyState() => const _RoomList(rooms: []),
        _ => const SizedBox.shrink(),
      },
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'join',
            onPressed: () => _showJoinDialog(context, controller),
            icon: const Icon(Icons.login),
            label: const Text('Join Room'),
            backgroundColor: Colors.teal.shade700,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: () => _showCreateDialog(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Create Room'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, LobbyController controller) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Room'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Room name', border: OutlineInputBorder()),
          onSubmitted: (v) {
            Navigator.pop(ctx);
            if (v.trim().isNotEmpty) controller.createRoom(v.trim());
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (ctrl.text.trim().isNotEmpty) controller.createRoom(ctrl.text.trim());
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context, LobbyController controller) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Room'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 8,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Room code',
            hintText: 'e.g. XKBF9A2M',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) {
            Navigator.pop(ctx);
            if (v.trim().length == 8) controller.joinRoom(v.trim());
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (ctrl.text.trim().length == 8) controller.joinRoom(ctrl.text.trim());
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}

class _RoomList extends StatelessWidget {
  const _RoomList({required this.rooms});
  final List<Room> rooms;

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white30),
            SizedBox(height: 12),
            Text('No rooms yet.\nCreate one or join with a code.', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final room = rooms[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.chat)),
            title: Text(room.name),
            subtitle: Text('Code: ${room.code}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => LobbyConfigWidget.controllerOf(context).joinRoom(room.code),
          ),
        );
      },
    );
  }
}
