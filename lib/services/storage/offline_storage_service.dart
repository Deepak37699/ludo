import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/game_state.dart';
import '../../data/models/player.dart';
import '../../core/enums/game_enums.dart';
import '../../data/adapters/hive_adapters.dart';

/// Offline storage service using Hive for local data persistence
class OfflineStorageService {
  static const String _gameStateBoxName = 'game_states';
  static const String _userStatsBoxName = 'user_stats';
  static const String _settingsBoxName = 'app_settings';
  static const String _achievementsBoxName = 'achievements';
  static const String _gameHistoryBoxName = 'game_history';

  static Box<GameState>? _gameStateBox;
  static Box<UserStats>? _userStatsBox;
  static Box<Map>? _settingsBox;
  static Box<Achievement>? _achievementsBox;
  static Box<GameHistory>? _gameHistoryBox;

  /// Initialize Hive and register adapters
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register type adapters
    _registerAdapters();
    
    // Open boxes
    await _openBoxes();
  }

  /// Register all Hive type adapters
  static void _registerAdapters() {
    // Register enums
    Hive.registerAdapter(PlayerColorAdapter());
    Hive.registerAdapter(TokenStateAdapter());
    Hive.registerAdapter(GameStatusAdapter());
    Hive.registerAdapter(GameModeAdapter());
    Hive.registerAdapter(PositionTypeAdapter());
    Hive.registerAdapter(AIDifficultyAdapter());
    Hive.registerAdapter(AchievementTypeAdapter());
    
    // Register models
    Hive.registerAdapter(GameStateAdapter());
    Hive.registerAdapter(PlayerAdapter());
    Hive.registerAdapter(TokenAdapter());
    Hive.registerAdapter(PositionAdapter());
    Hive.registerAdapter(UserStatsAdapter());
    Hive.registerAdapter(AchievementAdapter());
    Hive.registerAdapter(GameHistoryAdapter());
  }

  /// Open all Hive boxes
  static Future<void> _openBoxes() async {
    _gameStateBox = await Hive.openBox<GameState>(_gameStateBoxName);
    _userStatsBox = await Hive.openBox<UserStats>(_userStatsBoxName);
    _settingsBox = await Hive.openBox<Map>(_settingsBoxName);
    _achievementsBox = await Hive.openBox<Achievement>(_achievementsBoxName);
    _gameHistoryBox = await Hive.openBox<GameHistory>(_gameHistoryBoxName);
  }

  /// Save game state for offline play
  static Future<void> saveGameState(String gameId, GameState gameState) async {
    await _gameStateBox?.put(gameId, gameState);
  }

  /// Load saved game state
  static GameState? loadGameState(String gameId) {
    return _gameStateBox?.get(gameId);
  }

  /// Get all saved games
  static List<GameState> getAllSavedGames() {
    return _gameStateBox?.values.toList() ?? [];
  }

  /// Delete saved game
  static Future<void> deleteSavedGame(String gameId) async {
    await _gameStateBox?.delete(gameId);
  }

  /// Save user statistics
  static Future<void> saveUserStats(UserStats stats) async {
    await _userStatsBox?.put('current_user', stats);
  }

  /// Load user statistics
  static UserStats? loadUserStats() {
    return _userStatsBox?.get('current_user');
  }

  /// Save app settings
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _settingsBox?.put('app_settings', settings);
  }

  /// Load app settings
  static Map<String, dynamic>? loadSettings() {
    return _settingsBox?.get('app_settings')?.cast<String, dynamic>();
  }

  /// Save achievement
  static Future<void> saveAchievement(Achievement achievement) async {
    await _achievementsBox?.put(achievement.id, achievement);
  }

  /// Load all achievements
  static List<Achievement> loadAchievements() {
    return _achievementsBox?.values.toList() ?? [];
  }

  /// Save game to history
  static Future<void> saveGameHistory(GameHistory gameHistory) async {
    await _gameHistoryBox?.put(gameHistory.id, gameHistory);
    
    // Keep only last 100 games
    if (_gameHistoryBox!.length > 100) {
      final oldestKey = _gameHistoryBox!.keys.first;
      await _gameHistoryBox!.delete(oldestKey);
    }
  }

  /// Load game history
  static List<GameHistory> loadGameHistory() {
    final history = _gameHistoryBox?.values.toList() ?? [];
    history.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return history;
  }

  /// Clear all data
  static Future<void> clearAllData() async {
    await _gameStateBox?.clear();
    await _userStatsBox?.clear();
    await _settingsBox?.clear();
    await _achievementsBox?.clear();
    await _gameHistoryBox?.clear();
  }

  /// Check if offline mode is available
  static bool isOfflineModeAvailable() {
    return _gameStateBox != null && 
           _userStatsBox != null && 
           _settingsBox != null;
  }

  /// Get storage size in bytes
  static Future<int> getStorageSize() async {
    int totalSize = 0;
    
    if (_gameStateBox != null) {
      totalSize += await _getBoxSize(_gameStateBoxName);
    }
    if (_userStatsBox != null) {
      totalSize += await _getBoxSize(_userStatsBoxName);
    }
    if (_settingsBox != null) {
      totalSize += await _getBoxSize(_settingsBoxName);
    }
    if (_achievementsBox != null) {
      totalSize += await _getBoxSize(_achievementsBoxName);
    }
    if (_gameHistoryBox != null) {
      totalSize += await _getBoxSize(_gameHistoryBoxName);
    }
    
    return totalSize;
  }

  /// Get size of a specific box
  static Future<int> _getBoxSize(String boxName) async {
    // This is an approximation since Hive doesn't provide direct size info
    final box = await Hive.openBox(boxName);
    return box.length * 1024; // Rough estimate: 1KB per entry
  }

  /// Close all boxes
  static Future<void> close() async {
    await _gameStateBox?.close();
    await _userStatsBox?.close();
    await _settingsBox?.close();
    await _achievementsBox?.close();
    await _gameHistoryBox?.close();
  }
}

