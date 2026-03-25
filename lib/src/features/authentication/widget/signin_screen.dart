import 'package:flutter/material.dart';
import 'package:websockets/src/common/widget/scaffold_padding.dart';
import 'package:websockets/src/features/authentication/widget/authentication_scope.dart';

/// {@template signin_screen}
/// Guest display-name entry screen.
/// {@endtemplate}
class SignInScreen extends StatefulWidget {
  /// {@macro signin_screen}
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _nameError;

  bool get _isValid => _nameController.text.trim().length >= 2;

  void _submit() {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(() => _nameError = 'Name must be at least 2 characters.');
      return;
    }
    setState(() => _nameError = null);
    AuthenticationScope.controllerOf(context).signIn(name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              child: Padding(
                padding: ScaffoldPadding.of(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.video_call_rounded, size: 80, color: Colors.teal),
                    const SizedBox(height: 24),
                    Text(
                      'Websockets',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your display name to continue',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      autofocus: true,
                      maxLength: 30,
                      onChanged: (_) => setState(() => _nameError = null),
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        hintText: 'e.g. Alex Johnson',
                        prefixIcon: const Icon(Icons.person),
                        errorText: _nameError,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: _nameController,
                      builder: (context, _) => FilledButton.icon(
                        onPressed: _isValid ? _submit : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Continue'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
