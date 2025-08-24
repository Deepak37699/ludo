import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ludo_game/main.dart' as app;
import 'package:ludo_game/core/enums/game_enums.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Comprehensive Ludo Game Integration Tests', () {
    
    testWidgets('Full Game Lifecycle Test', (WidgetTester tester) async {
      // Initialize the app
      await app.main();
      await tester.pumpAndSettle();

      // Verify home screen
      expect(find.text('Ludo King'), findsOneWidget);

      // Navigate to single player
      await tester.tap(find.text('Play vs AI'));
      await tester.pumpAndSettle();

      // Select difficulty
      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();

      // Start game
      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify game screen loaded
      expect(find.byKey(const Key('game_board')), findsOneWidget);
      expect(find.byKey(const Key('dice_widget')), findsOneWidget);

      // Play multiple rounds
      for (int round = 0; round < 3; round++) {
        await _playGameRound(tester);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify game is still playable
      expect(find.byKey(const Key('game_board')), findsOneWidget);
    });

    testWidgets('Settings Integration Test', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Test various settings changes
      await _testSettingsFlow(tester);

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify we're back at home
      expect(find.text('Ludo King'), findsOneWidget);
    });

    testWidgets('Profile and Statistics Test', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Verify profile elements
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);

      // Check achievements section
      await tester.tap(find.text('Achievements'));
      await tester.pumpAndSettle();

      expect(find.text('Achievements'), findsOneWidget);

      // Navigate back to profile
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Go back to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    });

    testWidgets('Performance Monitoring Test', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Navigate to performance settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      if (find.text('Performance').evaluate().isNotEmpty) {
        await tester.tap(find.text('Performance'));
        await tester.pumpAndSettle();

        // Verify performance metrics are shown
        expect(find.textContaining('FPS'), findsWidgets);
        expect(find.textContaining('Memory'), findsWidgets);

        // Test performance actions
        if (find.text('Optimize Now').evaluate().isNotEmpty) {
          await tester.tap(find.text('Optimize Now'));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    });

    testWidgets('Accessibility Features Test', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Navigate to accessibility settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      if (find.text('Accessibility').evaluate().isNotEmpty) {
        await tester.tap(find.text('Accessibility'));
        await tester.pumpAndSettle();

        // Test accessibility toggles
        await _testAccessibilityFeatures(tester);

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    });

    testWidgets('Offline Mode Test', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Simulate offline condition
      await _simulateOfflineMode(tester);

      // Verify offline indicator
      expect(find.textContaining('Offline'), findsWidgets);

      // Start offline game
      await tester.tap(find.text('Play vs AI'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Easy'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify game works offline
      expect(find.byKey(const Key('game_board')), findsOneWidget);

      // Play a round offline
      await _playGameRound(tester);
      await tester.pumpAndSettle();
    });

    testWidgets('Theme and Customization Test', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Navigate to theme settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      if (find.text('Themes').evaluate().isNotEmpty) {
        await tester.tap(find.text('Themes'));
        await tester.pumpAndSettle();

        // Test theme switching
        await _testThemeChanges(tester);

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    });

    testWidgets('Game State Persistence Test', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Start a game
      await tester.tap(find.text('Play vs AI'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Make some moves
      await _playGameRound(tester);
      await tester.pumpAndSettle();

      // Pause game
      if (find.byIcon(Icons.pause).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pumpAndSettle();

        // Exit game
        if (find.text('Exit Game').evaluate().isNotEmpty) {
          await tester.tap(find.text('Exit Game'));
          await tester.pumpAndSettle();
        }
      }

      // Verify we can continue the game
      if (find.text('Continue Game').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue Game'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('game_board')), findsOneWidget);
      }
    });

    testWidgets('Error Handling and Recovery Test', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Test invalid actions
      await _testErrorScenarios(tester);

      // Verify app remains stable
      expect(find.text('Ludo King'), findsOneWidget);
    });

    testWidgets('Memory and Performance Stress Test', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // Start multiple games in sequence
      for (int i = 0; i < 3; i++) {
        await _startAndPlayQuickGame(tester);
        await tester.pumpAndSettle();
      }

      // Verify app performance remains stable
      expect(find.text('Ludo King'), findsOneWidget);
    });
  });
}

