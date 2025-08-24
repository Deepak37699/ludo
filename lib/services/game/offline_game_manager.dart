import 'dart:async';
import '../../data/models/game_state.dart';
import '../../data/models/player.dart';
import '../../core/enums/game_enums.dart';
import '../storage/offline_storage_service.dart';
import '../game/game_engine.dart';
import '../game/ai_player_service.dart';

/// Offline game manager for handling local gameplay and data persistence
class OfflineGameManager {
  static const String _currentGameKey = 'current_game';
  static GameState? _currentGame;
  static StreamController<GameState>? _gameStateController;
  static Timer? _autoSaveTimer;

  /// Initialize offline game manager
  static Future<void> initialize() async {
    await OfflineStorageService.initialize();
    _gameStateController = StreamController<GameState>.broadcast();
    
    // Setup auto-save timer (save every 30 seconds)
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentGame != null) {
        _autoSaveCurrentGame();
      }
    });
  }

  /// Stream of game state changes
  static Stream<GameState> get gameStateStream => 
    _gameStateController?.stream ?? const Stream.empty();

  /// Current game state
  static GameState? get currentGame => _currentGame;

  /// Create a new offline game
  static Future<GameState> createOfflineGame({
    required GameMode mode,
    required List<Player> players,
    AIDifficulty aiDifficulty = AIDifficulty.medium,
  }) async {
    final gameState = GameEngine.createGame(
      mode: mode,
      players: players,
      isOnline: false,
    );

    _currentGame = gameState;
    await _saveCurrentGame();
    _gameStateController?.add(gameState);

    return gameState;
  }

  /// Load saved game
  static Future<GameState?> loadSavedGame([String? gameId]) async {
    if (!OfflineStorageService.isOfflineModeAvailable()) {
      return null;
    }

    final savedGame = gameId != null 
      ? OfflineStorageService.loadGameState(gameId)
      : OfflineStorageService.loadGameState(_currentGameKey);

    if (savedGame != null) {
      _currentGame = savedGame;
      _gameStateController?.add(savedGame);
    }

    return savedGame;
  }

  /// Resume current game
  static Future<GameState?> resumeCurrentGame() async {
    return await loadSavedGame(_currentGameKey);
  }

  /// Save current game
  static Future<void> saveCurrentGame() async {
    await _saveCurrentGame();
  }

  /// Private method to save current game
  static Future<void> _saveCurrentGame() async {
    if (_currentGame != null) {
      await OfflineStorageService.saveGameState(_currentGameKey, _currentGame!);
    }
  }

  /// Auto-save current game (called by timer)
  static Future<void> _autoSaveCurrentGame() async {
    try {
      await _saveCurrentGame();
    } catch (e) {
      // Log error but don't throw to avoid disrupting gameplay
      print('Auto-save failed: $e');
    }
  }

  /// Make a move in offline game
  static Future<GameState> makeMove({
    required String tokenId,
    required int diceValue,
  }) async {
    if (_currentGame == null) {
      throw Exception('No active game');
    }

    // Execute move using game engine
    final updatedGame = GameEngine.makeMove(
      gameState: _currentGame!,
      tokenId: tokenId,
      diceValue: diceValue,
    );

    _currentGame = updatedGame;
    _gameStateController?.add(updatedGame);

    // Auto-save after each move
    await _saveCurrentGame();

    // If next player is AI, make AI move
    if (updatedGame.gameStatus == GameStatus.playing) {
      final currentPlayer = updatedGame.currentPlayer;
      if (!currentPlayer.isHuman) {
        await _makeAIMove();
      }
    }

    return _currentGame!;
  }

  /// Roll dice in offline game
  static Future<GameState> rollDice() async {
    if (_currentGame == null) {
      throw Exception('No active game');
    }

    final updatedGame = GameEngine.rollDice(_currentGame!);
    _currentGame = updatedGame;
    _gameStateController?.add(updatedGame);

    await _saveCurrentGame();
    return updatedGame;
  }

  /// Make AI move
  static Future<void> _makeAIMove() async {
    if (_currentGame == null) return;

    final currentPlayer = _currentGame!.currentPlayer;
    if (currentPlayer.isHuman) return;

    // Add realistic thinking delay
    final thinkingDelay = AIPlayerService.getThinkingDelay(
      currentPlayer.aiDifficulty ?? AIDifficulty.medium
    );
    
    await Future.delayed(thinkingDelay);

    // Get AI decision
    final aiDecision = AIPlayerService.makeMove(
      gameState: _currentGame!,
      aiPlayer: currentPlayer,
      diceValue: _currentGame!.diceValue,
      difficulty: currentPlayer.aiDifficulty ?? AIDifficulty.medium,
    );

    if (aiDecision.isMove && aiDecision.tokenId != null) {
      await makeMove(
        tokenId: aiDecision.tokenId!,
        diceValue: _currentGame!.diceValue,
      );
    } else {
      // AI skips turn
      await endTurn();
    }
  }

  /// End current player's turn
  static Future<GameState> endTurn() async {
    if (_currentGame == null) {
      throw Exception('No active game');
    }

    final updatedGame = GameEngine.endTurn(_currentGame!);
    _currentGame = updatedGame;
    _gameStateController?.add(updatedGame);

    await _saveCurrentGame();

    // Check if next player is AI
    if (updatedGame.gameStatus == GameStatus.playing) {
      final currentPlayer = updatedGame.currentPlayer;
      if (!currentPlayer.isHuman) {
        // Delay AI move to make it feel natural
        Future.delayed(const Duration(milliseconds: 500), () {
          _makeAIMove();
        });
      }
    }

    return updatedGame;
  }

  /// Pause current game
  static Future<GameState> pauseGame() async {
    if (_currentGame == null) {
      throw Exception('No active game');
    }

    final updatedGame = _currentGame!.copyWith(
      gameStatus: GameStatus.paused,
    );

    _currentGame = updatedGame;
    _gameStateController?.add(updatedGame);
    await _saveCurrentGame();

    return updatedGame;
  }

  /// Resume paused game
  static Future<GameState> resumeGame() async {
    if (_currentGame == null) {
      throw Exception('No active game');
    }

    final updatedGame = _currentGame!.copyWith(
      gameStatus: GameStatus.playing,
    );

    _currentGame = updatedGame;
    _gameStateController?.add(updatedGame);
    await _saveCurrentGame();

    return updatedGame;
  }

  /// End current game
  static Future<void> endGame() async {
    if (_currentGame == null) return;

    // Save game to history if it was actually played
    if (_currentGame!.turnCount > 0) {
      await _saveGameToHistory();
      await _updateUserStats();
    }

    // Clear current game
    await OfflineStorageService.deleteSavedGame(_currentGameKey);
    _currentGame = null;
  }

  /// Save completed game to history
  static Future<void> _saveGameToHistory() async {
    if (_currentGame == null) return;

    final gameHistory = GameHistory(
      id: _currentGame!.id,
      mode: _currentGame!.gameMode,
      playerNames: _currentGame!.players.map((p) => p.name).toList(),
      winnerName: _currentGame!.winner?.name,
      gameDuration: _currentGame!.gameDuration,
      completedAt: DateTime.now(),
      totalMoves: _currentGame!.turnCount,
      aiDifficulty: _currentGame!.players
          .where((p) => !p.isHuman)
          .firstOrNull
          ?.aiDifficulty,
    );

    await OfflineStorageService.saveGameHistory(gameHistory);
  }

  /// Update user statistics
  static Future<void> _updateUserStats() async {
    if (_currentGame == null) return;

    final currentStats = OfflineStorageService.loadUserStats() ?? 
      UserStats(lastPlayed: DateTime.now());

    final humanPlayer = _currentGame!.players.firstWhere(
      (p) => p.isHuman,
      orElse: () => _currentGame!.players.first,
    );

    final isWinner = _currentGame!.winner?.id == humanPlayer.id;
    final newWinStreak = isWinner ? currentStats.winStreak + 1 : 0;

    final updatedStats = currentStats.copyWith(
      gamesPlayed: currentStats.gamesPlayed + 1,
      gamesWon: currentStats.gamesWon + (isWinner ? 1 : 0),
      winStreak: newWinStreak,
      maxWinStreak: newWinStreak > currentStats.maxWinStreak 
        ? newWinStreak 
        : currentStats.maxWinStreak,
      totalPlayTime: currentStats.totalPlayTime + _currentGame!.gameDuration,
      lastPlayed: DateTime.now(),
      tokensFinished: currentStats.tokensFinished + 
        humanPlayer.tokens.where((t) => t.hasFinished).length,
      tokensKilled: currentStats.tokensKilled + 
        _calculateTokensKilled(humanPlayer),
    );

    await OfflineStorageService.saveUserStats(updatedStats);
  }

  /// Calculate tokens killed by player
  static int _calculateTokensKilled(Player player) {
    // This would need to be tracked during gameplay
    // For now, return 0 as placeholder
    return 0;
  }

  /// Get all saved games
  static List<GameState> getAllSavedGames() {
    return OfflineStorageService.getAllSavedGames();
  }

  /// Delete saved game
  static Future<void> deleteSavedGame(String gameId) async {
    await OfflineStorageService.deleteSavedGame(gameId);
  }

  /// Get user statistics
  static UserStats? getUserStats() {
    return OfflineStorageService.loadUserStats();
  }

  /// Get game history
  static List<GameHistory> getGameHistory() {
    return OfflineStorageService.loadGameHistory();
  }

  /// Check if offline mode is available
  static bool isOfflineModeAvailable() {
    return OfflineStorageService.isOfflineModeAvailable();
  }

  /// Get storage usage information
  static Future<OfflineStorageInfo> getStorageInfo() async {
    final sizeBytes = await OfflineStorageService.getStorageSize();
    final savedGames = getAllSavedGames().length;
    final gameHistory = getGameHistory().length;

    return OfflineStorageInfo(
      totalSizeBytes: sizeBytes,
      savedGamesCount: savedGames,
      gameHistoryCount: gameHistory,
    );
  }

  /// Clear all offline data
  static Future<void> clearAllData() async {
    _currentGame = null;
    await OfflineStorageService.clearAllData();
  }

  /// Dispose resources
  static Future<void> dispose() async {
    _autoSaveTimer?.cancel();
    await _gameStateController?.close();
    await OfflineStorageService.close();
  }
}

