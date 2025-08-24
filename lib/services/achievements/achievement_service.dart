import 'dart:async';
import '../../data/models/player.dart';
import '../../data/models/game_state.dart';
import '../../core/enums/game_enums.dart';
import '../storage/offline_storage_service.dart';

/// Achievement system service for tracking and managing player achievements
class AchievementService {
  static final List<AchievementDefinition> _achievementDefinitions = [];
  static final StreamController<AchievementUnlocked> _achievementController = 
      StreamController<AchievementUnlocked>.broadcast();

  /// Stream of achievement unlocks
  static Stream<AchievementUnlocked> get achievementStream => 
      _achievementController.stream;

  /// Initialize achievement system
  static void initialize() {
    _initializeAchievements();
  }

  /// Initialize all achievement definitions
  static void _initializeAchievements() {
    _achievementDefinitions.clear();
    _achievementDefinitions.addAll([
      // First game achievements
      AchievementDefinition(
        id: 'first_game',
        title: 'First Steps',
        description: 'Play your first game',
        type: AchievementType.gameplay,
        target: 1,
        icon: '🎮',
        rarity: AchievementRarity.common,
        points: 10,
      ),
      
      AchievementDefinition(
        id: 'first_win',
        title: 'Victory!',
        description: 'Win your first game',
        type: AchievementType.wins,
        target: 1,
        icon: '🏆',
        rarity: AchievementRarity.common,
        points: 25,
      ),

      // Win streak achievements
      AchievementDefinition(
        id: 'win_streak_3',
        title: 'Hot Streak',
        description: 'Win 3 games in a row',
        type: AchievementType.streaks,
        target: 3,
        icon: '🔥',
        rarity: AchievementRarity.uncommon,
        points: 50,
      ),

      AchievementDefinition(
        id: 'win_streak_5',
        title: 'Unstoppable',
        description: 'Win 5 games in a row',
        type: AchievementType.streaks,
        target: 5,
        icon: '⚡',
        rarity: AchievementRarity.rare,
        points: 100,
      ),

      AchievementDefinition(
        id: 'win_streak_10',
        title: 'Legendary',
        description: 'Win 10 games in a row',
        type: AchievementType.streaks,
        target: 10,
        icon: '👑',
        rarity: AchievementRarity.legendary,
        points: 250,
      ),

      // Total wins achievements
      AchievementDefinition(
        id: 'wins_10',
        title: 'Champion',
        description: 'Win 10 games',
        type: AchievementType.wins,
        target: 10,
        icon: '🥇',
        rarity: AchievementRarity.uncommon,
        points: 75,
      ),

      AchievementDefinition(
        id: 'wins_50',
        title: 'Master',
        description: 'Win 50 games',
        type: AchievementType.wins,
        target: 50,
        icon: '🎖️',
        rarity: AchievementRarity.rare,
        points: 200,
      ),

      AchievementDefinition(
        id: 'wins_100',
        title: 'Grandmaster',
        description: 'Win 100 games',
        type: AchievementType.wins,
        target: 100,
        icon: '🏅',
        rarity: AchievementRarity.epic,
        points: 500,
      ),

      // Token achievements
      AchievementDefinition(
        id: 'tokens_finished_100',
        title: 'Home Runner',
        description: 'Get 100 tokens to finish',
        type: AchievementType.tokens,
        target: 100,
        icon: '🏃',
        rarity: AchievementRarity.uncommon,
        points: 75,
      ),

      AchievementDefinition(
        id: 'tokens_captured_50',
        title: 'Hunter',
        description: 'Capture 50 opponent tokens',
        type: AchievementType.captures,
        target: 50,
        icon: '🎯',
        rarity: AchievementRarity.rare,
        points: 150,
      ),

      // Perfect game achievements
      AchievementDefinition(
        id: 'perfect_game',
        title: 'Flawless Victory',
        description: 'Win without losing any tokens',
        type: AchievementType.special,
        target: 1,
        icon: '💎',
        rarity: AchievementRarity.epic,
        points: 300,
      ),

      AchievementDefinition(
        id: 'quick_win',
        title: 'Speed Demon',
        description: 'Win a game in under 5 minutes',
        type: AchievementType.special,
        target: 1,
        icon: '💨',
        rarity: AchievementRarity.rare,
        points: 200,
      ),

      // Dice achievements
      AchievementDefinition(
        id: 'six_streak_3',
        title: 'Lucky Streak',
        description: 'Roll three 6s in a row',
        type: AchievementType.dice,
        target: 3,
        icon: '🎲',
        rarity: AchievementRarity.rare,
        points: 150,
      ),

      AchievementDefinition(
        id: 'all_sixes',
        title: 'Maximum Luck',
        description: 'Roll 6 on all dice in a turn',
        type: AchievementType.dice,
        target: 1,
        icon: '🍀',
        rarity: AchievementRarity.legendary,
        points: 400,
      ),

      // AI difficulty achievements
      AchievementDefinition(
        id: 'beat_hard_ai',
        title: 'AI Challenger',
        description: 'Beat Hard AI difficulty',
        type: AchievementType.ai,
        target: 1,
        icon: '🤖',
        rarity: AchievementRarity.rare,
        points: 175,
      ),

      AchievementDefinition(
        id: 'beat_expert_ai',
        title: 'AI Master',
        description: 'Beat Expert AI difficulty',
        type: AchievementType.ai,
        target: 1,
        icon: '🧠',
        rarity: AchievementRarity.epic,
        points: 350,
      ),

      // Time-based achievements
      AchievementDefinition(
        id: 'play_time_10h',
        title: 'Dedicated Player',
        description: 'Play for 10 total hours',
        type: AchievementType.time,
        target: 36000, // 10 hours in seconds
        icon: '⏰',
        rarity: AchievementRarity.uncommon,
        points: 100,
      ),

      // Special achievements
      AchievementDefinition(
        id: 'comeback_victory',
        title: 'Comeback King',
        description: 'Win after being in last place',
        type: AchievementType.special,
        target: 1,
        icon: '📈',
        rarity: AchievementRarity.epic,
        points: 300,
      ),
    ]);
  }

