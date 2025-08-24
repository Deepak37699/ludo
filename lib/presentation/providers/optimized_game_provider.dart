import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/game_state.dart';
import '../../data/models/player.dart';
import '../../data/models/token.dart';
import '../../data/models/position.dart';
import '../../core/enums/game_enums.dart';
import '../../services/game/game_logic_service.dart';
import '../../services/ai/ai_service.dart';
import '../../services/performance/performance_optimizer.dart';
import '../../services/performance/performance_monitor.dart';

/// Optimized game provider with performance enhancements
final optimizedGameProvider = StateNotifierProvider<OptimizedGameNotifier, OptimizedGameState>((ref) {
  return OptimizedGameNotifier(ref);
});

/// Optimized game state with caching and lazy loading
class OptimizedGameState {
  final GameState? gameState;
  final bool isLoading;
  final String? error;
  final List<Position> validMoves;
  final Position? selectedPosition;
  final bool isAnimating;
  final double animationProgress;
  final Map<String, dynamic> cache;
  final PerformanceSettings performanceSettings;

  const OptimizedGameState({
    this.gameState,
    this.isLoading = false,
    this.error,
    this.validMoves = const [],
    this.selectedPosition,
    this.isAnimating = false,
    this.animationProgress = 0.0,
    this.cache = const {},
    this.performanceSettings = const PerformanceSettings(
      enableAdvancedOptimizations: true,
      enableResourcePooling: true,
      enableAssetPreloading: true,
      maxConcurrentOperations: 3,
      cacheSize: 100,
      preloadedAssetsCount: 0,
    ),
  });

  OptimizedGameState copyWith({
    GameState? gameState,
    bool? isLoading,
    String? error,
    List<Position>? validMoves,
    Position? selectedPosition,
    bool? isAnimating,
    double? animationProgress,
    Map<String, dynamic>? cache,
    PerformanceSettings? performanceSettings,
  }) {
    return OptimizedGameState(
      gameState: gameState ?? this.gameState,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      validMoves: validMoves ?? this.validMoves,
      selectedPosition: selectedPosition,
      isAnimating: isAnimating ?? this.isAnimating,
      animationProgress: animationProgress ?? this.animationProgress,
      cache: cache ?? this.cache,
      performanceSettings: performanceSettings ?? this.performanceSettings,
    );
  }

  /// Get cached value with type safety
  T? getCached<T>(String key) {
    return cache[key] as T?;
  }

  /// Update cache with new value
  OptimizedGameState updateCache(String key, dynamic value) {
    final newCache = Map<String, dynamic>.from(cache);
    newCache[key] = value;
    return copyWith(cache: newCache);
  }

  /// Clear specific cache entry
  OptimizedGameState clearCache(String key) {
    final newCache = Map<String, dynamic>.from(cache);
    newCache.remove(key);
    return copyWith(cache: newCache);
  }

  /// Clear all cache
  OptimizedGameState clearAllCache() {
    return copyWith(cache: {});
  }
}

/// Optimized game notifier with performance monitoring
class OptimizedGameNotifier extends StateNotifier<OptimizedGameState> {
  final Ref _ref;
  final GameLogicService _gameLogic = GameLogicService();
  final AIService _aiService = AIService();
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  final PerformanceMonitor _monitor = PerformanceMonitor();

  // Optimization state
  bool _enableOptimizations = true;
  DateTime _lastUpdateTime = DateTime.now();
  
  OptimizedGameNotifier(this._ref) : super(const OptimizedGameState()) {
    _initializeOptimizations();
  }

  /// Initialize performance optimizations
  Future<void> _initializeOptimizations() async {
    await _optimizer.initialize();
    _monitor.startMonitoring();
    
    // Enable optimizations based on device performance
    _enableOptimizations = await _shouldEnableOptimizations();
    
    debugPrint('🚀 Optimized game provider initialized');
  }

  /// Check if optimizations should be enabled
  Future<bool> _shouldEnableOptimizations() async {
    // In production, check device capabilities
    // For now, enable optimizations in release mode
    return kReleaseMode;
  }

  /// Start a new optimized game
  Future<void> startOptimizedGame({
    required GameMode mode,
    required List<Player> players,
    AIDifficulty aiDifficulty = AIDifficulty.medium,
  }) async {
    await _monitor.measureOperation('start_game', () async {
      state = state.copyWith(isLoading: true, error: null);
      
      try {
        // Create initial game state
        final gameState = await _createOptimizedGameState(
          mode: mode,
          players: players,
          aiDifficulty: aiDifficulty,
        );
        
        // Cache initial calculations
        final initialCache = await _precomputeGameData(gameState);
        
        state = state.copyWith(
          gameState: gameState,
          isLoading: false,
          cache: initialCache,
        );
        
        debugPrint('✅ Optimized game started successfully');
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
        debugPrint('❌ Failed to start optimized game: $e');
      }
    });
  }

