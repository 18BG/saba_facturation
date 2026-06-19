import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'models/billing_line.dart';
import 'theme/app_theme.dart';

void main() {
  _installDebugFrameworkNoiseFilter();
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
  });

  final List<BillingLine>? initialLines;
  final bool persistLocalData;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facturation RH',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AppShell(
        initialLines: initialLines,
        persistLocalData: persistLocalData,
      ),
    );
  }
}
