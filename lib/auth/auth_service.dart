import 'package:firebase_auth/firebase_auth.dart';

/// Thin, testable wrapper around [FirebaseAuth] for the app.
///
/// Centralizes sign-in/out and maps Firebase error codes to French,
/// user-friendly messages.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Emits the current user, or `null` when signed out.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageForCode(error.code));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageForCode(error.code));
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _messageForCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'user-disabled':
        return 'Ce compte a ete desactive.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou mot de passe incorrect.';
      case 'too-many-requests':
        return 'Trop de tentatives. Reessayez dans quelques minutes.';
      case 'network-request-failed':
        return 'Connexion impossible. Verifiez votre reseau.';
      default:
        return 'Une erreur est survenue. Reessayez.';
    }
  }
}

/// User-facing authentication error with a localized [message].
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
