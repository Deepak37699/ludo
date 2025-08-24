import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../data/models/game_state.dart';
import '../../data/models/player.dart';
import '../../data/models/token.dart';
import '../../data/models/position.dart';
import '../../core/enums/game_enums.dart';

/// Provider for the current game state
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState?>((ref) {
  return GameStateNotifier();
});

/// Provider for checking if a game is active
final isGameActiveProvider = Provider<bool>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState != null && gameState.status == GameStatus.playing;
});

/// Provider for the current player
final currentPlayerProvider = Provider<Player?>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState?.currentPlayer;
});

/// Provider for checking if it's the current user's turn
final isCurrentUserTurnProvider = Provider<bool>((ref) {
  final gameState = ref.watch(gameStateProvider);
  final currentPlayer = ref.watch(currentPlayerProvider);
  // TODO: Check against actual user ID when multiplayer is implemented
  return gameState != null && currentPlayer != null && currentPlayer.isCurrentTurn;
});

/// Provider for the last dice roll value
final lastDiceRollProvider = Provider<int>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState?.lastDiceRoll ?? 0;
});

/// Provider for game winner
final gameWinnerProvider = Provider<Player?>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState?.winner;
});

/// Game State Notifier for managing game state changes
class GameStateNotifier extends StateNotifier<GameState?> {
  GameStateNotifier() : super(null);

  /// Create a new game
  void createGame({
    required List<Player> players,
    required GameMode gameMode,
    GameTheme theme = GameTheme.classic,
    int turnTimeLimit = 30,
  }) {
    final newGame = GameState.create(
      players: players,
      gameMode: gameMode,
      theme: theme,
      turnTimeLimit: turnTimeLimit,
    );
    state = newGame;
  }

  /// Start the game
  void startGame() {
    if (state != null && state!.canStart) {
      state = state!.startGame();
    }
  }

  /// Roll the dice
  int rollDice() {
    if (state == null || !state!.canRollDice) return 0;

    final diceValue = Random().nextInt(6) + 1;
    state = state!.rollDice(diceValue);
    return diceValue;
  }

  /// Move a token
  void moveToken(String tokenId, Position newPosition) {
    if (state == null) return;

    final currentPlayer = state!.currentPlayer;
    final tokenIndex = currentPlayer.tokens.indexWhere((t) => t.id == tokenId);
    
    if (tokenIndex == -1) return;

    final token = currentPlayer.tokens[tokenIndex];
    final updatedToken = token.moveTo(newPosition);
    final updatedPlayer = currentPlayer.updateToken(tokenId, updatedToken);
    
    // Update the game state with the new player
    state = state!.updatePlayer(currentPlayer.id, updatedPlayer);
    
    // Check for winner and move to next turn
    state = state!.checkForWinner();
    if (state!.status != GameStatus.finished) {
      nextTurn();
    }
  }

  /// Move to next player's turn
  void nextTurn() {
    if (state != null) {
      state = state!.nextTurn();
    }
  }

  /// Pause the game
  void pauseGame() {
    if (state != null) {
      state = state!.pauseGame();
    }
  }

  /// Resume the game
  void resumeGame() {
    if (state != null) {
      state = state!.resumeGame();
    }
  }

  /// Cancel the game
  void cancelGame() {
    if (state != null) {
      state = state!.cancelGame();
    }
  }

  /// Reset the game
  void resetGame() {
    state = null;
  }

  /// Update game theme
  void updateTheme(GameTheme theme) {
    if (state != null) {
      state = state!.copyWith(theme: theme);
    }
  }

