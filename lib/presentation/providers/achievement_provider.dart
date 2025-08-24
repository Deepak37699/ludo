import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../services/achievements/achievement_service.dart';
import '../../services/achievements/leaderboard_service.dart';
import '../../services/storage/offline_storage_service.dart';
import 'offline_provider.dart';

/// Provider for achievement service
final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService();
});

/// Provider for leaderboard service
final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService();
});

/// Provider for user achievements
final userAchievementsProvider = StateNotifierProvider<UserAchievementsNotifier, UserAchievementsState>((ref) {
  return UserAchievementsNotifier(ref);
});

/// User achievements state
class UserAchievementsState {
  final List<Achievement> achievements;
  final List<AchievementDefinition> allDefinitions;
  final bool isLoading;
  final String? error;
  final int totalPoints;
  final double completionPercentage;
  final List<AchievementUnlocked> recentUnlocks;

  const UserAchievementsState({
    this.achievements = const [],
    this.allDefinitions = const [],
    this.isLoading = false,
    this.error,
    this.totalPoints = 0,
    this.completionPercentage = 0.0,
    this.recentUnlocks = const [],
  });

  UserAchievementsState copyWith({
    List<Achievement>? achievements,
    List<AchievementDefinition>? allDefinitions,
    bool? isLoading,
    String? error,
    int? totalPoints,
    double? completionPercentage,
    List<AchievementUnlocked>? recentUnlocks,
  }) {
    return UserAchievementsState(
      achievements: achievements ?? this.achievements,
      allDefinitions: allDefinitions ?? this.allDefinitions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalPoints: totalPoints ?? this.totalPoints,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      recentUnlocks: recentUnlocks ?? this.recentUnlocks,
    );
  }
}

/// User achievements notifier
class UserAchievementsNotifier extends StateNotifier<UserAchievementsState> {
  final Ref _ref;

  UserAchievementsNotifier(this._ref) : super(const UserAchievementsState()) {
    _initialize();
  }

  /// Initialize achievements
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      AchievementService.initialize();
      
      // Load user achievements
      final achievements = OfflineStorageService.loadAchievements();
      final allDefinitions = AchievementService.getAllAchievements();
      
      // Calculate stats
      final totalPoints = AchievementService.calculateTotalPoints(achievements);
      final completionPercentage = AchievementService.getCompletionPercentage(achievements);

      state = state.copyWith(
        achievements: achievements,
        allDefinitions: allDefinitions,
        totalPoints: totalPoints,
        completionPercentage: completionPercentage,
        isLoading: false,
        error: null,
      );

      // Listen to achievement unlocks
      AchievementService.achievementStream.listen((unlock) {
        _handleAchievementUnlock(unlock);
      });

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      debugPrint('Failed to initialize achievements: $e');
    }
  }

  /// Handle achievement unlock
  void _handleAchievementUnlock(AchievementUnlocked unlock) {
    final updatedAchievements = List<Achievement>.from(state.achievements);
    
    // Remove old version if exists
    updatedAchievements.removeWhere((a) => a.id == unlock.achievement.id);
    
    // Add new unlocked achievement
    updatedAchievements.add(unlock.achievement);

    // Update recent unlocks
    final updatedRecentUnlocks = List<AchievementUnlocked>.from(state.recentUnlocks);
    updatedRecentUnlocks.insert(0, unlock);
    
    // Keep only last 10 recent unlocks
    if (updatedRecentUnlocks.length > 10) {
      updatedRecentUnlocks.removeRange(10, updatedRecentUnlocks.length);
    }

    // Recalculate stats
    final totalPoints = AchievementService.calculateTotalPoints(updatedAchievements);
    final completionPercentage = AchievementService.getCompletionPercentage(updatedAchievements);

    state = state.copyWith(
      achievements: updatedAchievements,
      totalPoints: totalPoints,
      completionPercentage: completionPercentage,
      recentUnlocks: updatedRecentUnlocks,
    );
  }

  /// Check achievements after game events
  Future<void> checkAchievements({
    GameEvent? gameEvent,
  }) async {
    try {
      final userStats = _ref.read(userStatsProvider);
      if (userStats == null) return;

      await AchievementService.checkAchievements(
        userStats: userStats,
        gameEvent: gameEvent,
      );

      // Refresh achievements
      await _refreshAchievements();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Refresh achievements from storage
  Future<void> _refreshAchievements() async {
    final achievements = OfflineStorageService.loadAchievements();
    final totalPoints = AchievementService.calculateTotalPoints(achievements);
    final completionPercentage = AchievementService.getCompletionPercentage(achievements);

    state = state.copyWith(
      achievements: achievements,
      totalPoints: totalPoints,
      completionPercentage: completionPercentage,
    );
  }

  /// Get achievements by category
  List<Achievement> getAchievementsByType(AchievementType type) {
    return state.achievements.where((a) {
      final definition = AchievementService.getAchievementDefinition(a.id);
      return definition?.type == type;
    }).toList();
  }

  /// Get unlocked achievements
  List<Achievement> get unlockedAchievements {
    return state.achievements.where((a) => a.isUnlocked).toList();
  }

  /// Get locked achievements
  List<Achievement> get lockedAchievements {
    return state.achievements.where((a) => !a.isUnlocked).toList();
  }

  /// Clear recent unlocks
  void clearRecentUnlocks() {
    state = state.copyWith(recentUnlocks: []);
  }

  /// Mark recent unlock as seen
  void markRecentUnlockAsSeen(String achievementId) {
    final updatedRecentUnlocks = state.recentUnlocks
        .where((unlock) => unlock.achievement.id != achievementId)
        .toList();
    
    state = state.copyWith(recentUnlocks: updatedRecentUnlocks);
  }
}

/// Provider for leaderboard state
final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref);
});

