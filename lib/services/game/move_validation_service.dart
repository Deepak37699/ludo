import '../../data/models/token.dart';
import '../../data/models/player.dart';
import '../../data/models/position.dart';
import '../../data/models/game_state.dart';
import '../../core/enums/game_enums.dart';
import 'board_service.dart';

/// Service class for validating moves according to Ludo rules
class MoveValidationService {
  
  /// Validate if a token can be moved with the given dice value
  static MoveValidationResult validateMove({
    required Token token,
    required Position targetPosition,
    required int diceValue,
    required GameState gameState,
  }) {
    // Rule 1: Dice value must be between 1 and 6
    if (diceValue < 1 || diceValue > 6) {
      return MoveValidationResult.invalid('Invalid dice value');
    }

    // Rule 2: Token at home can only move with a 6
    if (token.isAtHome && diceValue != 6) {
      return MoveValidationResult.invalid('Need to roll 6 to move token from home');
    }

    // Rule 3: Calculate expected position based on current position and dice value
    final expectedPosition = BoardService.calculateNextPosition(
      token.currentPosition,
      diceValue,
      token.color,
    );

    if (expectedPosition == null) {
      return MoveValidationResult.invalid('Cannot move that far');
    }

    // Rule 4: Target position must match calculated position
    if (!BoardService.isSamePosition(expectedPosition, targetPosition)) {
      return MoveValidationResult.invalid('Invalid target position');
    }

    // Rule 5: Check for collisions with other tokens
    final collisionResult = _checkTokenCollision(
      targetPosition,
      token,
      gameState,
    );

    if (!collisionResult.isValid) {
      return collisionResult;
    }

    // Rule 6: Check if move would result in capturing opponent token
    final captureInfo = _checkTokenCapture(
      targetPosition,
      token,
      gameState,
    );

    return MoveValidationResult.valid(
      message: 'Valid move',
      capturedToken: captureInfo.capturedToken,
      moveType: captureInfo.moveType,
    );
  }

  /// Check for valid moves for a player with given dice value
  static List<ValidMove> getValidMoves({
    required Player player,
    required int diceValue,
    required GameState gameState,
  }) {
    List<ValidMove> validMoves = [];

    for (final token in player.tokens) {
      // Skip finished tokens
      if (token.hasFinished) continue;

      // For tokens at home, only 6 allows movement
      if (token.isAtHome && diceValue != 6) continue;

      final targetPosition = BoardService.calculateNextPosition(
        token.currentPosition,
        diceValue,
        token.color,
      );

      if (targetPosition != null) {
        final validationResult = validateMove(
          token: token,
          targetPosition: targetPosition,
          diceValue: diceValue,
          gameState: gameState,
        );

        if (validationResult.isValid) {
          validMoves.add(ValidMove(
            token: token,
            targetPosition: targetPosition,
            diceValue: diceValue,
            capturedToken: validationResult.capturedToken,
            moveType: validationResult.moveType,
          ));
        }
      }
    }

    return validMoves;
  }

  /// Check if a player has any valid moves
  static bool hasValidMoves({
    required Player player,
    required int diceValue,
    required GameState gameState,
  }) {
    return getValidMoves(
      player: player,
      diceValue: diceValue,
      gameState: gameState,
    ).isNotEmpty;
  }

  /// Check for token collision at target position
  static MoveValidationResult _checkTokenCollision(
    Position targetPosition,
    Token movingToken,
    GameState gameState,
  ) {
    // Check if any other token is at the target position
    for (final player in gameState.players) {
      for (final token in player.tokens) {
        // Skip the moving token itself
        if (token.id == movingToken.id) continue;

        // Check if token is at target position
        if (BoardService.isSamePosition(token.currentPosition, targetPosition)) {
          // If it's the same color, collision is not allowed
          if (token.color == movingToken.color) {
            return MoveValidationResult.invalid(
              'Cannot move to position occupied by own token',
            );
          }

          // If target position is safe, opponent token cannot be captured
          if (BoardService.isSafePosition(targetPosition)) {
            return MoveValidationResult.invalid(
              'Cannot capture token in safe position',
            );
          }

          // Opponent token can be captured
          return MoveValidationResult.valid(
            message: 'Can capture opponent token',
          );
        }
      }
    }

    return MoveValidationResult.valid(message: 'Position is clear');
  }

