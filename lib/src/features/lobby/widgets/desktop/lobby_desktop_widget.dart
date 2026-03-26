import 'package:flutter/material.dart';
import 'package:websockets/src/features/lobby/widgets/mobile/lobby_mobile_widget.dart';

/// {@template lobby_desktop_widget}
/// Desktop layout for the lobby — reuses the mobile layout centred with max-width.
/// {@endtemplate}
class LobbyDesktopWidget extends StatelessWidget {
  /// {@macro lobby_desktop_widget}
  const LobbyDesktopWidget({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: const LobbyMobileWidget(),
    ),
  );
}
