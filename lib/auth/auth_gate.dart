import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_shell.dart';
import '../models/billing_line.dart';
import '../sync/remote_sync_client.dart';
import '../widgets/brand_logo.dart';
import 'auth_service.dart';
import 'login_page.dart';

/// Decides whether to show the [LoginPage] or the authenticated [AppShell],
/// based on the Firebase auth state.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.authService,
    this.initialLines,
    this.persistLocalData = true,
    this.remoteSyncClient,
  });

  final AuthService authService;
  final List<BillingLine>? initialLines;
  final bool persistLocalData;
  final RemoteSyncClient? remoteSyncClient;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authService.authStateChanges(),
      builder: (context, snapshot) {
        final Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = const _AuthSplash(key: ValueKey('auth-splash'));
        } else if (snapshot.hasData) {
          child = AppShell(
            key: const ValueKey('app-shell'),
            initialLines: widget.initialLines,
            persistLocalData: widget.persistLocalData,
            remoteSyncClient: widget.remoteSyncClient,
            onSignOut: widget.authService.signOut,
            currentUserEmail: snapshot.data?.email,
          );
        } else {
          child = LoginPage(
            key: const ValueKey('login-page'),
            authService: widget.authService,
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: child,
        );
      },
    );
  }
}

/// Lightweight branded splash shown while the auth state resolves.
class _AuthSplash extends StatelessWidget {
  const _AuthSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            BrandLogo.full(height: 88),
            SizedBox(height: 28),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            SizedBox(height: 14),
            Text(
              'Ouverture de votre espace...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
