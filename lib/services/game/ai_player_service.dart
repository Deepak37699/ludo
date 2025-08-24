import 'dart:math';
import '../../data/models/game_state.dart';
import '../../data/models/player.dart';
import '../../data/models/token.dart';
import '../../data/models/position.dart';
import '../../core/enums/game_enums.dart';
import '../../services/game/move_validation_service.dart';
import '../../services/game/board_service.dart';

/// AI player service for automated gameplay
class AIPlayerService {
  static final Random _random = Random();

  /// Make an AI move for the given player
  static AIDecision makeMove({
    required GameState gameState,
    required Player aiPlayer,
    required int diceValue,
    AIDifficulty difficulty = AIDifficulty.medium,
  }) {
    // Get all valid moves for the AI player
    final validMoves = MoveValidationService.getValidMoves(
      player: aiPlayer,
      diceValue: diceValue,
      gameState: gameState,
    );

    if (validMoves.isEmpty) {
      return AIDecision.skipTurn('No valid moves available');
    }

    // Choose move based on difficulty level
    switch (difficulty) {
      case AIDifficulty.easy:
        return _makeEasyMove(validMoves, gameState);
      case AIDifficulty.medium:
        return _makeMediumMove(validMoves, gameState);
      case AIDifficulty.hard:
        return _makeHardMove(validMoves, gameState);
      case AIDifficulty.expert:
        return _makeExpertMove(validMoves, gameState);
    }
  }

  /// Easy AI - Random moves with slight preference for captures
  static AIDecision _makeEasyMove(List<ValidMove> validMoves, GameState gameState) {
    // 30% chance to prioritize captures
    if (_random.nextDouble() < 0.3) {
      final captureMoves = validMoves.where((move) => move.isCaptureMove).toList();
      if (captureMoves.isNotEmpty) {
        final selectedMove = captureMoves[_random.nextInt(captureMoves.length)];
        return AIDecision.move(
          selectedMove.token.id,
          selectedMove.targetPosition,
          'Capturing opponent token',
        );
      }
    }

    // Otherwise random move
    final randomMove = validMoves[_random.nextInt(validMoves.length)];
    return AIDecision.move(
      randomMove.token.id,
      randomMove.targetPosition,
      'Random move',
    );
  }

  /// Medium AI - Strategic moves with basic prioritization
  static AIDecision _makeMediumMove(List<ValidMove> validMoves, GameState gameState) {
    // Priority 1: Captures (60% chance)
    if (_random.nextDouble() < 0.6) {
      final captureMoves = validMoves.where((move) => move.isCaptureMove).toList();
      if (captureMoves.isNotEmpty) {
        final selectedMove = captureMoves.first;
        return AIDecision.move(
          selectedMove.token.id,
          selectedMove.targetPosition,
          'Strategic capture',
        );
      }
    }

    // Priority 2: Move tokens out of home (if dice is 6)
    final homeExitMoves = validMoves.where((move) => 
      move.token.isAtHome && move.diceValue == 6
    ).toList();
    
    if (homeExitMoves.isNotEmpty) {
      final selectedMove = homeExitMoves.first;
      return AIDecision.move(
        selectedMove.token.id,
        selectedMove.targetPosition,
        'Moving token out of home',
      );
    }

    // Priority 3: Advance tokens closest to finish
    final playingTokenMoves = validMoves.where((move) => 
      move.token.canMove && !move.token.isAtHome
    ).toList();

    if (playingTokenMoves.isNotEmpty) {
      // Sort by distance to finish (approximate)
      playingTokenMoves.sort((a, b) => 
        _calculateDistanceToFinish(a.token, a.targetPosition) -
        _calculateDistanceToFinish(b.token, b.targetPosition)
      );
      
      final selectedMove = playingTokenMoves.first;
      return AIDecision.move(
        selectedMove.token.id,
        selectedMove.targetPosition,
        'Advancing toward finish',
      );
    }

    // Fallback to random move
    final randomMove = validMoves[_random.nextInt(validMoves.length)];
    return AIDecision.move(
      randomMove.token.id,
      randomMove.targetPosition,
      'Fallback move',
    );
  }

