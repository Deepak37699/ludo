import 'dart:async';
import 'dart:math' as math;
import '../../data/models/player.dart';
import '../../services/storage/offline_storage_service.dart';
import 'achievement_service.dart';

/// Leaderboard service for managing player rankings and competitive features
class LeaderboardService {
  static const int _maxLeaderboardEntries = 100;
  static final List<LeaderboardEntry> _globalLeaderboard = [];
  static final List<LeaderboardEntry> _localLeaderboard = [];

  /// Initialize leaderboard service
  static Future<void> initialize() async {
    await _loadLocalLeaderboard();
  }

  /// Add or update player score
  static Future<void> updatePlayerScore({
    required String playerId,
    required String playerName,
    required UserStats stats,
    String? profileImageUrl,
  }) async {
    final score = _calculatePlayerScore(stats);
    final achievements = OfflineStorageService.loadAchievements();
    final achievementPoints = AchievementService.calculateTotalPoints(achievements);

    final entry = LeaderboardEntry(
      playerId: playerId,
      playerName: playerName,
      score: score,
      gamesPlayed: stats.gamesPlayed,
      gamesWon: stats.gamesWon,
      winRate: stats.winRate,
      winStreak: stats.winStreak,
      maxWinStreak: stats.maxWinStreak,
      achievementPoints: achievementPoints,
      lastActive: DateTime.now(),
      profileImageUrl: profileImageUrl,
      rank: 0, // Will be calculated when sorting
    );

    await _updateLocalLeaderboard(entry);
  }

  /// Calculate player score based on various factors
  static int _calculatePlayerScore(UserStats stats) {
    // Base score from wins
    int score = stats.gamesWon * 100;

    // Bonus for win rate (0-50% bonus)
    score += (stats.winRate * 50 * stats.gamesWon).round();

    // Bonus for win streaks
    score += stats.maxWinStreak * 25;

    // Bonus for tokens finished
    score += stats.tokensFinished * 2;

    // Bonus for tokens captured
    score += stats.tokensKilled * 5;

    // Bonus for playtime (diminishing returns)
    final hoursPlayed = stats.totalPlayTime.inHours;
    score += (hoursPlayed * 10 * math.log(hoursPlayed + 1)).round();

    return score;
  }

  /// Update local leaderboard
  static Future<void> _updateLocalLeaderboard(LeaderboardEntry entry) async {
    // Remove existing entry for this player
    _localLeaderboard.removeWhere((e) => e.playerId == entry.playerId);

    // Add new entry
    _localLeaderboard.add(entry);

    // Sort by score (descending)
    _localLeaderboard.sort((a, b) => b.score.compareTo(a.score));

    // Limit entries
    if (_localLeaderboard.length > _maxLeaderboardEntries) {
      _localLeaderboard.removeRange(_maxLeaderboardEntries, _localLeaderboard.length);
    }

    // Update ranks
    for (int i = 0; i < _localLeaderboard.length; i++) {
      _localLeaderboard[i] = _localLeaderboard[i].copyWith(rank: i + 1);
    }

    // Save to storage
    await _saveLocalLeaderboard();
  }

  /// Load local leaderboard from storage
  static Future<void> _loadLocalLeaderboard() async {
    // In a real implementation, this would load from local storage
    // For now, we'll start with an empty leaderboard
    _localLeaderboard.clear();
  }

  /// Save local leaderboard to storage
  static Future<void> _saveLocalLeaderboard() async {
    // In a real implementation, this would save to local storage
    // For now, we'll just keep it in memory
  }