/// User statistics model for offline storage
@HiveType(typeId: 10)
class UserStats extends HiveObject {
  @HiveField(0)
  final int gamesPlayed;

  @HiveField(1)
  final int gamesWon;

  @HiveField(2)
  final int tokensKilled;

  @HiveField(3)
  final int tokensFinished;

  @HiveField(4)
  final Duration totalPlayTime;

  @HiveField(5)
  final int winStreak;

  @HiveField(6)
  final int maxWinStreak;

  @HiveField(7)
  final DateTime lastPlayed;

  @HiveField(8)
  final Map<AIDifficulty, int> aiWins;

  UserStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.tokensKilled = 0,
    this.tokensFinished = 0,
    this.totalPlayTime = Duration.zero,
    this.winStreak = 0,
    this.maxWinStreak = 0,
    required this.lastPlayed,
    this.aiWins = const {},
  });

  double get winRate => gamesPlayed > 0 ? gamesWon / gamesPlayed : 0.0;

  UserStats copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? tokensKilled,
    int? tokensFinished,
    Duration? totalPlayTime,
    int? winStreak,
    int? maxWinStreak,
    DateTime? lastPlayed,
    Map<AIDifficulty, int>? aiWins,
  }) {
    return UserStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      tokensKilled: tokensKilled ?? this.tokensKilled,
      tokensFinished: tokensFinished ?? this.tokensFinished,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
      winStreak: winStreak ?? this.winStreak,
      maxWinStreak: maxWinStreak ?? this.maxWinStreak,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      aiWins: aiWins ?? this.aiWins,
    );
  }
}

/// Achievement model for offline storage
@HiveType(typeId: 11)
class Achievement extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final AchievementType type;

  @HiveField(4)
  final bool isUnlocked;

  @HiveField(5)
  final DateTime? unlockedAt;

  @HiveField(6)
  final int progress;

  @HiveField(7)
  final int target;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0,
    required this.target,
  });

  double get progressPercent => target > 0 ? progress / target : 0.0;

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    AchievementType? type,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? progress,
    int? target,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      target: target ?? this.target,
    );
  }
}

/// Game history model for offline storage
@HiveType(typeId: 12)
class GameHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final GameMode mode;

  @HiveField(2)
  final List<String> playerNames;

  @HiveField(3)
  final String? winnerName;

  @HiveField(4)
  final Duration gameDuration;

  @HiveField(5)
  final DateTime completedAt;

  @HiveField(6)
  final int totalMoves;

  @HiveField(7)
  final AIDifficulty? aiDifficulty;

  GameHistory({
    required this.id,
    required this.mode,
    required this.playerNames,
    this.winnerName,
    required this.gameDuration,
    required this.completedAt,
    this.totalMoves = 0,
    this.aiDifficulty,
  });
}