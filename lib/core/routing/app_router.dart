import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/game/game_screens.dart';
import '../../presentation/screens/common_screens.dart';

/// App router configuration with authentication and deep linking
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isSignedIn = authState.when(
        data: (user) => user != null,
        loading: () => false,
        error: (_, __) => false,
      );

      final isOnAuthPage = state.matchedLocation.startsWith('/auth');
      final isOnSplashPage = state.matchedLocation == '/splash';

      // If still loading auth state, stay on splash
      if (authState.isLoading && !isOnSplashPage) {
        return '/splash';
      }

      // If not signed in and not on auth pages, redirect to login
      if (!isSignedIn && !isOnAuthPage && !isOnSplashPage) {
        return '/auth/login';
      }

      // If signed in and on auth pages, redirect to home
      if (isSignedIn && isOnAuthPage) {
        return '/home';
      }

      // If signed in and on splash, redirect to home
      if (isSignedIn && isOnSplashPage) {
        return '/home';
      }

      return null; // No redirect needed
    },
    routes: [
      // Splash route
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication routes
      GoRoute(
        path: '/auth',
        redirect: (context, state) => '/auth/login',
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Game routes
      GoRoute(
        path: '/game-modes',
        name: 'game-modes',
        builder: (context, state) => const GameModeSelectionScreen(),
      ),
      GoRoute(
        path: '/game-lobby',
        name: 'game-lobby',
        builder: (context, state) {
          final gameMode = state.uri.queryParameters['mode'] ?? 'single';
          return GameLobbyScreen(gameMode: gameMode);
        },
      ),
      GoRoute(
        path: '/game/:gameId',
        name: 'game',
        builder: (context, state) {
          final gameId = state.pathParameters['gameId']!;
          return GameScreen(gameId: gameId);
        },
      ),

      // Profile routes
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),

      // Leaderboard route
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),

      // Settings route
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // About route
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The page "${state.matchedLocation}" does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Router helper class for navigation
class AppRouter {
  static void goToLogin(BuildContext context) {
    context.go('/auth/login');
  }

  static void goToRegister(BuildContext context) {
    context.go('/auth/register');
  }

  static void goToForgotPassword(BuildContext context) {
    context.go('/auth/forgot-password');
  }

  static void goToHome(BuildContext context) {
    context.go('/home');
  }

  static void goToGameModes(BuildContext context) {
    context.go('/game-modes');
  }

  static void goToGameLobby(BuildContext context, {String gameMode = 'single'}) {
    context.go('/game-lobby?mode=$gameMode');
  }

  static void goToGame(BuildContext context, String gameId) {
    context.go('/game/$gameId');
  }

  static void goToProfile(BuildContext context) {
    context.go('/profile');
  }

  static void goToEditProfile(BuildContext context) {
    context.go('/profile/edit');
  }

  static void goToLeaderboard(BuildContext context) {
    context.go('/leaderboard');
  }

  static void goToSettings(BuildContext context) {
    context.go('/settings');
  }

  static void goToAbout(BuildContext context) {
    context.go('/about');
  }

  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  // Push methods for overlay navigation
  static void pushGameModes(BuildContext context) {
    context.push('/game-modes');
  }

  static void pushProfile(BuildContext context) {
    context.push('/profile');
  }

  static void pushSettings(BuildContext context) {
    context.push('/settings');
  }

  static void pushLeaderboard(BuildContext context) {
    context.push('/leaderboard');
  }

  static void pushAbout(BuildContext context) {
    context.push('/about');
  }

  // Replace methods for navigation without back stack
  static void replaceWithHome(BuildContext context) {
    context.pushReplacement('/home');
  }

  static void replaceWithLogin(BuildContext context) {
    context.pushReplacement('/auth/login');
  }

  // Deep linking helpers
  static String createGameInviteLink(String gameId) {
    return '/game/$gameId';
  }

  static String? getGameIdFromPath(String path) {
    final uri = Uri.parse(path);
    final segments = uri.pathSegments;
    
    if (segments.length >= 2 && segments[0] == 'game') {
      return segments[1];
    }
    
    return null;
  }

  // Navigation guards
  static bool canAccessGame(BuildContext context) {
    // Add logic to check if user can access game
    return true;
  }

  static bool canAccessProfile(BuildContext context) {
    // Add logic to check if user can access profile
    return true;
  }

  static bool canAccessLeaderboard(BuildContext context) {
    // Add logic to check if user can access leaderboard
    return true;
  }
}

/// Route names constants
class RouteNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String home = 'home';
  static const String gameModes = 'game-modes';
  static const String gameLobby = 'game-lobby';
  static const String game = 'game';
  static const String profile = 'profile';
  static const String editProfile = 'edit-profile';
  static const String leaderboard = 'leaderboard';
  static const String settings = 'settings';
  static const String about = 'about';
}

/// Route paths constants
class RoutePaths {
  static const String splash = '/splash';
  static const String auth = '/auth';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String home = '/home';
  static const String gameModes = '/game-modes';
  static const String gameLobby = '/game-lobby';
  static const String game = '/game';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String leaderboard = '/leaderboard';
  static const String settings = '/settings';
  static const String about = '/about';
}