  /// Get local leaderboard
  static List<LeaderboardEntry> getLocalLeaderboard({
    int limit = 50,
    LeaderboardFilter filter = LeaderboardFilter.allTime,
  }) {
    var entries = List<LeaderboardEntry>.from(_localLeaderboard);

    // Apply filters
    switch (filter) {
      case LeaderboardFilter.allTime:
        break;
      case LeaderboardFilter.thisWeek:
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        entries = entries.where((e) => e.lastActive.isAfter(weekAgo)).toList();
        break;
      case LeaderboardFilter.thisMonth:
        final monthAgo = DateTime.now().subtract(const Duration(days: 30));
        entries = entries.where((e) => e.lastActive.isAfter(monthAgo)).toList();
        break;
      case LeaderboardFilter.topPlayers:
        entries = entries.where((e) => e.gamesPlayed >= 10).toList();
        break;
    }

    return entries.take(limit).toList();
  }

  /// Get player rank
  static int? getPlayerRank(String playerId) {
    final entry = _localLeaderboard
        .where((e) => e.playerId == playerId)
        .firstOrNull;
    return entry?.rank;
  }

  /// Get player leaderboard entry
  static LeaderboardEntry? getPlayerEntry(String playerId) {
    return _localLeaderboard
        .where((e) => e.playerId == playerId)
        .firstOrNull;
  }

  /// Get players around a specific rank
  static List<LeaderboardEntry> getPlayersAroundRank(int rank, {int range = 5}) {
    final startIndex = math.max(0, rank - range - 1);
    final endIndex = math.min(_localLeaderboard.length, rank + range);
    
    return _localLeaderboard.sublist(startIndex, endIndex);
  }

  /// Get leaderboard statistics
  static LeaderboardStats getLeaderboardStats() {
    if (_localLeaderboard.isEmpty) {
      return const LeaderboardStats(
        totalPlayers: 0,
        averageScore: 0,
        topScore: 0,
        averageWinRate: 0.0,
        totalGamesPlayed: 0,
      );
    }

    final totalPlayers = _localLeaderboard.length;
    final totalScore = _localLeaderboard.fold<int>(0, (sum, entry) => sum + entry.score);
    final averageScore = totalScore / totalPlayers;
    final topScore = _localLeaderboard.first.score;
    final totalWinRate = _localLeaderboard.fold<double>(0, (sum, entry) => sum + entry.winRate);
    final averageWinRate = totalWinRate / totalPlayers;
    final totalGames = _localLeaderboard.fold<int>(0, (sum, entry) => sum + entry.gamesPlayed);

    return LeaderboardStats(
      totalPlayers: totalPlayers,
      averageScore: averageScore.round(),
      topScore: topScore,
      averageWinRate: averageWinRate,
      totalGamesPlayed: totalGames,
    );
  }

  /// Check if player qualifies for leaderboard
  static bool playerQualifiesForLeaderboard(UserStats stats) {
    return stats.gamesPlayed >= 5; // Minimum games to appear on leaderboard
  }

  /// Get rank change for player (comparing to previous period)
  static RankChange? getPlayerRankChange(String playerId) {
    // This would compare current rank to previous rank
    // For now, return null (no change tracking implemented)
    return null;
  }

  /// Get nearby players (similar skill level)
  static List<LeaderboardEntry> getNearbyPlayers(String playerId, {int count = 10}) {
    final playerEntry = getPlayerEntry(playerId);
    if (playerEntry == null) return [];

    final playerRank = playerEntry.rank;
    final halfCount = count ~/ 2;
    
    return getPlayersAroundRank(playerRank, range: halfCount);
  }

  /// Search players by name
  static List<LeaderboardEntry> searchPlayers(String query) {
    if (query.trim().isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return _localLeaderboard
        .where((entry) => entry.playerName.toLowerCase().contains(lowerQuery))
        .take(20)
        .toList();
  }

  /// Get season leaderboard (if seasons are implemented)
  static List<LeaderboardEntry> getSeasonLeaderboard(String seasonId) {
    // Placeholder for seasonal leaderboards
    return [];
  }

  /// Clear leaderboard (for testing/reset)
  static Future<void> clearLeaderboard() async {
    _localLeaderboard.clear();
    await _saveLocalLeaderboard();
  }
}

/// Leaderboard entry representing a player's ranking
class LeaderboardEntry {
  final String playerId;
  final String playerName;
  final int score;
  final int gamesPlayed;
  final int gamesWon;
  final double winRate;
  final int winStreak;
  final int maxWinStreak;
  final int achievementPoints;
  final DateTime lastActive;
  final String? profileImageUrl;
  final int rank;

