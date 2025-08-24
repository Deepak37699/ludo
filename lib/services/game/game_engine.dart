import 'dart:math';
import '../../data/models/game_state.dart';
import '../../data/models/player.dart';
import '../../data/models/token.dart';
import '../../data/models/position.dart';
import '../../core/enums/game_enums.dart';
import 'board_service.dart';
import 'move_validation_service.dart';

/// Main game engine that handles all Ludo game logic
class GameEngine {
  static final Random _random = Random();

  /// Create a new game with specified players
  static GameState createGame({
    required List<String> playerNames,
    required List<PlayerColor> playerColors,
    required List<bool> isHuman,
    GameMode gameMode = GameMode.singlePlayer,
    GameTheme theme = GameTheme.classic,
    int turnTimeLimit = 30,
  }) {
    if (playerNames.length != playerColors.length || 
        playerNames.length != isHuman.length) {
      throw ArgumentError('Player configuration arrays must have same length');
    }

    if (playerNames.length < LudoRules.minPlayers || 
        playerNames.length > LudoRules.maxPlayers) {
      throw ArgumentError('Number of players must be between ${LudoRules.minPlayers} and ${LudoRules.maxPlayers}');
    }

    final players = <Player>[];
    for (int i = 0; i < playerNames.length; i++) {
      final homePositions = BoardService.getHomePositions(playerColors[i]);
      
      if (isHuman[i]) {
        players.add(Player.human(
          name: playerNames[i],
          color: playerColors[i],
          homePositions: homePositions,
        ));
      } else {
        players.add(Player.ai(
          color: playerColors[i],
          homePositions: homePositions,
          difficulty: AIDifficulty.medium,
        ));
      }
    }

    return GameState.create(
      players: players,
      gameMode: gameMode,
      theme: theme,
      turnTimeLimit: turnTimeLimit,
    );
  }

  /// Start the game
  static GameState startGame(GameState gameState) {
    if (!gameState.canStart) {
      throw StateError('Game cannot be started in current state');
    }

    return gameState.startGame();
  }

  /// Roll the dice for the current player
  static GameDiceResult rollDice(GameState gameState) {
    if (!gameState.canRollDice) {
      throw StateError('Cannot roll dice in current game state');
    }

    final diceValue = _random.nextInt(6) + 1;
    final newGameState = gameState.rollDice(diceValue);
    
    // Check if player has valid moves
    final validMoves = MoveValidationService.getValidMoves(
      player: newGameState.currentPlayer,
      diceValue: diceValue,
      gameState: newGameState,
    );

    return GameDiceResult(
      gameState: newGameState,
      diceValue: diceValue,
      validMoves: validMoves,
      hasValidMoves: validMoves.isNotEmpty,
    );
  }

  /// Execute a move
  static GameMoveResult executeMove({
    required GameState gameState,
    required String tokenId,
    required Position targetPosition,
    required int diceValue,
  }) {
    final currentPlayer = gameState.currentPlayer;
    final token = currentPlayer.tokens.firstWhere(
      (t) => t.id == tokenId,
      orElse: () => throw ArgumentError('Token not found'),
    );

    // Validate the move
    final validationResult = MoveValidationService.validateMove(
      token: token,
      targetPosition: targetPosition,
      diceValue: diceValue,
      gameState: gameState,
    );

    if (!validationResult.isValid) {
      throw ArgumentError(validationResult.message);
    }

    // Execute the move
    GameState newGameState = gameState;
    bool tokenFinished = false;
    int scoreEarned = 0;

    // Move the token
    final newToken = token.moveTo(targetPosition);
    tokenFinished = newToken.hasFinished;
    
    // Update the player with the moved token
    Player updatedPlayer = currentPlayer.updateToken(tokenId, newToken);

    // Handle token capture
    if (validationResult.capturedToken != null) {
      newGameState = _handleTokenCapture(
        newGameState,
        validationResult.capturedToken!,
      );
    }

    // Calculate score
    scoreEarned = MoveValidationService.calculateMoveScore(
      moveType: validationResult.moveType,
      capturedToken: validationResult.capturedToken != null,
      tokenFinished: tokenFinished,
    );

    // Update player score
    updatedPlayer = updatedPlayer.addScore(scoreEarned);

    // Update game state with new player
    newGameState = newGameState.updatePlayer(currentPlayer.id, updatedPlayer);

    // Record the move
    final gameMove = GameMove(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      playerId: currentPlayer.id,
      tokenId: tokenId,
      fromPosition: token.currentPosition,
      toPosition: targetPosition,
      diceValue: diceValue,
      timestamp: DateTime.now(),
      capturedTokenId: validationResult.capturedToken?.id,
      moveType: validationResult.moveType,
    );

    newGameState = newGameState.addMove(gameMove);

    // Check for game winner
    newGameState = newGameState.checkForWinner();

    // Determine if player gets another turn
    bool anotherTurn = MoveValidationService.canRollAgain(
      lastDiceValue: diceValue,
      capturedToken: validationResult.capturedToken != null,
      consecutiveSixes: newGameState.consecutiveSixes,
    );

    // Move to next turn if no another turn
    if (!anotherTurn && newGameState.status != GameStatus.finished) {
      newGameState = newGameState.nextTurn();
    }

    return GameMoveResult(
      gameState: newGameState,
      movedToken: newToken,
      capturedToken: validationResult.capturedToken,
      scoreEarned: scoreEarned,
      tokenFinished: tokenFinished,
      anotherTurn: anotherTurn,
      moveType: validationResult.moveType,
    );
  }