  /// Create optimized game state
  Future<GameState> _createOptimizedGameState({
    required GameMode mode,
    required List<Player> players,
    required AIDifficulty aiDifficulty,
  }) async {
    return GameState(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      players: players,
      currentPlayerIndex: 0,
      gameStatus: GameStatus.playing,
      gameMode: mode,
      startTime: DateTime.now(),
    );
  }

  /// Precompute expensive game data
  Future<Map<String, dynamic>> _precomputeGameData(GameState gameState) async {
    final cache = <String, dynamic>{};
    
    if (_enableOptimizations) {
      // Precompute valid moves for current player
      final currentPlayer = gameState.currentPlayer;
      for (int diceValue = 1; diceValue <= 6; diceValue++) {
        final validMoves = _gameLogic.getValidMoves(
          player: currentPlayer,
          diceValue: diceValue,
          gameState: gameState,
        );
        cache['valid_moves_$diceValue'] = validMoves;
      }
      
      // Cache board positions
      cache['board_positions'] = _precomputeBoardPositions();
      
      // Cache player colors
      cache['player_colors'] = {
        for (final player in gameState.players)
          player.id: player.color,
      };
    }
    
    return cache;
  }

  /// Precompute board positions
  List<Position> _precomputeBoardPositions() {
    final positions = <Position>[];
    
    // Generate all board positions
    for (int x = 0; x < 15; x++) {
      for (int y = 0; y < 15; y++) {
        positions.add(Position(
          x: x,
          y: y,
          type: _getPositionType(x, y),
          ownerColor: _getPositionOwner(x, y),
        ));
      }
    }
    
    return positions;
  }

  /// Get position type based on coordinates
  PositionType _getPositionType(int x, int y) {
    // Home areas
    if ((x < 6 && y < 6) || (x > 8 && y < 6) || 
        (x < 6 && y > 8) || (x > 8 && y > 8)) {
      return PositionType.home;
    }
    
    // Safe zones
    if ((x == 2 && y == 6) || (x == 6 && y == 2) ||
        (x == 8 && y == 12) || (x == 12 && y == 8)) {
      return PositionType.safe;
    }
    
    // Start positions
    if ((x == 6 && y == 1) || (x == 13 && y == 6) ||
        (x == 8 && y == 13) || (x == 1 && y == 8)) {
      return PositionType.start;
    }
    
    return PositionType.regular;
  }

  /// Get position owner color
  PlayerColor? _getPositionOwner(int x, int y) {
    if (x < 6 && y < 6) return PlayerColor.red;
    if (x > 8 && y < 6) return PlayerColor.blue;
    if (x < 6 && y > 8) return PlayerColor.green;
    if (x > 8 && y > 8) return PlayerColor.yellow;
    return null;
  }

  /// Roll dice with optimization
  Future<void> rollDice() async {
    await _monitor.measureOperation('roll_dice', () async {
      if (state.gameState == null || !state.gameState!.canRollDice) return;
      
      try {
        final diceValue = _generateOptimizedDiceValue();
        
        // Update game state
        final updatedGameState = state.gameState!.copyWith(
          diceValue: diceValue,
          lastDiceRoll: DateTime.now(),
        );
        
        // Get cached valid moves or calculate
        final cacheKey = 'valid_moves_$diceValue';
        List<Position> validMoves;
        
        if (state.getCached<Map<String, List<Position>>>(cacheKey) != null) {
          final cachedMoves = state.getCached<Map<String, List<Position>>>(cacheKey)!;
          validMoves = cachedMoves.values.expand((x) => x).toList();
        } else {
          final currentPlayer = updatedGameState.currentPlayer;
          final movesMap = _gameLogic.getValidMoves(
            player: currentPlayer,
            diceValue: diceValue,
            gameState: updatedGameState,
          );
          validMoves = movesMap.values.expand((x) => x).toList();
          
          // Cache for future use
          state = state.updateCache(cacheKey, movesMap);
        }
        
        state = state.copyWith(
          gameState: updatedGameState,
          validMoves: validMoves,
        );
        
        // Handle AI turn if needed
        if (!updatedGameState.currentPlayer.isHuman) {
          _handleAITurn(diceValue);
        }
        
      } catch (e) {
        state = state.copyWith(error: e.toString());
      }
    });
  }

  /// Generate optimized dice value
  int _generateOptimizedDiceValue() {
    // In optimized mode, we could potentially cache random sequences
    // or provide more predictable gameplay for performance testing
    return _optimizer.measureSync('generate_dice', () {
      return (DateTime.now().millisecondsSinceEpoch % 6) + 1;
    });
  }