  /// Check and update achievements based on game events
  static Future<List<AchievementUnlocked>> checkAchievements({
    required UserStats userStats,
    GameState? gameState,
    GameEvent? gameEvent,
  }) async {
    final unlockedAchievements = <AchievementUnlocked>[];
    final currentAchievements = OfflineStorageService.loadAchievements();

    for (final definition in _achievementDefinitions) {
      // Skip if already unlocked
      if (currentAchievements.any((a) => a.id == definition.id && a.isUnlocked)) {
        continue;
      }

      final currentProgress = _calculateProgress(definition, userStats, gameState, gameEvent);
      
      // Check if achievement should be unlocked
      if (currentProgress >= definition.target) {
        final achievement = Achievement(
          id: definition.id,
          title: definition.title,
          description: definition.description,
          type: definition.type,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
          progress: currentProgress,
          target: definition.target,
        );

        await OfflineStorageService.saveAchievement(achievement);
        
        final unlocked = AchievementUnlocked(
          achievement: achievement,
          definition: definition,
        );
        
        unlockedAchievements.add(unlocked);
        _achievementController.add(unlocked);
      } else {
        // Update progress for locked achievements
        final existingAchievement = currentAchievements
            .where((a) => a.id == definition.id)
            .firstOrNull;
        
        if (existingAchievement == null || existingAchievement.progress < currentProgress) {
          final updatedAchievement = Achievement(
            id: definition.id,
            title: definition.title,
            description: definition.description,
            type: definition.type,
            isUnlocked: false,
            progress: currentProgress,
            target: definition.target,
          );
          
          await OfflineStorageService.saveAchievement(updatedAchievement);
        }
      }
    }

    return unlockedAchievements;
  }

  /// Calculate current progress for an achievement
  static int _calculateProgress(
    AchievementDefinition definition,
    UserStats userStats,
    GameState? gameState,
    GameEvent? gameEvent,
  ) {
    switch (definition.type) {
      case AchievementType.gameplay:
        return userStats.gamesPlayed;
      case AchievementType.wins:
        return userStats.gamesWon;
      case AchievementType.streaks:
        return userStats.maxWinStreak;
      case AchievementType.tokens:
        return userStats.tokensFinished;
      case AchievementType.captures:
        return userStats.tokensKilled;
      case AchievementType.time:
        return userStats.totalPlayTime.inSeconds;
      case AchievementType.dice:
      case AchievementType.ai:
      case AchievementType.special:
        return _calculateSpecialProgress(definition, userStats, gameState, gameEvent);
    }
  }

