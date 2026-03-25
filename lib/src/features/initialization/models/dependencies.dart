import 'package:flutter/widgets.dart';
import 'package:websockets/src/common/model/app_metadata.dart';
import 'package:websockets/src/features/authentication/controller/authentication_controller.dart';
import 'package:websockets/src/features/initialization/widget/dependencies_scope.dart';

/// {@template dependencies}
/// Application dependencies.
/// {@endtemplate}
class Dependencies {
  /// {@macro dependencies}
  Dependencies();

  /// The state from the closest instance of this class.
  ///
  /// {@macro dependencies}
  factory Dependencies.of(BuildContext context) => DependenciesScope.of(context);

  /// Injest dependencies to the widget tree.
  Widget inject({required Widget child, Key? key}) =>
      DependenciesScope(dependencies: this, key: key, child: child);

  /// App metadata
  late final AppMetadata metadata;

  /// Authentication controller
  late final AuthenticationController authenticationController;

  @override
  String toString() => 'Dependencies{}';
}

/// Fake Dependencies
@visibleForTesting
class FakeDependencies extends Dependencies {
  FakeDependencies();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // ... implement fake dependencies
    throw UnimplementedError();
  }
}