  /// Hard AI - Advanced strategy with threat assessment
  static AIDecision _makeHardMove(List<ValidMove> validMoves, GameState gameState) {
    final aiPlayer = validMoves.first.token.color;
    
    // Priority 1: Captures (always prioritize)
    final captureMoves = validMoves.where((move) => move.isCaptureMove).toList();
    if (captureMoves.isNotEmpty) {
      // Choose the best capture (target closest to finish)
      captureMoves.sort((a, b) => 
        _calculateDistanceToFinish(b.capturedToken!, b.capturedToken!.currentPosition) -
        _calculateDistanceToFinish(a.capturedToken!, a.capturedToken!.currentPosition)
      );
      
      final selectedMove = captureMoves.first;
      return AIDecision.move(
        selectedMove.token.id,
        selectedMove.targetPosition,
        'High-value capture',
      );
    }

    // Priority 2: Avoid being captured (defensive)
    final defensiveMoves = _getDefensiveMoves(validMoves, gameState);
    if (defensiveMoves.isNotEmpty) {
      final selectedMove = defensiveMoves.first;
      return AIDecision.move(
        selectedMove.token.id,
        selectedMove.targetPosition,
        'Defensive move',
      );
    }

    // Priority 3: Form blockades or strategic positioning
    final strategicMoves = _getStrategicMoves(validMoves, gameState);
    if (strategicMoves.isNotEmpty) {
      final selectedMove = strategicMoves.first;
      return AIDecision.move(
        selectedMove.token.id,
        selectedMove.targetPosition,
        'Strategic positioning',
      );
    }

    // Priority 4: Move tokens out of home
    final homeExitMoves = validMoves.where((move) => 
      move.token.isAtHome && move.diceValue == 6
    ).toList();
    
    if (homeExitMoves.isNotEmpty) {
      final selectedMove = homeExitMoves.first;
      return AIDecision.move(
        selectedMove.token.id,
        selectedMove.targetPosition,
        'Deploying from home',
      );
    }

    // Priority 5: Advance optimally
    return _makeMediumMove(validMoves, gameState);
  }

  /// Expert AI - Minimax-like strategy with deep analysis
  static AIDecision _makeExpertMove(List<ValidMove> validMoves, GameState gameState) {
    // Evaluate each move with a scoring system
    final scoredMoves = validMoves.map((move) => 
      ScoredMove(move, _evaluateMove(move, gameState))
    ).toList();

    // Sort by score (highest first)
    scoredMoves.sort((a, b) => b.score.compareTo(a.score));

    final bestMove = scoredMoves.first.move;
    return AIDecision.move(
      bestMove.token.id,
      bestMove.targetPosition,
      'Optimal calculated move (score: ${scoredMoves.first.score})',
    );
  }

  /// Evaluate a move and return a score
  static double _evaluateMove(ValidMove move, GameState gameState) {
    double score = 0.0;

    // Capture bonus
    if (move.isCaptureMove) {
      score += 100.0;
      // Bonus for capturing advanced tokens
      if (move.capturedToken != null) {
        score += _calculateDistanceToFinish(
          move.capturedToken!, 
          move.capturedToken!.currentPosition
        ) * 2.0;
      }
    }

    // Progress bonus
    final distanceToFinish = _calculateDistanceToFinish(move.token, move.targetPosition);
    score += (60 - distanceToFinish) * 1.5; // Closer to finish = higher score

    // Home exit bonus
    if (move.token.isAtHome) {
      score += 50.0;
    }

    // Finish bonus
    if (move.isFinishMove) {
      score += 200.0;
    }

    // Safety bonus
    if (BoardService.isSafePosition(move.targetPosition)) {
      score += 20.0;
    }

    // Threat penalty (if move puts token in danger)
    final threatLevel = _calculateThreatLevel(move.targetPosition, gameState);
    score -= threatLevel * 30.0;

    // Blockade bonus
    if (_canFormBlockade(move, gameState)) {
      score += 40.0;
    }

    return score;
  }

  /// Calculate approximate distance to finish
  static int _calculateDistanceToFinish(Token token, Position position) {
    if (token.hasFinished) return 0;
    if (token.isAtHome) return 60; // Max distance

    final pathIndex = position.pathIndex;
    if (pathIndex == null) return 60;

    // Approximate calculation based on path index and color
    return 56 - pathIndex; // Simplified calculation
  }

  /// Calculate threat level at a position
  static double _calculateThreatLevel(Position position, GameState gameState) {
    double threat = 0.0;

    for (final player in gameState.players) {
      for (final token in player.tokens) {
        if (token.canMove) {
          // Check if opponent token can reach this position with dice rolls 1-6
          for (int dice = 1; dice <= 6; dice++) {
            final nextPos = BoardService.calculateNextPosition(
              token.currentPosition, 
              dice, 
              token.color
            );
            if (nextPos != null && BoardService.isSamePosition(nextPos, position)) {
              threat += 1.0 / dice; // Higher threat for lower dice values
            }
          }
        }
      }
    }

    return threat;
  }

  /// Get defensive moves (avoid being captured)
  static List<ValidMove> _getDefensiveMoves(List<ValidMove> validMoves, GameState gameState) {
    return validMoves.where((move) {
      final threatLevel = _calculateThreatLevel(move.targetPosition, gameState);
      return threatLevel < 0.5; // Low threat threshold
    }).toList();
  }

