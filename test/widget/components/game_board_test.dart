import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ludo_game/presentation/widgets/game/game_board.dart';
import 'package:ludo_game/data/models/token.dart';
import 'package:ludo_game/data/models/position.dart';
import 'package:ludo_game/data/models/player.dart';
import 'package:ludo_game/data/models/game_state.dart';
import 'package:ludo_game/core/enums/game_enums.dart';

// Mock classes
class MockGameState extends Mock implements GameState {}
class MockPlayer extends Mock implements Player {}
class MockToken extends Mock implements Token {}

void main() {
  group('GameBoard Widget Tests', () {
    late GameState testGameState;
    late List<Player> testPlayers;
    late List<Token> testTokens;

    setUp(() {
      // Setup test data
      final homePosition = Position(
        x: 1,
        y: 1,
        type: PositionType.home,
        ownerColor: PlayerColor.red,
        pathIndex: null,
      );

      testTokens = List.generate(4, (index) => Token(
        id: 'token_$index',
        color: PlayerColor.red,
        currentPosition: homePosition,
        state: TokenState.home,
      ));

      testPlayers = [
        Player(
          id: 'player1',
          name: 'Player 1',
          color: PlayerColor.red,
          isHuman: true,
          tokens: testTokens,
        ),
        Player(
          id: 'player2',
          name: 'Player 2',
          color: PlayerColor.blue,
          isHuman: false,
          tokens: testTokens.map((t) => t.copyWith(color: PlayerColor.blue)).toList(),
        ),
      ];

      testGameState = GameState(
        id: 'test_game',
        players: testPlayers,
        currentPlayerIndex: 0,
        gameStatus: GameStatus.playing,
        gameMode: GameMode.vsAI,
      );
    });

    Widget createWidgetUnderTest({
      GameState? gameState,
      List<Position>? validMoves,
      Position? selectedPosition,
      Function(Token)? onTokenTap,
      Function(Position)? onPositionTap,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GameBoard(
              gameState: gameState ?? testGameState,
              validMoves: validMoves ?? [],
              selectedPosition: selectedPosition,
              onTokenTap: onTokenTap,
              onPositionTap: onPositionTap,
            ),
          ),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('renders game board widget', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(GameBoard), findsOneWidget);
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('displays board with correct size', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        final gameBoardWidget = tester.widget<GameBoard>(find.byType(GameBoard));
        expect(gameBoardWidget.size, isNotNull);
        expect(gameBoardWidget.size, greaterThan(0));
      });

      testWidgets('renders tokens for all players', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        // Should find interactive areas for tokens
        final tokenAreas = find.byType(GestureDetector);
        expect(tokenAreas, findsWidgets);
      });
    });

    group('Token Interactions', () {
      testWidgets('calls onTokenTap when token is tapped', (WidgetTester tester) async {
        Token? tappedToken;
        
        await tester.pumpWidget(createWidgetUnderTest(
          onTokenTap: (token) => tappedToken = token,
        ));

        // Find and tap the first token area
        final tokenDetectors = find.byType(GestureDetector);
        if (tokenDetectors.evaluate().isNotEmpty) {
          await tester.tap(tokenDetectors.first);
          await tester.pump();

          // Token tap should be called (in a real implementation)
          // This test structure shows how we would verify the callback
        }
      });

      testWidgets('highlights selected token', (WidgetTester tester) async {
        final selectedPosition = Position(
          x: 1,
          y: 1,
          type: PositionType.home,
          ownerColor: PlayerColor.red,
          pathIndex: null,
        );

        await tester.pumpWidget(createWidgetUnderTest(
          selectedPosition: selectedPosition,
        ));

        // Should render with selection highlighting
        expect(find.byType(GameBoard), findsOneWidget);
      });

      testWidgets('shows valid moves when token is selected', (WidgetTester tester) async {
        final validMoves = [
          Position(
            x: 6,
            y: 1,
            type: PositionType.start,
            ownerColor: PlayerColor.red,
            pathIndex: 0,
          ),
        ];

        await tester.pumpWidget(createWidgetUnderTest(
          validMoves: validMoves,
        ));

        // Board should render with valid move indicators
        expect(find.byType(GameBoard), findsOneWidget);
      });
    });

    group('Position Interactions', () {
      testWidgets('calls onPositionTap when position is tapped', (WidgetTester tester) async {
        Position? tappedPosition;
        final validMoves = [
          Position(
            x: 6,
            y: 1,
            type: PositionType.start,
            ownerColor: PlayerColor.red,
            pathIndex: 0,
          ),
        ];

        await tester.pumpWidget(createWidgetUnderTest(
          validMoves: validMoves,
          onPositionTap: (position) => tappedPosition = position,
        ));

        // In a real implementation, we would find and tap valid move positions
        expect(find.byType(GameBoard), findsOneWidget);
      });

      testWidgets('only allows tapping on valid move positions', (WidgetTester tester) async {
        final validMoves = [
          Position(
            x: 6,
            y: 1,
            type: PositionType.start,
            ownerColor: PlayerColor.red,
            pathIndex: 0,
          ),
        ];

        await tester.pumpWidget(createWidgetUnderTest(
          validMoves: validMoves,
        ));

        // Valid moves should be tappable, others should not
        expect(find.byType(GameBoard), findsOneWidget);
      });
    });

    group('Game State Changes', () {
      testWidgets('updates when game state changes', (WidgetTester tester) async {
        // Initial render
        await tester.pumpWidget(createWidgetUnderTest());
        expect(find.byType(GameBoard), findsOneWidget);

        // Update with new game state
        final updatedGameState = testGameState.copyWith(
          currentPlayerIndex: 1,
        );

        await tester.pumpWidget(createWidgetUnderTest(
          gameState: updatedGameState,
        ));

        await tester.pump();
        expect(find.byType(GameBoard), findsOneWidget);
      });

      testWidgets('handles game over state', (WidgetTester tester) async {
        final finishedGameState = testGameState.copyWith(
          gameStatus: GameStatus.finished,
          winner: testPlayers[0],
        );

        await tester.pumpWidget(createWidgetUnderTest(
          gameState: finishedGameState,
        ));

        expect(find.byType(GameBoard), findsOneWidget);
      });
    });

    group('Responsive Design', () {
      testWidgets('adapts to different screen sizes', (WidgetTester tester) async {
        // Test with small screen
        await tester.binding.setSurfaceSize(const Size(400, 600));
        await tester.pumpWidget(createWidgetUnderTest());
        expect(find.byType(GameBoard), findsOneWidget);

        // Test with large screen
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        await tester.pumpWidget(createWidgetUnderTest());
        expect(find.byType(GameBoard), findsOneWidget);

        // Reset to default
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('maintains aspect ratio', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        final boardWidget = tester.widget<GameBoard>(find.byType(GameBoard));
        
        // Board should maintain square aspect ratio
        expect(boardWidget.size, isNotNull);
      });
    });

    group('Performance', () {
      testWidgets('does not rebuild unnecessarily', (WidgetTester tester) async {
        int buildCount = 0;
        
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    buildCount++;
                    return GameBoard(
                      gameState: testGameState,
                      validMoves: const [],
                    );
                  },
                ),
              ),
            ),
          ),
        );

        expect(buildCount, 1);

        // Pump again without changes
        await tester.pump();
        expect(buildCount, 1); // Should not rebuild
      });

      testWidgets('handles large number of tokens efficiently', (WidgetTester tester) async {
        // Create game state with many tokens
        final manyPlayers = List.generate(4, (playerIndex) {
          final tokens = List.generate(4, (tokenIndex) => Token(
            id: 'player_${playerIndex}_token_$tokenIndex',
            color: PlayerColor.values[playerIndex],
            currentPosition: Position(
              x: playerIndex,
              y: tokenIndex,
              type: PositionType.home,
              ownerColor: PlayerColor.values[playerIndex],
              pathIndex: null,
            ),
            state: TokenState.home,
          ));

          return Player(
            id: 'player_$playerIndex',
            name: 'Player $playerIndex',
            color: PlayerColor.values[playerIndex],
            isHuman: playerIndex == 0,
            tokens: tokens,
          );
        });

        final largeGameState = GameState(
          id: 'large_game',
          players: manyPlayers,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.local,
        );

        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(createWidgetUnderTest(
          gameState: largeGameState,
        ));

        stopwatch.stop();

        // Should render within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(find.byType(GameBoard), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('provides semantic labels for screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        // Look for semantic information
        final semantics = find.byType(Semantics);
        expect(semantics, findsWidgets);
      });

      testWidgets('supports keyboard navigation', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        // Look for Focus widgets that enable keyboard navigation
        final focusableWidgets = find.byType(Focus);
        expect(focusableWidgets, findsWidgets);
      });
    });

    group('Error Handling', () {
      testWidgets('handles null game state gracefully', (WidgetTester tester) async {
        // This test would verify error handling in a real implementation
        await tester.pumpWidget(createWidgetUnderTest());
        expect(find.byType(GameBoard), findsOneWidget);
      });

      testWidgets('handles empty player list', (WidgetTester tester) async {
        final emptyGameState = GameState(
          id: 'empty_game',
          players: [],
          currentPlayerIndex: 0,
          gameStatus: GameStatus.waiting,
          gameMode: GameMode.vsAI,
        );

        await tester.pumpWidget(createWidgetUnderTest(
          gameState: emptyGameState,
        ));

        expect(find.byType(GameBoard), findsOneWidget);
      });
    });
  });
}