  const LeaderboardEntry({
    required this.playerId,
    required this.playerName,
    required this.score,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.winRate,
    required this.winStreak,
    required this.maxWinStreak,
    required this.achievementPoints,
    required this.lastActive,
    this.profileImageUrl,
    required this.rank,
  });

  LeaderboardEntry copyWith({
    String? playerId,
    String? playerName,
    int? score,
    int? gamesPlayed,
    int? gamesWon,
    double? winRate,
    int? winStreak,
    int? maxWinStreak,
    int? achievementPoints,
    DateTime? lastActive,
    String? profileImageUrl,
    int? rank,
  }) {
    return LeaderboardEntry(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      score: score ?? this.score,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      winRate: winRate ?? this.winRate,
      winStreak: winStreak ?? this.winStreak,
      maxWinStreak: maxWinStreak ?? this.maxWinStreak,
      achievementPoints: achievementPoints ?? this.achievementPoints,
      lastActive: lastActive ?? this.lastActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rank: rank ?? this.rank,
    );
  }

  /// Get rank tier based on rank position
  RankTier get rankTier {
    if (rank <= 10) return RankTier.grandmaster;
    if (rank <= 50) return RankTier.master;
    if (rank <= 100) return RankTier.diamond;
    if (rank <= 250) return RankTier.platinum;
    if (rank <= 500) return RankTier.gold;
    if (rank <= 1000) return RankTier.silver;
    return RankTier.bronze;
  }

  /// Get formatted rank with suffix
  String get formattedRank {
    if (rank == 1) return '1st';
    if (rank == 2) return '2nd';
    if (rank == 3) return '3rd';
    return '${rank}th';
  }
}

/// Leaderboard filter options
enum LeaderboardFilter {
  allTime,
  thisWeek,
  thisMonth,
  topPlayers,
}

/// Rank tiers for visual representation
enum RankTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  master,
  grandmaster,
}

extension RankTierExtension on RankTier {
  String get displayName {
    switch (this) {
      case RankTier.bronze:
        return 'Bronze';
      case RankTier.silver:
        return 'Silver';
      case RankTier.gold:
        return 'Gold';
      case RankTier.platinum:
        return 'Platinum';
      case RankTier.diamond:
        return 'Diamond';
      case RankTier.master:
        return 'Master';
      case RankTier.grandmaster:
        return 'Grandmaster';
    }
  }

  String get icon {
    switch (this) {
      case RankTier.bronze:
        return '🥉';
      case RankTier.silver:
        return '🥈';
      case RankTier.gold:
        return '🥇';
      case RankTier.platinum:
        return '💍';
      case RankTier.diamond:
        return '💎';
      case RankTier.master:
        return '👑';
      case RankTier.grandmaster:
        return '🏆';
    }
  }
}

/// Rank change information
class RankChange {
  final int previousRank;
  final int currentRank;
  final DateTime changedAt;

  const RankChange({
    required this.previousRank,
    required this.currentRank,
    required this.changedAt,
  });

  int get rankDifference => previousRank - currentRank;
  bool get isImproved => rankDifference > 0;
  bool get isDeclined => rankDifference < 0;
  bool get isUnchanged => rankDifference == 0;
}

/// Leaderboard statistics
class LeaderboardStats {
  final int totalPlayers;
  final int averageScore;
  final int topScore;
  final double averageWinRate;
  final int totalGamesPlayed;

  const LeaderboardStats({
    required this.totalPlayers,
    required this.averageScore,
    required this.topScore,
    required this.averageWinRate,
    required this.totalGamesPlayed,
  });
}

/// Leaderboard season (for future implementation)
class LeaderboardSeason {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final Map<String, dynamic> rewards;

  const LeaderboardSeason({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.rewards = const {},
  });

  bool get isCurrentSeason {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }
}