  /// Handle AI turn with optimization
  Future<void> _handleAITurn(int diceValue) async {
    await _monitor.measureOperation('ai_turn', () async {
      if (state.gameState == null) return;
      
      final currentPlayer = state.gameState!.currentPlayer;
      if (currentPlayer.isHuman) return;
      
      // Calculate AI move with caching
      final cacheKey = 'ai_move_${currentPlayer.id}_$diceValue';
      AIMove? aiMove = state.getCached<AIMove>(cacheKey);
      
      if (aiMove == null) {
        aiMove = _aiService.calculateBestMove(
          aiPlayer: currentPlayer,
          diceValue: diceValue,
          gameState: state.gameState!,
          difficulty: currentPlayer.aiDifficulty ?? AIDifficulty.medium,
        );
        
        if (aiMove != null) {
          state = state.updateCache(cacheKey, aiMove);
        }
      }
      
      if (aiMove != null) {
        await Future.delayed(const Duration(milliseconds: 500)); // AI thinking time
        await makeMove(aiMove.tokenId);
      }
    });
  }

  /// Make move with optimization
  Future<void> makeMove(String tokenId) async {
    await _monitor.measureOperation('make_move', () async {
      if (state.gameState?.diceValue == null) return;
      
      try {
        state = state.copyWith(isAnimating: true);
        
        final result = _gameLogic.executeMove(
          tokenId: tokenId,
          diceValue: state.gameState!.diceValue!,
          gameState: state.gameState!,
        );
        
        if (result?.success == true) {
          // Animate move
          await _animateMove();
          
          // Update game state
          state = state.copyWith(
            gameState: result!.gameState,
            selectedPosition: null,
            validMoves: [],
            isAnimating: false,
            animationProgress: 0.0,
          );
          
          // Clear relevant cache entries
          state = state.clearCache('valid_moves_${state.gameState!.diceValue}');
          
          // Check for game end
          _checkGameEnd();
          
        } else {
          state = state.copyWith(
            error: result?.error ?? 'Move failed',
            isAnimating: false,
          );
        }
        
      } catch (e) {
        state = state.copyWith(
          error: e.toString(),
          isAnimating: false,
        );
      }
    });
  }

  /// Animate move with optimization
  Future<void> _animateMove() async {
    if (!_enableOptimizations) return;
    
    const animationDuration = Duration(milliseconds: 300);
    const frameRate = 60;
    const totalFrames = (animationDuration.inMilliseconds * frameRate / 1000).round();
    
    for (int frame = 0; frame <= totalFrames; frame++) {
      final progress = frame / totalFrames;
      
      state = state.copyWith(animationProgress: progress);
      
      await Future.delayed(Duration(milliseconds: animationDuration.inMilliseconds ~/ totalFrames));
    }
  }

  /// Select token with optimization
  void selectToken(String tokenId) {
    _monitor.measureSync('select_token', () {
      if (state.gameState == null) return;
      
      final currentPlayer = state.gameState!.currentPlayer;
      final token = currentPlayer.getTokenById(tokenId);
      
      if (token != null) {
        state = state.copyWith(
          selectedPosition: token.currentPosition,
        );
      }
    });
  }

  /// Check game end conditions
  void _checkGameEnd() {
    if (state.gameState == null) return;
    
    final winner = _gameLogic.checkGameWinner(state.gameState!);
    if (winner != null) {
      final finishedGame = state.gameState!.copyWith(
        gameStatus: GameStatus.finished,
        winner: winner,
        endTime: DateTime.now(),
      );
      
      state = state.copyWith(gameState: finishedGame);
      
      debugPrint('🏆 Game finished! Winner: ${winner.name}');
    }
  }

  /// Update performance settings
  void updatePerformanceSettings(PerformanceSettings settings) {
    _optimizer.updatePerformanceSettings(settings);
    state = state.copyWith(performanceSettings: settings);
    
    debugPrint('⚙️ Performance settings updated');
  }

  /// Get performance summary
  PerformanceSummary getPerformanceSummary() {
    return _monitor.getPerformanceSummary();
  }

  /// Clear cache
  void clearCache() {
    state = state.clearAllCache();
    debugPrint('🧹 Game cache cleared');
  }

  @override
  void dispose() {
    _monitor.stopMonitoring();
    _optimizer.dispose();
    super.dispose();
  }
}

/// Provider for performance settings
final performanceSettingsProvider = StateProvider<PerformanceSettings>((ref) {
  return const PerformanceSettings(
    enableAdvancedOptimizations: true,
    enableResourcePooling: true,
    enableAssetPreloading: true,
    maxConcurrentOperations: 3,
    cacheSize: 100,
    preloadedAssetsCount: 0,
  );
});

/// Provider for performance monitoring
final performanceMonitorProvider = Provider<PerformanceMonitor>((ref) {
  return PerformanceMonitor();
});

/// Provider for performance summary
final performanceSummaryProvider = Provider<PerformanceSummary>((ref) {
  final monitor = ref.watch(performanceMonitorProvider);
  return monitor.getPerformanceSummary();
});

/// Provider for checking if performance is good
final isPerformanceGoodProvider = Provider<bool>((ref) {
  final monitor = ref.watch(performanceMonitorProvider);
  return monitor.isPerformanceGood;
});

/// Provider for performance warnings
final performanceWarningsProvider = Provider<List<String>>((ref) {
  final monitor = ref.watch(performanceMonitorProvider);
  return monitor.getPerformanceWarnings();
});