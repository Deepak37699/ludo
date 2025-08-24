import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ludo_game/services/game/game_logic_service.dart';
import 'package:ludo_game/data/models/token.dart';
import 'package:ludo_game/data/models/position.dart';
import 'package:ludo_game/data/models/player.dart';
import 'package:ludo_game/data/models/game_state.dart';
import 'package:ludo_game/core/enums/game_enums.dart';

// Mock classes
class MockToken extends Mock implements Token {}
class MockPosition extends Mock implements Position {}
class MockPlayer extends Mock implements Player {}
class MockGameState extends Mock implements GameState {}

void main() {
  group('GameLogicService', () {
    late GameLogicService gameLogicService;
    late Position homePosition;
    late Position startPosition;
    late Position pathPosition;
    late Position finishPosition;
    late Token testToken;
    late Player testPlayer;
    late GameState testGameState;

    setUp(() {
      gameLogicService = GameLogicService();
      
      homePosition = Position(
        x: 1,
        y: 1,
        type: PositionType.home,
        ownerColor: PlayerColor.red,
        pathIndex: null,
      );
      
      startPosition = Position(
        x: 6,
        y: 1,
        type: PositionType.start,
        ownerColor: PlayerColor.red,
        pathIndex: 0,
      );
      
      pathPosition = Position(
        x: 7,
        y: 1,
        type: PositionType.path,
        ownerColor: null,
        pathIndex: 1,
      );
      
      finishPosition = Position(
        x: 7,
        y: 7,
        type: PositionType.finish,
        ownerColor: PlayerColor.red,
        pathIndex: 51,
      );

      testToken = Token(
        id: 'token1',
        color: PlayerColor.red,
        currentPosition: homePosition,
        state: TokenState.home,
      );

      final tokens = List.generate(4, (index) => Token(
        id: 'token_$index',
        color: PlayerColor.red,
        currentPosition: homePosition,
        state: TokenState.home,
      ));

      testPlayer = Player(
        id: 'player1',
        name: 'Test Player',
        color: PlayerColor.red,
        isHuman: true,
        tokens: tokens,
      );

      testGameState = GameState(
        id: 'game1',
        players: [testPlayer],
        currentPlayerIndex: 0,
        gameStatus: GameStatus.playing,
        gameMode: GameMode.vsAI,
      );
    });

    group('canMoveToken', () {
      test('returns true when token can exit home with dice 6', () {
        final result = gameLogicService.canMoveToken(
          token: testToken,
          diceValue: 6,
          gameState: testGameState,
        );

        expect(result, true);
      });

      test('returns false when token cannot exit home without dice 6', () {
        final result = gameLogicService.canMoveToken(
          token: testToken,
          diceValue: 4,
          gameState: testGameState,
        );

        expect(result, false);
      });

      test('returns true when active token can move', () {
        final activeToken = testToken.copyWith(
          state: TokenState.active,
          currentPosition: startPosition,
        );

        final result = gameLogicService.canMoveToken(
          token: activeToken,
          diceValue: 4,
          gameState: testGameState,
        );

        expect(result, true);
      });

      test('returns false when token is finished', () {
        final finishedToken = testToken.copyWith(
          state: TokenState.finished,
          currentPosition: finishPosition,
        );

        final result = gameLogicService.canMoveToken(
          token: finishedToken,
          diceValue: 6,
          gameState: testGameState,
        );

        expect(result, false);
      });

      test('returns false when token is animating', () {
        final animatingToken = testToken.copyWith(
          state: TokenState.active,
          currentPosition: startPosition,
          isAnimating: true,
        );

        final result = gameLogicService.canMoveToken(
          token: animatingToken,
          diceValue: 4,
          gameState: testGameState,
        );

        expect(result, false);
      });
    });

    group('calculateNewPosition', () {
      test('calculates new position from start', () {
        final activeToken = testToken.copyWith(
          state: TokenState.active,
          currentPosition: startPosition,
        );

        final newPosition = gameLogicService.calculateNewPosition(
          token: activeToken,
          diceValue: 3,
        );

        expect(newPosition, isNotNull);
        expect(newPosition!.pathIndex, 3);
      });

      test('returns null when move would exceed board', () {
        final tokenNearFinish = testToken.copyWith(
          state: TokenState.active,
          currentPosition: Position(
            x: 7,
            y: 6,
            type: PositionType.path,
            ownerColor: null,
            pathIndex: 50,
          ),
        );

        final newPosition = gameLogicService.calculateNewPosition(
          token: tokenNearFinish,
          diceValue: 6, // Would exceed 51 (max path index)
        );

        expect(newPosition, isNull);
      });

      test('calculates finish position correctly', () {
        final tokenNearFinish = testToken.copyWith(
          state: TokenState.active,
          currentPosition: Position(
            x: 7,
            y: 6,
            type: PositionType.path,
            ownerColor: null,
            pathIndex: 50,
          ),
        );

        final newPosition = gameLogicService.calculateNewPosition(
          token: tokenNearFinish,
          diceValue: 1,
        );

        expect(newPosition, isNotNull);
        expect(newPosition!.type, PositionType.finish);
        expect(newPosition.pathIndex, 51);
      });
    });

    group('getValidMoves', () {
      test('returns moves for tokens that can move', () {
        final activeToken = testToken.copyWith(
          state: TokenState.active,
          currentPosition: startPosition,
        );

        final playerWithActiveToken = testPlayer.copyWith(
          tokens: [activeToken],
        );

        final gameStateWithActiveToken = testGameState.copyWith(
          players: [playerWithActiveToken],
        );

        final validMoves = gameLogicService.getValidMoves(
          player: playerWithActiveToken,
          diceValue: 4,
          gameState: gameStateWithActiveToken,
        );

        expect(validMoves, isNotEmpty);
        expect(validMoves.keys.first, activeToken.id);
      });

      test('returns empty map when no tokens can move', () {
        final validMoves = gameLogicService.getValidMoves(
          player: testPlayer, // All tokens in home
          diceValue: 4, // Can't exit home
          gameState: testGameState,
        );

        expect(validMoves, isEmpty);
      });

      test('includes home token moves when dice is 6', () {
        final validMoves = gameLogicService.getValidMoves(
          player: testPlayer,
          diceValue: 6,
          gameState: testGameState,
        );

        expect(validMoves, isNotEmpty);
        expect(validMoves.length, testPlayer.tokens.length);
      });
    });

    group('executeMove', () {
      test('moves token from home to start position', () {
        final result = gameLogicService.executeMove(
          tokenId: testToken.id,
          diceValue: 6,
          gameState: testGameState,
        );

        expect(result, isNotNull);
        expect(result!.success, true);
        
        final updatedPlayer = result.gameState.players[0];
        final movedToken = updatedPlayer.getTokenById(testToken.id);
        expect(movedToken?.state, TokenState.active);
        expect(movedToken?.currentPosition.type, PositionType.start);
      });

      test('moves active token along path', () {
        final activeToken = testToken.copyWith(
          state: TokenState.active,
          currentPosition: startPosition,
        );

        final playerWithActiveToken = testPlayer.copyWith(
          tokens: [activeToken, ...testPlayer.tokens.skip(1)],
        );

        final gameStateWithActiveToken = testGameState.copyWith(
          players: [playerWithActiveToken],
        );

        final result = gameLogicService.executeMove(
          tokenId: activeToken.id,
          diceValue: 3,
          gameState: gameStateWithActiveToken,
        );

        expect(result, isNotNull);
        expect(result!.success, true);
        
        final updatedPlayer = result.gameState.players[0];
        final movedToken = updatedPlayer.getTokenById(activeToken.id);
        expect(movedToken?.currentPosition.pathIndex, 3);
      });

      test('returns failure when move is invalid', () {
        final result = gameLogicService.executeMove(
          tokenId: testToken.id,
          diceValue: 4, // Can't exit home with 4
          gameState: testGameState,
        );

        expect(result, isNotNull);
        expect(result!.success, false);
        expect(result.error, isNotNull);
      });

      test('captures opponent token', () {
        final opponentToken = Token(
          id: 'opponent_token',
          color: PlayerColor.blue,
          currentPosition: pathPosition,
          state: TokenState.active,
        );

        final opponentPlayer = Player(
          id: 'opponent',
          name: 'Opponent',
          color: PlayerColor.blue,
          isHuman: false,
          tokens: [opponentToken],
        );

        final activeToken = testToken.copyWith(
          state: TokenState.active,
          currentPosition: startPosition,
        );

        final playerWithActiveToken = testPlayer.copyWith(
          tokens: [activeToken],
        );

        final gameStateWithOpponent = testGameState.copyWith(
          players: [playerWithActiveToken, opponentPlayer],
        );

        final result = gameLogicService.executeMove(
          tokenId: activeToken.id,
          diceValue: 1, // Move to position occupied by opponent
          gameState: gameStateWithOpponent,
        );

        expect(result, isNotNull);
        expect(result!.success, true);
        expect(result.capturedToken, isNotNull);
        expect(result.capturedToken?.id, opponentToken.id);
      });
    });

    group('isPositionSafe', () {
      test('returns true for safe positions', () {
        final safePosition = Position(
          x: 2,
          y: 8,
          type: PositionType.safe,
          ownerColor: null,
          pathIndex: 8,
        );

        final result = gameLogicService.isPositionSafe(safePosition);
        expect(result, true);
      });

      test('returns true for home positions', () {
        final result = gameLogicService.isPositionSafe(homePosition);
        expect(result, true);
      });

      test('returns true for finish positions', () {
        final result = gameLogicService.isPositionSafe(finishPosition);
        expect(result, true);
      });

      test('returns false for regular path positions', () {
        final result = gameLogicService.isPositionSafe(pathPosition);
        expect(result, false);
      });
    });

    group('checkGameWinner', () {
      test('returns winner when player has all tokens finished', () {
        final finishedTokens = testPlayer.tokens.map((token) =>
          token.copyWith(state: TokenState.finished)
        ).toList();

        final winningPlayer = testPlayer.copyWith(tokens: finishedTokens);
        final gameStateWithWinner = testGameState.copyWith(
          players: [winningPlayer],
        );

        final winner = gameLogicService.checkGameWinner(gameStateWithWinner);
        expect(winner, isNotNull);
        expect(winner?.id, winningPlayer.id);
      });

      test('returns null when no player has won', () {
        final winner = gameLogicService.checkGameWinner(testGameState);
        expect(winner, isNull);
      });
    });

    group('validateGameRules', () {
      test('returns true for valid game state', () {
        final result = gameLogicService.validateGameRules(testGameState);
        expect(result, true);
      });

      test('validates maximum consecutive sixes rule', () {
        final gameStateWithManySixes = testGameState.copyWith(
          consecutiveSixes: 3,
        );

        final result = gameLogicService.validateGameRules(gameStateWithManySixes);
        expect(result, false);
      });
    });

    group('getTokensAtPosition', () {
      test('returns tokens at specified position', () {
        final activeToken = testToken.copyWith(
          state: TokenState.active,
          currentPosition: pathPosition,
        );

        final playerWithActiveToken = testPlayer.copyWith(
          tokens: [activeToken],
        );

        final gameStateWithActiveToken = testGameState.copyWith(
          players: [playerWithActiveToken],
        );

        final tokensAtPosition = gameLogicService.getTokensAtPosition(
          position: pathPosition,
          gameState: gameStateWithActiveToken,
        );

        expect(tokensAtPosition.length, 1);
        expect(tokensAtPosition.first.id, activeToken.id);
      });

      test('returns empty list when no tokens at position', () {
        final tokensAtPosition = gameLogicService.getTokensAtPosition(
          position: pathPosition,
          gameState: testGameState,
        );

        expect(tokensAtPosition, isEmpty);
      });
    });
  });
}