import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:websockets/src/features/account/widget/profile_screen.dart';
import 'package:websockets/src/features/authentication/widget/signin_screen.dart';
import 'package:websockets/src/features/chat/widgets/chat_config_widget.dart';
import 'package:websockets/src/features/developer/widget/developer_screen.dart';
import 'package:websockets/src/features/home/widget/home_screen.dart';
import 'package:websockets/src/features/lobby/models/room.dart';
import 'package:websockets/src/features/lobby/widgets/lobby_config_widget.dart';
import 'package:websockets/src/features/settings/widget/settings_screen.dart';

enum Routes with OctopusRoute {
  signin('signin', title: 'Sign-In'),
  home('home', title: 'Home'),
  lobby('lobby', title: 'Lobby'),
  chat('chat', title: 'Chat'),
  profile('profile', title: 'Profile'),
  developer('developer', title: 'Developer'),
  settings('settings', title: 'Settings');

  const Routes(this.name, {this.title});

  @override
  final String name;

  /// title is not necessary
  @override
  final String? title;

  @override
  Widget builder(BuildContext context, OctopusState state, OctopusNode node) => switch (this) {
    Routes.signin => const SignInScreen(),
    Routes.home => const HomeScreen(),
    Routes.lobby => const LobbyConfigWidget(),
    Routes.chat => ChatConfigWidget(
      room: Room(
        id: int.tryParse(node.arguments['id'] ?? '') ?? 0,
        code: node.arguments['code'] ?? '',
        name: node.arguments['name'] ?? '',
        ownerId: int.tryParse(node.arguments['ownerId'] ?? '') ?? 0,
      ),
    ),
    Routes.profile => const ProfileScreen(),
    Routes.developer => const DeveloperScreen(),
    Routes.settings => const SettingsScreen(),
  };
}
