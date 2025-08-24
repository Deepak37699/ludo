import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/game_state.dart';
import '../../services/game/offline_game_manager.dart';
import '../../services/storage/offline_storage_service.dart';
import '../../services/connectivity/connectivity_service.dart';
import '../../core/enums/game_enums.dart';

/// Provider for offline game manager
final offlineGameManagerProvider = Provider<OfflineGameManager>((ref) {
  return OfflineGameManager();
});

/// Provider for connectivity status
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  return ConnectivityService.statusStream;
});

/// Provider for checking if device is online
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityStatusProvider);
  return connectivityAsync.when(
    data: (status) => status == ConnectivityStatus.online,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for checking if offline mode is available
final isOfflineModeAvailableProvider = Provider<bool>((ref) {
  return OfflineGameManager.isOfflineModeAvailable();
});

/// Provider for current offline game state
final offlineGameStateProvider = StreamProvider<GameState?>((ref) {
  return OfflineGameManager.gameStateStream;
});

/// Provider for offline game notifier
final offlineGameNotifierProvider = 
    StateNotifierProvider<OfflineGameNotifier, OfflineGameState>((ref) {
  return OfflineGameNotifier(ref);
});

/// Offline game state
class OfflineGameState {
  final GameState? currentGame;
  final bool isLoading;
  final String? error;
  final bool hasGameToContinue;
  final OfflineStorageInfo? storageInfo;

  const OfflineGameState({
    this.currentGame,
    this.isLoading = false,
    this.error,
    this.hasGameToContinue = false,
    this.storageInfo,
  });

  OfflineGameState copyWith({
    GameState? currentGame,
    bool? isLoading,
    String? error,
    bool? hasGameToContinue,
    OfflineStorageInfo? storageInfo,
  }) {
    return OfflineGameState(
      currentGame: currentGame ?? this.currentGame,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasGameToContinue: hasGameToContinue ?? this.hasGameToContinue,
      storageInfo: storageInfo ?? this.storageInfo,
    );
  }
}

/// Offline game state notifier
class OfflineGameNotifier extends StateNotifier<OfflineGameState> {
  final Ref _ref;

  OfflineGameNotifier(this._ref) : super(const OfflineGameState()) {
    _initialize();
  }

  /// Initialize offline game notifier
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await OfflineGameManager.initialize();
      
      final hasGameToContinue = OfflineGameQuickActions.hasGameToContinue();
      final storageInfo = await OfflineGameManager.getStorageInfo();
      
      state = state.copyWith(
        isLoading: false,
        hasGameToContinue: hasGameToContinue,
        storageInfo: storageInfo,
        error: null,
      );
      
      // Listen to game state changes
      OfflineGameManager.gameStateStream.listen((gameState) {
        state = state.copyWith(currentGame: gameState);
      });
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      debugPrint('Failed to initialize offline game: $e');
    }
  }

  /// Start new offline game
  Future<void> startNewGame({
    required GameMode mode,
    required List<Player> players,
    AIDifficulty aiDifficulty = AIDifficulty.medium,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final gameState = await OfflineGameManager.createOfflineGame(
        mode: mode,
        players: players,
        aiDifficulty: aiDifficulty,
      );
      
      state = state.copyWith(
        currentGame: gameState,
        isLoading: false,
        hasGameToContinue: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Start quick game against AI
  Future<void> startQuickGame({
    AIDifficulty difficulty = AIDifficulty.medium,
    String playerName = 'Player',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final gameState = await OfflineGameQuickActions.startQuickGame(
        difficulty: difficulty,
        playerName: playerName,
      );
      
      state = state.copyWith(
        currentGame: gameState,
        isLoading: false,
        hasGameToContinue: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Continue last game
  Future<void> continueLastGame() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final gameState = await OfflineGameQuickActions.continueLastGame();
      
      state = state.copyWith(
        currentGame: gameState,
        isLoading: false,
        hasGameToContinue: gameState != null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Make move in current game
  Future<void> makeMove({
    required String tokenId,
    required int diceValue,
  }) async {
    if (state.currentGame == null) return;

    try {
      await OfflineGameManager.makeMove(
        tokenId: tokenId,
        diceValue: diceValue,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Roll dice
  Future<void> rollDice() async {
    if (state.currentGame == null) return;

    try {
      await OfflineGameManager.rollDice();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// End turn
  Future<void> endTurn() async {
    if (state.currentGame == null) return;

    try {
      await OfflineGameManager.endTurn();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Pause game
  Future<void> pauseGame() async {
    if (state.currentGame == null) return;

    try {
      await OfflineGameManager.pauseGame();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Resume game
  Future<void> resumeGame() async {
    if (state.currentGame == null) return;

    try {
      await OfflineGameManager.resumeGame();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// End current game
  Future<void> endGame() async {
    try {
      await OfflineGameManager.endGame();
      state = state.copyWith(
        currentGame: null,
        hasGameToContinue: false,
      );
      
      // Refresh storage info
      final storageInfo = await OfflineGameManager.getStorageInfo();
      state = state.copyWith(storageInfo: storageInfo);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Save current game
  Future<void> saveGame() async {
    try {
      await OfflineGameManager.saveCurrentGame();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Refresh storage info
  Future<void> refreshStorageInfo() async {
    try {
      final storageInfo = await OfflineGameManager.getStorageInfo();
      state = state.copyWith(storageInfo: storageInfo);
    } catch (e) {
      debugPrint('Failed to refresh storage info: $e');
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for user statistics
final userStatsProvider = Provider<UserStats?>((ref) {
  return OfflineGameManager.getUserStats();
});

/// Provider for game history
final gameHistoryProvider = Provider<List<GameHistory>>((ref) {
  return OfflineGameManager.getGameHistory();
});

/// Provider for saved games list
final savedGamesProvider = Provider<List<GameState>>((ref) {
  return OfflineGameManager.getAllSavedGames();
});

/// Provider for storage information
final storageInfoProvider = FutureProvider<OfflineStorageInfo>((ref) async {
  return await OfflineGameManager.getStorageInfo();
});

/// Provider for offline achievements
final offlineAchievementsProvider = Provider<List<Achievement>>((ref) {
  return OfflineStorageService.loadAchievements();
});

/// Provider for connectivity info
final connectivityInfoProvider = FutureProvider<ConnectivityInfo>((ref) async {
  return await ConnectivityService.getConnectivityInfo();
});

/// Provider for network-aware game actions
final networkAwareGameActionsProvider = Provider<NetworkAwareGameActions>((ref) {
  return NetworkAwareGameActions(ref);
});

/// Network-aware game actions helper
class NetworkAwareGameActions {
  final Ref _ref;

  NetworkAwareGameActions(this._ref);

  /// Start game with network awareness
  Future<void> startGame({
    required GameMode mode,
    required List<Player> players,
    AIDifficulty aiDifficulty = AIDifficulty.medium,
  }) async {
    final isOnline = _ref.read(isOnlineProvider);
    
    if (isOnline && mode.requiresOnline) {
      // Start online game
      // This would integrate with online game service
      throw UnimplementedError('Online game not implemented yet');
    } else {
      // Start offline game
      await _ref.read(offlineGameNotifierProvider.notifier).startNewGame(
        mode: mode,
        players: players,
        aiDifficulty: aiDifficulty,
      );
    }
  }

  /// Continue game with network awareness
  Future<void> continueGame() async {
    final isOnline = _ref.read(isOnlineProvider);
    
    if (isOnline) {
      // Try to sync and continue online game first
      // Fall back to offline if needed
    }
    
    // Continue offline game
    await _ref.read(offlineGameNotifierProvider.notifier).continueLastGame();
  }

  /// Save game with network awareness
  Future<void> saveGame() async {
    // Always save offline first
    await _ref.read(offlineGameNotifierProvider.notifier).saveGame();
    
    // Sync to cloud if online
    final isOnline = _ref.read(isOnlineProvider);
    if (isOnline) {
      // Sync to cloud storage
      // This would integrate with Firebase or other cloud service
    }
  }
}

/// Extension for GameMode to check online requirements
extension GameModeExtension on GameMode {
  bool get requiresOnline {
    switch (this) {
      case GameMode.online:
      case GameMode.tournament:
        return true;
      case GameMode.vsAI:
      case GameMode.local:
        return false;
    }
  }
}

/// Provider for offline sync status
final offlineSyncStatusProvider = StateProvider<OfflineSyncStatus>((ref) {
  return OfflineSyncStatus.synced;
});

/// Offline sync status
enum OfflineSyncStatus {
  synced,
  pending,
  syncing,
  failed,
}

/// Provider for managing offline to online sync
final offlineSyncManagerProvider = Provider<OfflineSyncManager>((ref) {
  return OfflineSyncManager(ref);
});

/// Offline sync manager
class OfflineSyncManager {
  final Ref _ref;

  OfflineSyncManager(this._ref);

  /// Sync offline data to online services
  Future<void> syncToOnline() async {
    final isOnline = _ref.read(isOnlineProvider);
    if (!isOnline) return;

    _ref.read(offlineSyncStatusProvider.notifier).state = OfflineSyncStatus.syncing;

    try {
      // Sync user stats
      await _syncUserStats();
      
      // Sync achievements
      await _syncAchievements();
      
      // Sync game history
      await _syncGameHistory();
      
      _ref.read(offlineSyncStatusProvider.notifier).state = OfflineSyncStatus.synced;
    } catch (e) {
      _ref.read(offlineSyncStatusProvider.notifier).state = OfflineSyncStatus.failed;
      debugPrint('Offline sync failed: $e');
    }
  }

  Future<void> _syncUserStats() async {
    // Implementation would sync user stats to Firebase
  }

  Future<void> _syncAchievements() async {
    // Implementation would sync achievements to Firebase
  }

  Future<void> _syncGameHistory() async {
    // Implementation would sync game history to Firebase
  }
}