  /// Handle token capture by sending captured token back home
  static GameState _handleTokenCapture(GameState gameState, Token capturedToken) {
    // Find the player who owns the captured token
    final ownerPlayer = gameState.players.firstWhere(
      (player) => player.tokens.any((token) => token.id == capturedToken.id),
    );

    // Find a home position for the captured token
    final homePositions = BoardService.getHomePositions(capturedToken.color);
    final availableHomePosition = homePositions.firstWhere(
      (homePos) => !ownerPlayer.tokens.any(
        (token) => token.id != capturedToken.id && 
                   BoardService.isSamePosition(token.currentPosition, homePos),
      ),
      orElse: () => homePositions.first, // Fallback to first position
    );

    // Reset the captured token to home
    final resetToken = capturedToken.resetToHome(availableHomePosition);
    final updatedOwner = ownerPlayer.updateToken(capturedToken.id, resetToken);

    return gameState.updatePlayer(ownerPlayer.id, updatedOwner);
  }

  /// Get all possible moves for current player
  static List<ValidMove> getCurrentPlayerMoves(GameState gameState, int diceValue) {
    return MoveValidationService.getValidMoves(
      player: gameState.currentPlayer,
      diceValue: diceValue,
      gameState: gameState,
    );
  }

  /// Check if current player has any valid moves
  static bool currentPlayerHasValidMoves(GameState gameState, int diceValue) {
    return MoveValidationService.hasValidMoves(
      player: gameState.currentPlayer,
      diceValue: diceValue,
      gameState: gameState,
    );
  }

  /// Skip turn if no valid moves available
  static GameState skipTurn(GameState gameState) {
    return gameState.nextTurn();
  }

  /// Pause the game
  static GameState pauseGame(GameState gameState) {
    return gameState.pauseGame();
  }

  /// Resume the game
  static GameState resumeGame(GameState gameState) {
    return gameState.resumeGame();
  }

  /// End the game
  static GameState endGame(GameState gameState) {
    return gameState.cancelGame();
  }

  /// Calculate game statistics
  static GameStatistics calculateGameStatistics(GameState gameState) {
    final duration = gameState.gameDuration ?? Duration.zero;
    final moves = gameState.moveHistory;
    final winner = gameState.winner;

    return GameStatistics(
      duration: duration,
      totalMoves: moves.length,
      winner: winner,
      playerStats: gameState.players.map((player) {
        final playerMoves = moves.where((move) => move.playerId == player.id);
        final captures = playerMoves.where((move) => move.moveType == MoveType.capture);
        
        return PlayerStatistics(
          player: player,
          movesCount: playerMoves.length,
          capturesCount: captures.length,
          tokensFinished: player.tokensFinishedCount,
          finalScore: player.score,
        );
      }).toList(),
    );
  }

  /// Simulate dice roll (for testing or AI)
  static int simulateDiceRoll([int? fixedValue]) {
    return fixedValue ?? (_random.nextInt(6) + 1);
  }

  /// Validate game state consistency
  static bool validateGameState(GameState gameState) {
    try {
      // Check player count
      if (gameState.players.length < LudoRules.minPlayers || 
          gameState.players.length > LudoRules.maxPlayers) {
        return false;
      }

      // Check current player index
      if (gameState.currentPlayerIndex < 0 || 
          gameState.currentPlayerIndex >= gameState.players.length) {
        return false;
      }

      // Check token counts
      for (final player in gameState.players) {
        if (player.tokens.length != LudoRules.tokensPerPlayer) {
          return false;
        }
      }

      // Check for duplicate token positions (except home and finish)
      final tokenPositions = <String, List<Token>>{};
      for (final player in gameState.players) {
        for (final token in player.tokens) {
          if (token.currentPosition.type != PositionType.home && 
              token.currentPosition.type != PositionType.finish) {
            final posKey = '${token.currentPosition.x},${token.currentPosition.y}';
            tokenPositions.putIfAbsent(posKey, () => []).add(token);
          }
        }
      }

      // Check for invalid overlapping positions
      for (final entry in tokenPositions.entries) {
        if (entry.value.length > 1) {
          final colors = entry.value.map((t) => t.color).toSet();
          if (colors.length > 1) {
            // Multiple colors at same position - check if it's a safe position
            final position = entry.value.first.currentPosition;
            if (!BoardService.isSafePosition(position)) {
              return false; // Invalid overlap
            }
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Result of a dice roll
class GameDiceResult {
  final GameState gameState;
  final int diceValue;
  final List<ValidMove> validMoves;
  final bool hasValidMoves;

  const GameDiceResult({
    required this.gameState,
    required this.diceValue,
    required this.validMoves,
    required this.hasValidMoves,
  });
}

/// Result of a move execution
class GameMoveResult {
  final GameState gameState;
  final Token movedToken;
  final Token? capturedToken;
  final int scoreEarned;
  final bool tokenFinished;
  final bool anotherTurn;
  final MoveType moveType;

  const GameMoveResult({
    required this.gameState,
    required this.movedToken,
    this.capturedToken,
    required this.scoreEarned,
    required this.tokenFinished,
    required this.anotherTurn,
    required this.moveType,
  });
}

/// Game statistics
class GameStatistics {
  final Duration duration;
  final int totalMoves;
  final Player? winner;
  final List<PlayerStatistics> playerStats;

  const GameStatistics({
    required this.duration,
    required this.totalMoves,
    this.winner,
    required this.playerStats,
  });
}

/// Player statistics
class PlayerStatistics {
  final Player player;
  final int movesCount;
  final int capturesCount;
  final int tokensFinished;
  final int finalScore;

  const PlayerStatistics({
    required this.player,
    required this.movesCount,
    required this.capturesCount,
    required this.tokensFinished,
    required this.finalScore,
  });
}