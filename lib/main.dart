import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'auth/auth_gate.dart';
import 'auth/auth_service.dart';
import 'firebase_options.dart';
import 'models/billing_line.dart';
import 'sync/remote_sync_client.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installDebugFrameworkNoiseFilter();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FacturationApp());
}

void _installDebugFrameworkNoiseFilter() {
  assert(() {
    final defaultOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      final isWindowsRawKeyboardNoise =
          message.contains('Attempted to send a key down event') &&
          message.contains('_keysPressed.isNotEmpty');

      if (isWindowsRawKeyboardNoise) return;

      if (defaultOnError != null) {
        defaultOnError(details);
      } else {
        FlutterError.presentError(details);
      }
    };
    return true;
  }());
}

class FacturationApp extends StatelessWidget {
  const FacturationApp({
    super.key,
    this.initialLines,
    this.persistLocalData = true,
    this.remoteSyncClient,
    this.authService,
    this.requireAuth = true,
  });

  final List<BillingLine>? initialLines;
  final bool persistLocalData;
  final RemoteSyncClient? remoteSyncClient;
  final AuthService? authService;

  /// When false, the app mounts straight into [AppShell] without the auth
  /// gate. Used by widget tests to bypass Firebase Auth.
  final bool requireAuth;

  @override
  Widget build(BuildContext context) {
    final Widget home = requireAuth
        ? AuthGate(
            authService: authService ?? AuthService(),
            initialLines: initialLines,
            persistLocalData: persistLocalData,
            remoteSyncClient: remoteSyncClient,
          )
        : AppShell(
            initialLines: initialLines,
            persistLocalData: persistLocalData,
            remoteSyncClient: remoteSyncClient,
          );

    return MaterialApp(
      title: 'Facturation RH',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: home,
    );
  }
}