  /// Add a chat message
  void addChatMessage(String playerId, String playerName, String message) {
    if (state != null) {
      final chatMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        playerId: playerId,
        playerName: playerName,
        message: message,
        timestamp: DateTime.now(),
      );
      state = state!.addChatMessage(chatMessage);
    }
  }

  /// Add a system message
  void addSystemMessage(String message) {
    if (state != null) {
      final chatMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        playerId: 'system',
        playerName: 'System',
        message: message,
        timestamp: DateTime.now(),
        isSystemMessage: true,
      );
      state = state!.addChatMessage(chatMessage);
    }
  }

  /// Update turn time limit
  void updateTurnTimeLimit(int seconds) {
    if (state != null) {
      state = state!.copyWith(turnTimeLimit: seconds);
    }
  }

  /// Handle turn timeout
  void handleTurnTimeout() {
    if (state != null && state!.isTurnTimeout) {
      addSystemMessage('${state!.currentPlayer.name} timed out. Moving to next player.');
      nextTurn();
    }
  }

  /// Get valid moves for current player
  List<Token> getValidMoves(int diceValue) {
    if (state == null) return [];
    
    final currentPlayer = state!.currentPlayer;
    final boardPath = getBoardPath(); // You'll need to implement this
    return currentPlayer.getValidMoves(diceValue, boardPath);
  }

  /// Check if a token can move
  bool canTokenMove(String tokenId, int diceValue) {
    if (state == null) return false;
    
    final currentPlayer = state!.currentPlayer;
    final token = currentPlayer.tokens.firstWhere(
      (t) => t.id == tokenId,
      orElse: () => currentPlayer.tokens.first,
    );
    
    final boardPath = getBoardPath();
    return currentPlayer.getValidMoves(diceValue, boardPath).contains(token);
  }

  /// Get the board path (simplified version - you'll expand this)
  List<Position> getBoardPath() {
    // This is a simplified version. You'll need to implement the full Ludo board path
    List<Position> path = [];
    
    // Create a simple 52-position path for now
    for (int i = 0; i < 52; i++) {
      // Calculate positions in a clockwise manner around the board
      int x, y;
      if (i < 13) {
        // Bottom side
        x = i;
        y = 14;
      } else if (i < 26) {
        // Right side
        x = 14;
        y = 14 - (i - 13);
      } else if (i < 39) {
        // Top side
        x = 14 - (i - 26);
        y = 0;
      } else {
        // Left side
        x = 0;
        y = i - 39;
      }
      
      path.add(Position(
        x: x,
        y: y,
        type: PositionType.regular,
        pathIndex: i,
      ));
    }
    
    return path;
  }

  /// Create a quick single-player game against AI
  void createQuickGame() {
    final humanPlayer = Player.human(
      name: 'You',
      color: PlayerColor.red,
      homePositions: _getHomePositions(PlayerColor.red),
    );

    final aiPlayer = Player.ai(
      color: PlayerColor.blue,
      homePositions: _getHomePositions(PlayerColor.blue),
      difficulty: AIDifficulty.medium,
    );

    createGame(
      players: [humanPlayer, aiPlayer],
      gameMode: GameMode.singlePlayer,
    );
  }

  /// Get home positions for a player color
  List<Position> _getHomePositions(PlayerColor color) {
    // Return 4 home positions for each player
    // This is simplified - you'll implement the actual board layout
    List<Position> positions = [];
    
    int baseX, baseY;
    switch (color) {
      case PlayerColor.red:
        baseX = 1;
        baseY = 1;
        break;
      case PlayerColor.blue:
        baseX = 13;
        baseY = 1;
        break;
      case PlayerColor.green:
        baseX = 13;
        baseY = 13;
        break;
      case PlayerColor.yellow:
        baseX = 1;
        baseY = 13;
        break;
    }
    
    for (int i = 0; i < 4; i++) {
      positions.add(Position(
        x: baseX + (i % 2),
        y: baseY + (i ~/ 2),
        type: PositionType.home,
        ownerColor: color,
      ));
    }
    
    return positions;
  }
}

/// Provider for dice animation state
final diceAnimationProvider = StateNotifierProvider<DiceAnimationNotifier, bool>((ref) {
  return DiceAnimationNotifier();
});

/// Dice animation state notifier
class DiceAnimationNotifier extends StateNotifier<bool> {
  DiceAnimationNotifier() : super(false);

  void startAnimation() {
    state = true;
  }

  void stopAnimation() {
    state = false;
  }
}

/// Provider for selected token
final selectedTokenProvider = StateNotifierProvider<SelectedTokenNotifier, String?>((ref) {
  return SelectedTokenNotifier();
});

/// Selected token state notifier
class SelectedTokenNotifier extends StateNotifier<String?> {
  SelectedTokenNotifier() : super(null);

  void selectToken(String tokenId) {
    state = tokenId;
  }

  void clearSelection() {
    state = null;
  }
}