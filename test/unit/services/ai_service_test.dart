import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ludo_game/services/ai/ai_service.dart';
import 'package:ludo_game/data/models/token.dart';
import 'package:ludo_game/data/models/position.dart';
import 'package:ludo_game/data/models/player.dart';
import 'package:ludo_game/data/models/game_state.dart';
import 'package:ludo_game/core/enums/game_enums.dart';

void main() {
  group('AIService', () {
    late AIService aiService;
    late Position homePosition;
    late Position startPosition;
    late Position pathPosition;
    late List<Token> tokens;
    late Player aiPlayer;
    late Player humanPlayer;
    late GameState gameState;

    setUp(() {
      aiService = AIService();
      
      homePosition = Position(
        x: 1,
        y: 1,
        type: PositionType.home,
        ownerColor: PlayerColor.blue,
        pathIndex: null,
      );
      
      startPosition = Position(
        x: 8,
        y: 6,
        type: PositionType.start,
        ownerColor: PlayerColor.blue,
        pathIndex: 0,
      );
      
      pathPosition = Position(
        x: 9,
        y: 6,
        type: PositionType.path,
        ownerColor: null,
        pathIndex: 1,
      );

      tokens = List.generate(4, (index) => Token(
        id: 'ai_token_$index',
        color: PlayerColor.blue,
        currentPosition: homePosition,
        state: TokenState.home,
      ));

      aiPlayer = Player(
        id: 'ai_player',
        name: 'AI Player',
        color: PlayerColor.blue,
        isHuman: false,
        tokens: tokens,
        aiDifficulty: AIDifficulty.medium,
      );

      final humanTokens = List.generate(4, (index) => Token(
        id: 'human_token_$index',
        color: PlayerColor.red,
        currentPosition: homePosition.copyWith(ownerColor: PlayerColor.red),
        state: TokenState.home,
      ));

      humanPlayer = Player(
        id: 'human_player',
        name: 'Human Player',
        color: PlayerColor.red,
        isHuman: true,
        tokens: humanTokens,
      );

      gameState = GameState(
        id: 'game1',
        players: [humanPlayer, aiPlayer],
        currentPlayerIndex: 1, // AI's turn
        gameStatus: GameStatus.playing,
        gameMode: GameMode.vsAI,
      );
    });

    group('calculateBestMove', () {
      test('prioritizes moving token out of home with dice 6', () {
        final move = aiService.calculateBestMove(
          aiPlayer: aiPlayer,
          diceValue: 6,
          gameState: gameState,
          difficulty: AIDifficulty.medium,
        );

        expect(move, isNotNull);
        expect(move!.tokenId, isIn(tokens.map((t) => t.id)));
        expect(move.priority, MovePriority.high);
      });

      test('chooses defensive move when opponent can capture', () {
        // Place AI token in vulnerable position
        final vulnerableToken = tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: pathPosition,
        );

        // Place human token that can capture
        final humanCapturingToken = humanPlayer.tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: Position(
            x: 7,
            y: 6,
            type: PositionType.path,
            ownerColor: null,
            pathIndex: 5,
          ),
        );

        final humanPlayerWithCapturingToken = humanPlayer.copyWith(
          tokens: [humanCapturingToken, ...humanPlayer.tokens.skip(1)],
        );

        final aiPlayerWithVulnerable = aiPlayer.copyWith(
          tokens: [vulnerableToken, ...tokens.skip(1)],
        );

        final gameStateWithThreat = gameState.copyWith(
          players: [humanPlayerWithCapturingToken, aiPlayerWithVulnerable],
        );

        final move = aiService.calculateBestMove(
          aiPlayer: aiPlayerWithVulnerable,
          diceValue: 4,
          gameState: gameStateWithThreat,
          difficulty: AIDifficulty.hard,
        );

        expect(move, isNotNull);
        // Should prioritize moving the vulnerable token to safety
      });

      test('chooses aggressive move when can capture opponent', () {
        final aiCapturingToken = tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: Position(
            x: 7,
            y: 6,
            type: PositionType.path,
            ownerColor: null,
            pathIndex: 3,
          ),
        );

        final humanVulnerableToken = humanPlayer.tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: Position(
            x: 9,
            y: 6,
            type: PositionType.path,
            ownerColor: null,
            pathIndex: 5,
          ),
        );

        final aiPlayerWithCapturing = aiPlayer.copyWith(
          tokens: [aiCapturingToken, ...tokens.skip(1)],
        );

        final humanPlayerWithVulnerable = humanPlayer.copyWith(
          tokens: [humanVulnerableToken, ...humanPlayer.tokens.skip(1)],
        );

        final gameStateWithCapture = gameState.copyWith(
          players: [humanPlayerWithVulnerable, aiPlayerWithCapturing],
        );

        final move = aiService.calculateBestMove(
          aiPlayer: aiPlayerWithCapturing,
          diceValue: 2, // Can capture with 2 moves
          gameState: gameStateWithCapture,
          difficulty: AIDifficulty.hard,
        );

        expect(move, isNotNull);
        expect(move!.tokenId, aiCapturingToken.id);
        expect(move.priority, MovePriority.high);
      });

      test('returns null when no valid moves available', () {
        final move = aiService.calculateBestMove(
          aiPlayer: aiPlayer, // All tokens in home
          diceValue: 4, // Can't exit home with 4
          gameState: gameState,
          difficulty: AIDifficulty.medium,
        );

        expect(move, isNull);
      });
    });

    group('evaluatePosition', () {
      test('gives higher score for advancing tokens', () {
        final advancedToken = tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: Position(
            x: 10,
            y: 6,
            type: PositionType.path,
            ownerColor: null,
            pathIndex: 20,
          ),
        );

        final newPosition = Position(
          x: 11,
          y: 6,
          type: PositionType.path,
          ownerColor: null,
          pathIndex: 25,
        );

        final score = aiService.evaluatePosition(
          token: advancedToken,
          newPosition: newPosition,
          gameState: gameState,
        );

        expect(score, greaterThan(0));
      });

      test('gives bonus for reaching finish', () {
        final nearFinishToken = tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: Position(
            x: 7,
            y: 7,
            type: PositionType.path,
            ownerColor: null,
            pathIndex: 50,
          ),
        );

        final finishPosition = Position(
          x: 7,
          y: 7,
          type: PositionType.finish,
          ownerColor: PlayerColor.blue,
          pathIndex: 51,
        );

        final score = aiService.evaluatePosition(
          token: nearFinishToken,
          newPosition: finishPosition,
          gameState: gameState,
        );

        expect(score, greaterThan(500)); // High bonus for finishing
      });

      test('penalizes moving to vulnerable positions', () {
        final token = tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: startPosition,
        );

        final vulnerablePosition = Position(
          x: 10,
          y: 6,
          type: PositionType.path,
          ownerColor: null,
          pathIndex: 5,
        );

        // Place opponent token that can capture
        final humanThreatToken = humanPlayer.tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: Position(
            x: 8,
            y: 6,
            type: PositionType.path,
            ownerColor: null,
            pathIndex: 1,
          ),
        );

        final humanPlayerWithThreat = humanPlayer.copyWith(
          tokens: [humanThreatToken, ...humanPlayer.tokens.skip(1)],
        );

        final gameStateWithThreat = gameState.copyWith(
          players: [humanPlayerWithThreat, aiPlayer],
        );

        final score = aiService.evaluatePosition(
          token: token,
          newPosition: vulnerablePosition,
          gameState: gameStateWithThreat,
        );

        expect(score, lessThan(0)); // Should be negative due to vulnerability
      });
    });

    group('difficulty-based behavior', () {
      test('easy AI makes more random moves', () {
        final activeToken = tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: startPosition,
        );

        final aiPlayerWithActive = aiPlayer.copyWith(
          tokens: [activeToken, ...tokens.skip(1)],
          aiDifficulty: AIDifficulty.easy,
        );

        final moves = <AIMove?>[];
        
        // Test multiple moves to check for randomness
        for (int i = 0; i < 10; i++) {
          final move = aiService.calculateBestMove(
            aiPlayer: aiPlayerWithActive,
            diceValue: 3,
            gameState: gameState,
            difficulty: AIDifficulty.easy,
          );
          moves.add(move);
        }

        // Easy AI should sometimes make suboptimal moves
        final hasVariation = moves.any((move) => 
          move?.priority != MovePriority.high);
        expect(hasVariation, true);
      });

      test('hard AI consistently makes optimal moves', () {
        final activeToken = tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: startPosition,
        );

        final aiPlayerWithActive = aiPlayer.copyWith(
          tokens: [activeToken, ...tokens.skip(1)],
          aiDifficulty: AIDifficulty.hard,
        );

        final moves = <AIMove?>[];
        
        // Test multiple moves to check consistency
        for (int i = 0; i < 5; i++) {
          final move = aiService.calculateBestMove(
            aiPlayer: aiPlayerWithActive,
            diceValue: 3,
            gameState: gameState,
            difficulty: AIDifficulty.hard,
          );
          moves.add(move);
        }

        // Hard AI should consistently make the same optimal move
        final firstMove = moves.first;
        final allSame = moves.every((move) => 
          move?.tokenId == firstMove?.tokenId);
        expect(allSame, true);
      });
    });

    group('canCapture', () {
      test('returns true when token can capture opponent', () {
        final aiToken = tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: startPosition,
        );

        final opponentToken = humanPlayer.tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: Position(
            x: 10,
            y: 6,
            type: PositionType.path,
            ownerColor: null,
            pathIndex: 2,
          ),
        );

        final humanPlayerWithVulnerable = humanPlayer.copyWith(
          tokens: [opponentToken, ...humanPlayer.tokens.skip(1)],
        );

        final gameStateWithCapture = gameState.copyWith(
          players: [humanPlayerWithVulnerable, aiPlayer],
        );

        final canCapture = aiService.canCapture(
          token: aiToken,
          diceValue: 2,
          gameState: gameStateWithCapture,
        );

        expect(canCapture, true);
      });

      test('returns false when cannot capture', () {
        final aiToken = tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: startPosition,
        );

        final canCapture = aiService.canCapture(
          token: aiToken,
          diceValue: 3,
          gameState: gameState, // No opponent tokens in range
        );

        expect(canCapture, false);
      });
    });

    group('isVulnerable', () {
      test('returns true when token can be captured', () {
        final aiToken = tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: pathPosition,
        );

        final humanThreatToken = humanPlayer.tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: Position(
            x: 7,
            y: 6,
            type: PositionType.path,
            ownerColor: null,
            pathIndex: 5,
          ),
        );

        final humanPlayerWithThreat = humanPlayer.copyWith(
          tokens: [humanThreatToken, ...humanPlayer.tokens.skip(1)],
        );

        final gameStateWithThreat = gameState.copyWith(
          players: [humanPlayerWithThreat, aiPlayer],
        );

        final isVulnerable = aiService.isVulnerable(
          token: aiToken,
          position: pathPosition,
          gameState: gameStateWithThreat,
        );

        expect(isVulnerable, true);
      });

      test('returns false when token is safe', () {
        final safePosition = Position(
          x: 2,
          y: 8,
          type: PositionType.safe,
          ownerColor: null,
          pathIndex: 8,
        );

        final aiToken = tokens[0].copyWith(
          state: TokenState.active,
          currentPosition: safePosition,
        );

        final isVulnerable = aiService.isVulnerable(
          token: aiToken,
          position: safePosition,
          gameState: gameState,
        );

        expect(isVulnerable, false);
      });
    });

    group('calculateMoveDelay', () {
      test('returns appropriate delay for difficulty level', () {
        final easyDelay = aiService.calculateMoveDelay(AIDifficulty.easy);
        final mediumDelay = aiService.calculateMoveDelay(AIDifficulty.medium);
        final hardDelay = aiService.calculateMoveDelay(AIDifficulty.hard);

        expect(easyDelay.inMilliseconds, greaterThan(hardDelay.inMilliseconds));
        expect(mediumDelay.inMilliseconds, greaterThan(hardDelay.inMilliseconds));
        expect(mediumDelay.inMilliseconds, lessThan(easyDelay.inMilliseconds));
      });

      test('adds random variation to delay', () {
        final delays = List.generate(5, (_) => 
          aiService.calculateMoveDelay(AIDifficulty.medium));
        
        // Should have some variation due to randomness
        final hasVariation = delays.any((delay) => 
          delay != delays.first);
        expect(hasVariation, true);
      });
    });
  });
}