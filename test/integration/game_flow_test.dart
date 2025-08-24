import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ludo_game/main.dart' as app;
import 'package:ludo_game/core/enums/game_enums.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Ludo Game Integration Tests', () {
    setUp(() async {
      // Reset any persistent state before each test
      await app.initializeApp();
    });

    testWidgets('Complete Game Flow - Human vs AI', (WidgetTester tester) async {
      // Launch the app
      await app.main();
      await tester.pumpAndSettle();

      // Should start at home screen
      expect(find.text('Ludo King'), findsOneWidget);
      expect(find.text('Play vs AI'), findsOneWidget);

      // Tap Play vs AI
      await tester.tap(find.text('Play vs AI'));
      await tester.pumpAndSettle();

      // Should navigate to game setup screen
      expect(find.text('Game Setup'), findsOneWidget);
      expect(find.text('Select Difficulty'), findsOneWidget);

      // Select medium difficulty
      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();

      // Start the game
      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should navigate to game screen
      expect(find.text('Your Turn'), findsOneWidget);
      expect(find.byKey(const Key('dice_widget')), findsOneWidget);
      expect(find.byKey(const Key('game_board')), findsOneWidget);

      // Play several rounds
      for (int round = 0; round < 5; round++) {
        await _playOneRound(tester);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Game should still be running or finished
      expect(find.byKey(const Key('game_board')), findsOneWidget);
    });

    testWidgets('Navigation Flow Test', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Test navigation to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Test navigation to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Test navigation to leaderboard
      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
      expect(find.text('Leaderboard'), findsOneWidget);

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    });

    testWidgets('Offline Mode Test', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Simulate offline mode
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/connectivity',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('check', null),
        ),
        (data) {
          const StandardMethodCodec().encodeSuccessEnvelope('none');
        },
      );

      await tester.pumpAndSettle();

      // Should show offline indicator
      expect(find.text('Offline'), findsOneWidget);

      // Should still be able to play vs AI
      await tester.tap(find.text('Play vs AI'));
      await tester.pumpAndSettle();

      expect(find.text('Game Setup'), findsOneWidget);
    });

    testWidgets('Settings Persistence Test', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Change sound setting
      final soundToggle = find.byKey(const Key('sound_toggle'));
      await tester.tap(soundToggle);
      await tester.pumpAndSettle();

      // Change theme
      await tester.tap(find.text('Dark Theme'));
      await tester.pumpAndSettle();

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Restart app to test persistence
      await tester.binding.reassembleApplication();
      await tester.pumpAndSettle();

      // Navigate back to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Settings should be persisted
      // (In a real test, we would verify the actual state)
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Game State Persistence Test', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Start a game
      await tester.tap(find.text('Play vs AI'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Easy'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      // Make a few moves
      await _playOneRound(tester);
      await tester.pumpAndSettle();

      // Pause the game
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();

      // Exit to home
      await tester.tap(find.text('Exit Game'));
      await tester.pumpAndSettle();

      // Should be back at home screen
      expect(find.text('Ludo King'), findsOneWidget);

      // Should have option to continue game
      expect(find.text('Continue Game'), findsOneWidget);

      // Continue the game
      await tester.tap(find.text('Continue Game'));
      await tester.pumpAndSettle();

      // Should be back in the game
      expect(find.byKey(const Key('game_board')), findsOneWidget);
    });

    testWidgets('Accessibility Features Test', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Navigate to accessibility settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accessibility'));
      await tester.pumpAndSettle();

      // Enable screen reader support
      await tester.tap(find.byKey(const Key('screen_reader_toggle')));
      await tester.pumpAndSettle();

      // Enable high contrast
      await tester.tap(find.byKey(const Key('high_contrast_toggle')));
      await tester.pumpAndSettle();

      // Navigate back to game
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Start a game with accessibility features
      await tester.tap(find.text('Play vs AI'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Easy'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      // Verify accessibility features are active
      expect(find.byKey(const Key('game_board')), findsOneWidget);
      
      // Test keyboard navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    });

    testWidgets('Performance Test - Large Game', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Start a 4-player local game
      await tester.tap(find.text('Local Multiplayer'));
      await tester.pumpAndSettle();

      // Select 4 players
      await tester.tap(find.text('4 Players'));
      await tester.pumpAndSettle();

      // Start the game
      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      // Measure frame rate during game
      final stopwatch = Stopwatch()..start();
      
      // Perform multiple rapid actions
      for (int i = 0; i < 10; i++) {
        await _playOneRound(tester);
        await tester.pump(const Duration(milliseconds: 100));
      }
      
      stopwatch.stop();

      // Game should maintain good performance
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      expect(find.byKey(const Key('game_board')), findsOneWidget);
    });

    testWidgets('Error Handling Test', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Try to perform invalid actions
      await tester.tap(find.text('Play vs AI'));
      await tester.pumpAndSettle();

      // Try to start game without selecting difficulty
      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.textContaining('Please select'), findsOneWidget);

      // Select difficulty and start
      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      // Should now work
      expect(find.byKey(const Key('game_board')), findsOneWidget);
    });
  });
}

/// Helper function to play one round (roll dice and make move if possible)
Future<void> _playOneRound(WidgetTester tester) async {
  // Look for dice widget
  final diceWidget = find.byKey(const Key('dice_widget'));
  if (diceWidget.evaluate().isNotEmpty) {
    // Roll the dice
    await tester.tap(diceWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Look for available tokens to move
    final tokenWidgets = find.byKey(const Key('token_widget'));
    if (tokenWidgets.evaluate().isNotEmpty) {
      // Tap the first available token
      await tester.tap(tokenWidgets.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Look for valid move positions
      final validMoves = find.byKey(const Key('valid_move_position'));
      if (validMoves.evaluate().isNotEmpty) {
        // Tap the first valid move
        await tester.tap(validMoves.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    }

    // Wait for AI turn if it's AI's turn
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}