/// Helper function to play a game round
Future<void> _playGameRound(WidgetTester tester) async {
  // Find and tap dice if available
  final diceWidget = find.byKey(const Key('dice_widget'));
  if (diceWidget.evaluate().isNotEmpty) {
    await tester.tap(diceWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Look for movable tokens
    final tokenWidgets = find.byKey(const Key('token_widget'));
    if (tokenWidgets.evaluate().isNotEmpty) {
      await tester.tap(tokenWidgets.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Look for valid move positions
      final validMovePositions = find.byKey(const Key('valid_move_position'));
      if (validMovePositions.evaluate().isNotEmpty) {
        await tester.tap(validMovePositions.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    }
  }

  // Wait for AI turn
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

/// Helper function to test settings flow
Future<void> _testSettingsFlow(WidgetTester tester) async {
  // Test sound toggle
  if (find.byKey(const Key('sound_toggle')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('sound_toggle')));
    await tester.pumpAndSettle();
  }

  // Test theme selection
  if (find.text('Dark Theme').evaluate().isNotEmpty) {
    await tester.tap(find.text('Dark Theme'));
    await tester.pumpAndSettle();
  }

  // Test language selection
  if (find.text('Language').evaluate().isNotEmpty) {
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    if (find.text('English').evaluate().isNotEmpty) {
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
  }
}

/// Helper function to test accessibility features
Future<void> _testAccessibilityFeatures(WidgetTester tester) async {
  // Test screen reader toggle
  if (find.byKey(const Key('screen_reader_toggle')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('screen_reader_toggle')));
    await tester.pumpAndSettle();
  }

  // Test high contrast toggle
  if (find.byKey(const Key('high_contrast_toggle')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('high_contrast_toggle')));
    await tester.pumpAndSettle();
  }

  // Test large text toggle
  if (find.byKey(const Key('large_text_toggle')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('large_text_toggle')));
    await tester.pumpAndSettle();
  }
}

/// Helper function to simulate offline mode
Future<void> _simulateOfflineMode(WidgetTester tester) async {
  // Simulate network disconnection
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
}

/// Helper function to test theme changes
Future<void> _testThemeChanges(WidgetTester tester) async {
  final themes = ['Classic', 'Royal', 'Modern', 'Nature'];
  
  for (final theme in themes) {
    if (find.text(theme).evaluate().isNotEmpty) {
      await tester.tap(find.text(theme));
      await tester.pumpAndSettle();
      break; // Test one theme change
    }
  }
}

/// Helper function to test error scenarios
Future<void> _testErrorScenarios(WidgetTester tester) async {
  // Try to start game without selecting options
  await tester.tap(find.text('Play vs AI'));
  await tester.pumpAndSettle();

  // Try to start without selecting difficulty
  if (find.text('Start Game').evaluate().isNotEmpty) {
    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();
    
    // Should show error or remain on setup screen
    // No assertion needed, just verify app doesn't crash
  }

  // Go back to home
  while (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    
    if (find.text('Ludo King').evaluate().isNotEmpty) {
      break;
    }
  }
}

/// Helper function to start and play a quick game
Future<void> _startAndPlayQuickGame(WidgetTester tester) async {
  // Start game
  await tester.tap(find.text('Play vs AI'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Easy'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Start Game'));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Play a few rounds
  for (int i = 0; i < 2; i++) {
    await _playGameRound(tester);
    await tester.pumpAndSettle();
  }

  // Exit game
  if (find.byIcon(Icons.pause).evaluate().isNotEmpty) {
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pumpAndSettle();

    if (find.text('Exit Game').evaluate().isNotEmpty) {
      await tester.tap(find.text('Exit Game'));
      await tester.pumpAndSettle();
    }
  }

  // Navigate back to home if needed
  while (!find.text('Ludo King').evaluate().isNotEmpty) {
    if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    } else {
      break;
    }
  }
}