/// Offline storage information
class OfflineStorageInfo {
  final int totalSizeBytes;
  final int savedGamesCount;
  final int gameHistoryCount;

  const OfflineStorageInfo({
    required this.totalSizeBytes,
    required this.savedGamesCount,
    required this.gameHistoryCount,
  });

  double get totalSizeMB => totalSizeBytes / (1024 * 1024);
  
  String get formattedSize {
    if (totalSizeBytes < 1024) {
      return '$totalSizeBytes B';
    } else if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

/// Offline game quick access methods
class OfflineGameQuickActions {
  /// Start quick game against AI
  static Future<GameState> startQuickGame({
    AIDifficulty difficulty = AIDifficulty.medium,
    String playerName = 'Player',
  }) async {
    final humanPlayer = Player.human(
      id: 'human_player',
      name: playerName,
      color: PlayerColor.red,
    );

    final aiPlayer = Player.ai(
      id: 'ai_player',
      name: 'AI Opponent',
      color: PlayerColor.blue,
      difficulty: difficulty,
    );

    return await OfflineGameManager.createOfflineGame(
      mode: GameMode.vsAI,
      players: [humanPlayer, aiPlayer],
      aiDifficulty: difficulty,
    );
  }

  /// Continue last game if available
  static Future<GameState?> continueLastGame() async {
    return await OfflineGameManager.resumeCurrentGame();
  }

  /// Check if there's a game to continue
  static bool hasGameToContinue() {
    final savedGame = OfflineStorageService.loadGameState('current_game');
    return savedGame != null && savedGame.gameStatus != GameStatus.finished;
  }
}