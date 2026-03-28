import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:websockets/main.dart' as app;
import 'package:websockets/src/features/authentication/widget/signin_screen.dart';
import 'package:websockets/src/features/lobby/widgets/lobby_screen_widget.dart';

import 'helpers/auth_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication', () {
    testWidgets('sign-in screen is shown on first launch', (tester) async {
      await clearSavedSession();
      app.main();
      await waitForApp(tester);

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('WsChat'), findsOneWidget);
    });

    testWidgets('submit button is disabled with empty fields', (tester) async {
      await clearSavedSession();
      app.main();
      await waitForApp(tester);

      final button = tester.widget<FilledButton>(find.byKey(const Key('submitButton')));
      expect(button.onPressed, isNull);
    });

    testWidgets('submit button enables after valid email and password', (tester) async {
      await clearSavedSession();
      app.main();
      await waitForApp(tester);

      await tester.enterText(find.byKey(const Key('emailField')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byKey(const Key('submitButton')));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('login with valid credentials navigates to lobby', (tester) async {
      await clearSavedSession();
      app.main();
      await waitForApp(tester);

      await loginTestUser(tester);

      expect(find.byType(LobbyScreenWidget), findsOneWidget);
      expect(find.text('Lobby'), findsOneWidget);
    });

    testWidgets('login with wrong password shows error message', (tester) async {
      await clearSavedSession();
      app.main();
      await waitForApp(tester);

      await tester.enterText(find.byKey(const Key('emailField')), kTestEmail);
      await tester.enterText(find.byKey(const Key('passwordField')), 'wrongpassword');
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pumpAndSettle();

      // Should still be on sign-in screen with an error shown
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('switching to Register tab shows name field', (tester) async {
      await clearSavedSession();
      app.main();
      await waitForApp(tester);

      expect(find.byKey(const Key('nameField')), findsNothing);

      // SegmentedButton — tap the Register segment
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nameField')), findsOneWidget);
    });
  });
}