  /// Get strategic moves (blockades, positioning)
  static List<ValidMove> _getStrategicMoves(List<ValidMove> validMoves, GameState gameState) {
    return validMoves.where((move) => 
      _canFormBlockade(move, gameState) || 
      _isGoodStrategicPosition(move.targetPosition, gameState)
    ).toList();
  }

  /// Check if move can form a blockade
  static bool _canFormBlockade(ValidMove move, GameState gameState) {
    // Check if there's already a friendly token at adjacent positions
    // This is a simplified check - real implementation would be more complex
    return false; // Placeholder
  }

  /// Check if position is strategically valuable
  static bool _isGoodStrategicPosition(Position position, GameState gameState) {
    // Check for safe zones, chokepoints, etc.
    return BoardService.isSafePosition(position);
  }

  /// Generate a thinking delay for AI (for realism)
  static Duration getThinkingDelay(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return Duration(milliseconds: 500 + _random.nextInt(1000));
      case AIDifficulty.medium:
        return Duration(milliseconds: 1000 + _random.nextInt(1500));
      case AIDifficulty.hard:
        return Duration(milliseconds: 1500 + _random.nextInt(2000));
      case AIDifficulty.expert:
        return Duration(milliseconds: 2000 + _random.nextInt(2500));
    }
  }

  /// Check if AI should risk rolling again (when having multiple sixes)
  static bool shouldRiskAnotherRoll(int consecutiveSixes, AIDifficulty difficulty) {
    final riskThreshold = switch (difficulty) {
      AIDifficulty.easy => 0.8, // High risk tolerance
      AIDifficulty.medium => 0.6,
      AIDifficulty.hard => 0.4,
      AIDifficulty.expert => 0.3, // Low risk tolerance
    };

    final risk = consecutiveSixes / 3.0; // Risk increases with consecutive sixes
    return _random.nextDouble() > risk * riskThreshold;
  }
}

/// AI decision result
class AIDecision {
  final AIDecisionType type;
  final String? tokenId;
  final Position? targetPosition;
  final String reasoning;

  const AIDecision._(this.type, this.tokenId, this.targetPosition, this.reasoning);

  factory AIDecision.move(String tokenId, Position targetPosition, String reasoning) {
    return AIDecision._(AIDecisionType.move, tokenId, targetPosition, reasoning);
  }

  factory AIDecision.skipTurn(String reasoning) {
    return AIDecision._(AIDecisionType.skipTurn, null, null, reasoning);
  }

  bool get isMove => type == AIDecisionType.move;
  bool get isSkip => type == AIDecisionType.skipTurn;
}

/// AI decision types
enum AIDecisionType {
  move,
  skipTurn,
}

/// Scored move for AI evaluation
class ScoredMove {
  final ValidMove move;
  final double score;

  const ScoredMove(this.move, this.score);
}

/// AI personality traits (for future enhancement)
class AIPersonality {
  final double aggressiveness; // 0.0 to 1.0
  final double cautiousness; // 0.0 to 1.0
  final double riskTolerance; // 0.0 to 1.0

  const AIPersonality({
    this.aggressiveness = 0.5,
    this.cautiousness = 0.5,
    this.riskTolerance = 0.5,
  });

  static const conservative = AIPersonality(
    aggressiveness: 0.3,
    cautiousness: 0.8,
    riskTolerance: 0.2,
  );

  static const balanced = AIPersonality(
    aggressiveness: 0.5,
    cautiousness: 0.5,
    riskTolerance: 0.5,
  );

  static const aggressive = AIPersonality(
    aggressiveness: 0.8,
    cautiousness: 0.2,
    riskTolerance: 0.8,
  );
}

/// AI thinking simulator for UX
class AIThinkingSimulator {
  static Stream<String> simulateThinking(AIDifficulty difficulty) async* {
    final messages = _getThinkingMessages(difficulty);
    
    for (int i = 0; i < messages.length; i++) {
      await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(700)));
      yield messages[i];
    }
  }

  static List<String> _getThinkingMessages(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return ['Thinking...', 'Making move...'];
      case AIDifficulty.medium:
        return ['Analyzing board...', 'Considering options...', 'Making move...'];
      case AIDifficulty.hard:
        return [
          'Analyzing board state...',
          'Evaluating threats...',
          'Calculating optimal move...',
          'Making move...'
        ];
      case AIDifficulty.expert:
        return [
          'Deep analysis in progress...',
          'Evaluating all possibilities...',
          'Calculating move sequences...',
          'Optimizing strategy...',
          'Making move...'
        ];
    }
  }
}