/// Leaderboard state
class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final LeaderboardFilter currentFilter;
  final bool isLoading;
  final String? error;
  final LeaderboardStats? stats;
  final LeaderboardEntry? userEntry;
  final int? userRank;

  const LeaderboardState({
    this.entries = const [],
    this.currentFilter = LeaderboardFilter.allTime,
    this.isLoading = false,
    this.error,
    this.stats,
    this.userEntry,
    this.userRank,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    LeaderboardFilter? currentFilter,
    bool? isLoading,
    String? error,
    LeaderboardStats? stats,
    LeaderboardEntry? userEntry,
    int? userRank,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      currentFilter: currentFilter ?? this.currentFilter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
      userEntry: userEntry ?? this.userEntry,
      userRank: userRank ?? this.userRank,
    );
  }
}

/// Leaderboard notifier
class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final Ref _ref;

  LeaderboardNotifier(this._ref) : super(const LeaderboardState()) {
    _initialize();
  }

  /// Initialize leaderboard
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      await LeaderboardService.initialize();
      await _loadLeaderboard();
      
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      debugPrint('Failed to initialize leaderboard: $e');
    }
  }

  /// Load leaderboard data
  Future<void> _loadLeaderboard() async {
    final entries = LeaderboardService.getLocalLeaderboard(
      filter: state.currentFilter,
    );
    final stats = LeaderboardService.getLeaderboardStats();

    // Get user's entry if available
    // This would use the actual user ID in a real implementation
    const userId = 'current_user';
    final userEntry = LeaderboardService.getPlayerEntry(userId);
    final userRank = LeaderboardService.getPlayerRank(userId);

    state = state.copyWith(
      entries: entries,
      stats: stats,
      userEntry: userEntry,
      userRank: userRank,
    );
  }

  /// Change leaderboard filter
  Future<void> changeFilter(LeaderboardFilter filter) async {
    if (state.currentFilter == filter) return;

    state = state.copyWith(currentFilter: filter, isLoading: true);
    await _loadLeaderboard();
    state = state.copyWith(isLoading: false);
  }

  /// Update user's leaderboard position
  Future<void> updateUserScore() async {
    try {
      final userStats = _ref.read(userStatsProvider);
      if (userStats == null) return;

      await LeaderboardService.updatePlayerScore(
        playerId: 'current_user',
        playerName: 'Player', // This would be the actual username
        stats: userStats,
      );

      await _loadLeaderboard();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Search players
  List<LeaderboardEntry> searchPlayers(String query) {
    return LeaderboardService.searchPlayers(query);
  }

  /// Get players around user's rank
  List<LeaderboardEntry> getPlayersAroundUser() {
    if (state.userRank == null) return [];
    return LeaderboardService.getPlayersAroundRank(state.userRank!);
  }

  /// Refresh leaderboard
  Future<void> refresh() async {
    await _loadLeaderboard();
  }
}

/// Provider for achievement categories
final achievementCategoriesProvider = Provider<List<AchievementCategory>>((ref) {
  return AchievementCategory.categories;
});

/// Provider for achievements by category
final achievementsByCategoryProvider = Provider.family<List<Achievement>, AchievementType>((ref, type) {
  final achievementsState = ref.watch(userAchievementsProvider);
  return achievementsState.achievements.where((achievement) {
    final definition = AchievementService.getAchievementDefinition(achievement.id);
    return definition?.type == type;
  }).toList();
});

/// Provider for checking if user has recent unlocks
final hasRecentAchievementUnlocksProvider = Provider<bool>((ref) {
  final achievementsState = ref.watch(userAchievementsProvider);
  return achievementsState.recentUnlocks.isNotEmpty;
});

/// Provider for user's rank tier
final userRankTierProvider = Provider<RankTier?>((ref) {
  final leaderboardState = ref.watch(leaderboardProvider);
  return leaderboardState.userEntry?.rankTier;
});

/// Provider for leaderboard actions
final leaderboardActionsProvider = Provider<LeaderboardActions>((ref) {
  return LeaderboardActions(ref);
});

/// Leaderboard actions helper
class LeaderboardActions {
  final Ref _ref;

  LeaderboardActions(this._ref);

  /// Check and update achievements after game completion
  Future<void> processGameCompletion({
    required bool won,
    required Duration gameDuration,
    required int tokensFinished,
    required int tokensKilled,
  }) async {
    // Update user stats would happen in offline provider
    
    // Check achievements
    await _ref.read(userAchievementsProvider.notifier).checkAchievements(
      gameEvent: GameEvent.gameEnded,
    );

    // Update leaderboard
    await _ref.read(leaderboardProvider.notifier).updateUserScore();
  }

  /// Check achievements for specific game events
  Future<void> checkAchievementsForEvent(GameEvent event) async {
    await _ref.read(userAchievementsProvider.notifier).checkAchievements(
      gameEvent: event,
    );
  }
}