  /// Calculate progress for special achievements
  static int _calculateSpecialProgress(
    AchievementDefinition definition,
    UserStats userStats,
    GameState? gameState,
    GameEvent? gameEvent,
  ) {
    switch (definition.id) {
      case 'beat_hard_ai':
        return userStats.aiWins[AIDifficulty.hard] ?? 0;
      case 'beat_expert_ai':
        return userStats.aiWins[AIDifficulty.expert] ?? 0;
      case 'six_streak_3':
      case 'all_sixes':
      case 'perfect_game':
      case 'quick_win':
      case 'comeback_victory':
        // These would need specific tracking during gameplay
        return 0; // Placeholder
      default:
        return 0;
    }
  }

  /// Get all achievement definitions
  static List<AchievementDefinition> getAllAchievements() {
    return List.unmodifiable(_achievementDefinitions);
  }

  /// Get achievement definition by ID
  static AchievementDefinition? getAchievementDefinition(String id) {
    return _achievementDefinitions.where((a) => a.id == id).firstOrNull;
  }

  /// Get achievements by category
  static List<AchievementDefinition> getAchievementsByType(AchievementType type) {
    return _achievementDefinitions.where((a) => a.type == type).toList();
  }

  /// Get user's total achievement points
  static int calculateTotalPoints(List<Achievement> unlockedAchievements) {
    int totalPoints = 0;
    for (final achievement in unlockedAchievements) {
      if (achievement.isUnlocked) {
        final definition = getAchievementDefinition(achievement.id);
        if (definition != null) {
          totalPoints += definition.points;
        }
      }
    }
    return totalPoints;
  }

  /// Get completion percentage
  static double getCompletionPercentage(List<Achievement> userAchievements) {
    final totalAchievements = _achievementDefinitions.length;
    final unlockedCount = userAchievements.where((a) => a.isUnlocked).length;
    return totalAchievements > 0 ? unlockedCount / totalAchievements : 0.0;
  }

  /// Dispose achievement service
  static void dispose() {
    _achievementController.close();
  }
}

/// Achievement definition class
class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final int target;
  final String icon;
  final AchievementRarity rarity;
  final int points;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.icon,
    required this.rarity,
    required this.points,
  });
}

/// Achievement rarity levels
enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

/// Achievement unlocked event
class AchievementUnlocked {
  final Achievement achievement;
  final AchievementDefinition definition;

  const AchievementUnlocked({
    required this.achievement,
    required this.definition,
  });
}

/// Game event types for achievement tracking
enum GameEvent {
  gameStarted,
  gameEnded,
  tokenMoved,
  tokenCaptured,
  tokenFinished,
  diceRolled,
  turnEnded,
}

/// Achievement categories for UI organization
class AchievementCategory {
  final String name;
  final String icon;
  final AchievementType type;
  final String description;

  const AchievementCategory({
    required this.name,
    required this.icon,
    required this.type,
    required this.description,
  });

  static const List<AchievementCategory> categories = [
    AchievementCategory(
      name: 'Gameplay',
      icon: '🎮',
      type: AchievementType.gameplay,
      description: 'General gameplay achievements',
    ),
    AchievementCategory(
      name: 'Victories',
      icon: '🏆',
      type: AchievementType.wins,
      description: 'Win-based achievements',
    ),
    AchievementCategory(
      name: 'Streaks',
      icon: '🔥',
      type: AchievementType.streaks,
      description: 'Winning streak achievements',
    ),
    AchievementCategory(
      name: 'Tokens',
      icon: '🎯',
      type: AchievementType.tokens,
      description: 'Token-related achievements',
    ),
    AchievementCategory(
      name: 'AI Challenges',
      icon: '🤖',
      type: AchievementType.ai,
      description: 'AI difficulty achievements',
    ),
    AchievementCategory(
      name: 'Special',
      icon: '⭐',
      type: AchievementType.special,
      description: 'Special and rare achievements',
    ),
  ];
}