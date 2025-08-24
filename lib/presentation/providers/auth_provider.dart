import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth/auth_service.dart';

/// Provider for authentication state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.authStateChanges;
});

/// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider to check if user is signed in
final isSignedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Provider to check if user is anonymous
final isAnonymousProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isAnonymous ?? true;
});

/// Provider for user display name
final userDisplayNameProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    return user.displayName ?? user.email ?? 'Guest User';
  }
  return 'Guest User';
});

/// Provider for user photo URL
final userPhotoURLProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.photoURL;
});

/// Provider for user email
final userEmailProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email;
});

/// Authentication controller for handling auth actions
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

/// Authentication controller class
class AuthController {
  final Ref _ref;

  AuthController(this._ref);

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      return await AuthService.signInWithGoogle();
    } catch (e) {
      throw AuthException('Failed to sign in with Google: $e', 'google-signin-failed');
    }
  }

  /// Sign in with Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      return await AuthService.signInWithFacebook();
    } catch (e) {
      throw AuthException('Failed to sign in with Facebook: $e', 'facebook-signin-failed');
    }
  }

  /// Sign in as guest
  Future<UserCredential?> signInAsGuest() async {
    try {
      return await AuthService.signInAsGuest();
    } catch (e) {
      throw AuthException('Failed to sign in as guest: $e', 'guest-signin-failed');
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await AuthService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      if (e is FirebaseAuthException) {
        throw AuthException(e.friendlyMessage, e.code);
      }
      throw AuthException('Failed to sign in: $e', 'signin-failed');
    }
  }

  /// Create account with email and password
  Future<UserCredential?> createAccountWithEmailAndPassword(String email, String password) async {
    try {
      return await AuthService.createAccountWithEmailAndPassword(email, password);
    } catch (e) {
      if (e is FirebaseAuthException) {
        throw AuthException(e.friendlyMessage, e.code);
      }
      throw AuthException('Failed to create account: $e', 'create-account-failed');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await AuthService.sendPasswordResetEmail(email);
    } catch (e) {
      if (e is FirebaseAuthException) {
        throw AuthException(e.friendlyMessage, e.code);
      }
      throw AuthException('Failed to send password reset email: $e', 'password-reset-failed');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      await AuthService.updateUserProfile(displayName: displayName, photoURL: photoURL);
    } catch (e) {
      throw AuthException('Failed to update profile: $e', 'update-profile-failed');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await AuthService.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: $e', 'signout-failed');
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      await AuthService.deleteAccount();
    } catch (e) {
      throw AuthException('Failed to delete account: $e', 'delete-account-failed');
    }
  }

  /// Convert guest account to Google account
  Future<UserCredential?> convertGuestToGoogle() async {
    try {
      return await AuthService.convertGuestToGoogle();
    } catch (e) {
      throw AuthException('Failed to convert guest account: $e', 'convert-account-failed');
    }
  }

  /// Convert guest account to Facebook account
  Future<UserCredential?> convertGuestToFacebook() async {
    try {
      return await AuthService.convertGuestToFacebook();
    } catch (e) {
      throw AuthException('Failed to convert guest account: $e', 'convert-account-failed');
    }
  }
}

/// Authentication exception class
class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException(this.message, this.code);

  @override
  String toString() => 'AuthException: $message (Code: $code)';
}