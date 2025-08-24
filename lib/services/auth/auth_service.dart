import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';

/// Authentication service that handles user authentication
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of authentication state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  static bool get isSignedIn => currentUser != null;

  /// Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      debugPrint('Google Sign-In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      rethrow;
    }
  }

  /// Sign in with Facebook
  static Future<UserCredential?> signInWithFacebook() async {
    try {
      // Trigger the Facebook authentication flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        // Get the access token
        final AccessToken accessToken = result.accessToken!;

        // Create a credential from the access token
        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(accessToken.tokenString);

        // Sign in to Firebase with the Facebook credential
        final UserCredential userCredential =
            await _auth.signInWithCredential(facebookAuthCredential);

        debugPrint('Facebook Sign-In successful: ${userCredential.user?.email}');
        return userCredential;
      } else {
        debugPrint('Facebook Sign-In failed: ${result.status}');
        return null;
      }
    } catch (e) {
      debugPrint('Facebook Sign-In failed: $e');
      rethrow;
    }
  }

  /// Sign in as guest (anonymous)
  static Future<UserCredential?> signInAsGuest() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      debugPrint('Guest Sign-In successful: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      debugPrint('Guest Sign-In failed: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Email Sign-In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('Email Sign-In failed: $e');
      rethrow;
    }
  }

  /// Create account with email and password
  static Future<UserCredential?> createAccountWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Account creation successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('Account creation failed: $e');
      rethrow;
    }
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent to: $email');
    } catch (e) {
      debugPrint('Failed to send password reset email: $e');
      rethrow;
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final User? user = currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
        await user.reload();
        debugPrint('User profile updated successfully');
      }
    } catch (e) {
      debugPrint('Failed to update user profile: $e');
      rethrow;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      // Sign out from all providers
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        FacebookAuth.instance.logOut(),
      ]);
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Sign out failed: $e');
      rethrow;
    }
  }

  /// Delete user account
  static Future<void> deleteAccount() async {
    try {
      final User? user = currentUser;
      if (user != null) {
        await user.delete();
        debugPrint('User account deleted successfully');
      }
    } catch (e) {
      debugPrint('Failed to delete user account: $e');
      rethrow;
    }
  }

  /// Get user display name
  static String getUserDisplayName() {
    final User? user = currentUser;
    if (user != null) {
      return user.displayName ?? user.email ?? 'Guest User';
    }
    return 'Guest User';
  }

  /// Get user photo URL
  static String? getUserPhotoURL() {
    final User? user = currentUser;
    return user?.photoURL;
  }

  /// Get user email
  static String? getUserEmail() {
    final User? user = currentUser;
    return user?.email;
  }

  /// Check if user is anonymous (guest)
  static bool get isAnonymous => currentUser?.isAnonymous ?? true;

  /// Link anonymous account with credential
  static Future<UserCredential?> linkAnonymousAccount(
      AuthCredential credential) async {
    try {
      final User? user = currentUser;
      if (user != null && user.isAnonymous) {
        final UserCredential userCredential =
            await user.linkWithCredential(credential);
        debugPrint('Anonymous account linked successfully');
        return userCredential;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to link anonymous account: $e');
      rethrow;
    }
  }

  /// Convert guest account to Google account
  static Future<UserCredential?> convertGuestToGoogle() async {
    try {
      if (isAnonymous) {
        // Get Google credential
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Link the credential
        return await linkAnonymousAccount(credential);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to convert guest to Google account: $e');
      rethrow;
    }
  }

  /// Convert guest account to Facebook account
  static Future<UserCredential?> convertGuestToFacebook() async {
    try {
      if (isAnonymous) {
        // Get Facebook credential
        final LoginResult result = await FacebookAuth.instance.login(
          permissions: ['email', 'public_profile'],
        );

        if (result.status == LoginStatus.success) {
          final AccessToken accessToken = result.accessToken!;
          final OAuthCredential credential =
              FacebookAuthProvider.credential(accessToken.tokenString);

          // Link the credential
          return await linkAnonymousAccount(credential);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Failed to convert guest to Facebook account: $e');
      rethrow;
    }
  }

  /// Get authentication provider ID
  static String? getProviderID() {
    final User? user = currentUser;
    if (user != null && user.providerData.isNotEmpty) {
      return user.providerData.first.providerId;
    }
    return null;
  }

  /// Check if user signed in with specific provider
  static bool isSignedInWith(String providerId) {
    final User? user = currentUser;
    if (user != null) {
      return user.providerData.any((info) => info.providerId == providerId);
    }
    return false;
  }
}

/// Authentication exceptions
class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException(this.message, this.code);

  @override
  String toString() => 'AuthException: $message (Code: $code)';
}

/// Extension for handling Firebase Auth exceptions
extension FirebaseAuthExceptionHandler on FirebaseAuthException {
  String get friendlyMessage {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return message ?? 'An unexpected error occurred.';
    }
  }
}"