  /// Check if move would result in capturing an opponent token
  static TokenCaptureInfo _checkTokenCapture(
    Position targetPosition,
    Token movingToken,
    GameState gameState,
  ) {
    for (final player in gameState.players) {
      for (final token in player.tokens) {
        // Skip own tokens
        if (token.color == movingToken.color) continue;

        // Check if opponent token is at target position
        if (BoardService.isSamePosition(token.currentPosition, targetPosition)) {
          // Check if target position is safe
          if (BoardService.isSafePosition(targetPosition)) {
            return TokenCaptureInfo(
              capturedToken: null,
              moveType: MoveType.normal,
            );
          }

          // Token can be captured
          return TokenCaptureInfo(
            capturedToken: token,
            moveType: MoveType.capture,
          );
        }
      }
    }

    // Determine move type based on target position
    MoveType moveType = MoveType.normal;
    if (targetPosition.type == PositionType.finish) {
      moveType = MoveType.finish;
    } else if (targetPosition.type == PositionType.homeEntrance) {
      moveType = MoveType.homeEntry;
    }

    return TokenCaptureInfo(
      capturedToken: null,
      moveType: moveType,
    );
  }

  /// Check if a player can roll the dice again (rolled a 6 or captured a token)
  static bool canRollAgain({
    required int lastDiceValue,
    required bool capturedToken,
    required int consecutiveSixes,
  }) {
    // Can roll again if rolled a 6 (but not more than 3 times in a row)
    if (lastDiceValue == 6 && consecutiveSixes < 3) {
      return true;
    }

    // Can roll again if captured an opponent token
    if (capturedToken) {
      return true;
    }

    return false;
  }

  /// Check if a token has completed the game (reached center)
  static bool hasTokenFinished(Position position) {
    return BoardService.isSamePosition(position, BoardService.getCenterPosition());
  }

  /// Check if a player has won the game (all tokens finished)
  static bool hasPlayerWon(Player player) {
    return player.tokens.every((token) => token.hasFinished);
  }

  /// Calculate score for a move
  static int calculateMoveScore({
    required MoveType moveType,
    required bool capturedToken,
    required bool tokenFinished,
  }) {
    int score = 1; // Base score for any move

    switch (moveType) {
      case MoveType.capture:
        score += 10; // Bonus for capturing
        break;
      case MoveType.homeEntry:
        score += 5; // Bonus for entering home area
        break;
      case MoveType.finish:
        score += 15; // Bonus for finishing
        break;
      case MoveType.normal:
        break;
    }

    if (tokenFinished) {
      score += 20; // Bonus for completing a token
    }

    return score;
  }
}

/// Result of move validation
class MoveValidationResult {
  final bool isValid;
  final String message;
  final Token? capturedToken;
  final MoveType moveType;

  const MoveValidationResult({
    required this.isValid,
    required this.message,
    this.capturedToken,
    this.moveType = MoveType.normal,
  });

  factory MoveValidationResult.valid({
    required String message,
    Token? capturedToken,
    MoveType moveType = MoveType.normal,
  }) {
    return MoveValidationResult(
      isValid: true,
      message: message,
      capturedToken: capturedToken,
      moveType: moveType,
    );
  }

  factory MoveValidationResult.invalid(String message) {
    return MoveValidationResult(
      isValid: false,
      message: message,
    );
  }
}

/// Information about a valid move
class ValidMove {
  final Token token;
  final Position targetPosition;
  final int diceValue;
  final Token? capturedToken;
  final MoveType moveType;

  const ValidMove({
    required this.token,
    required this.targetPosition,
    required this.diceValue,
    this.capturedToken,
    this.moveType = MoveType.normal,
  });

  bool get isCaptureMove => capturedToken != null;
  bool get isFinishMove => moveType == MoveType.finish;
  bool get isHomeEntryMove => moveType == MoveType.homeEntry;
}

/// Information about token capture
class TokenCaptureInfo {
  final Token? capturedToken;
  final MoveType moveType;

  const TokenCaptureInfo({
    required this.capturedToken,
    required this.moveType,
  });
}

/// Ludo game rules constants
class LudoRules {
  static const int maxConsecutiveSixes = 3;
  static const int diceValueToExitHome = 6;
  static const int tokensPerPlayer = 4;
  static const int maxPlayers = 4;
  static const int minPlayers = 2;
  static const int mainPathLength = 52;
  static const int finishPathLength = 6;
  
  /// Points awarded for different actions
  static const int pointsPerMove = 1;
  static const int pointsForCapture = 10;
  static const int pointsForHomeEntry = 5;
  static const int pointsForFinish = 15;
  static const int pointsForTokenCompletion = 20;
  static const int pointsForGameWin = 100;
}