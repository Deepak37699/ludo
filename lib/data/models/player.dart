import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../core/enums/game_enums.dart';
import 'token.dart';
import 'position.dart';

part 'player.g.dart';

/// Represents a player in the Ludo game
@JsonSerializable()
class Player extends Equatable {
  const Player({
    required this.id,
    required this.name,
    required this.color,
    required this.tokens,
    this.avatar = '',
    this.score = 0,
    this.isCurrentTurn = false,
    this.isHuman = true,
    this.isHost = false,
    this.isReady = false,
    this.aiDifficulty,
    this.totalGamesPlayed = 0,
    this.totalGamesWon = 0,
    this.achievements = const [],
    this.consecutiveRolls = 0,
    this.lastMoveTime,
  });

  /// Unique identifier for the player
  final String id;

  /// Display name of the player
  final String name;

  /// Player's color (determines token color and starting position)
  final PlayerColor color;

  /// List of tokens owned by this player
  final List<Token> tokens;

  /// Avatar image URL or asset path
  final String avatar;

  /// Current score in the game
  final int score;

  /// Whether it's currently this player's turn
  final bool isCurrentTurn;

  /// Whether this is a human player or AI
  final bool isHuman;

  /// Whether this player is the host of the room
  final bool isHost;

  /// Whether this player is ready to start the game
  final bool isReady;

  /// AI difficulty level (only relevant for AI players)
  final AIDifficulty? aiDifficulty;

  /// Total number of games played by this player
  final int totalGamesPlayed;

  /// Total number of games won by this player
  final int totalGamesWon;

  /// List of achievements earned by this player
  final List<AchievementType> achievements;

  /// Number of consecutive dice rolls (for getting 6s)
  final int consecutiveRolls;

  /// Timestamp of the last move made by this player
  final DateTime? lastMoveTime;

  /// Creates a new human player
  factory Player.human({
    required String name,
    required PlayerColor color,
    required List<Position> homePositions,
    String avatar = '',
  }) {
    final tokens = homePositions
        .map((position) => Token.create(color: color, startPosition: position))
        .toList();

    return Player(
      id: const Uuid().v4(),
      name: name,
      color: color,
      tokens: tokens,
      avatar: avatar,
      isHuman: true,
    );
  }

  /// Creates a new AI player
  factory Player.ai({
    required PlayerColor color,
    required List<Position> homePositions,
    AIDifficulty difficulty = AIDifficulty.medium,
  }) {
    final tokens = homePositions
        .map((position) => Token.create(color: color, startPosition: position))
        .toList();

    return Player(
      id: const Uuid().v4(),
      name: '${color.displayName} AI',
      color: color,
      tokens: tokens,
      isHuman: false,
      aiDifficulty: difficulty,
    );
  }

  /// Creates a Player from JSON
  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);

  /// Converts Player to JSON
  Map<String, dynamic> toJson() => _$PlayerToJson(this);

  /// Creates a copy of this player with optional parameter overrides
  Player copyWith({
    String? id,
    String? name,
    PlayerColor? color,
    List<Token>? tokens,
    String? avatar,
    int? score,
    bool? isCurrentTurn,
    bool? isHuman,
    bool? isHost,
    bool? isReady,
    AIDifficulty? aiDifficulty,
    int? totalGamesPlayed,
    int? totalGamesWon,
    List<AchievementType>? achievements,
    int? consecutiveRolls,
    DateTime? lastMoveTime,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      tokens: tokens ?? this.tokens,
      avatar: avatar ?? this.avatar,
      score: score ?? this.score,
      isCurrentTurn: isCurrentTurn ?? this.isCurrentTurn,
      isHuman: isHuman ?? this.isHuman,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalGamesWon: totalGamesWon ?? this.totalGamesWon,
      achievements: achievements ?? this.achievements,
      consecutiveRolls: consecutiveRolls ?? this.consecutiveRolls,
      lastMoveTime: lastMoveTime ?? this.lastMoveTime,
    );
  }

  /// Update a specific token
  Player updateToken(String tokenId, Token updatedToken) {
    final updatedTokens = tokens.map((token) {
      return token.id == tokenId ? updatedToken : token;
    }).toList();

    return copyWith(tokens: updatedTokens);
  }

  /// Set turn status
  Player setTurn(bool isTurn) => copyWith(isCurrentTurn: isTurn);

  /// Add score points
  Player addScore(int points) => copyWith(score: score + points);

  /// Record a move
  Player recordMove() => copyWith(lastMoveTime: DateTime.now());

  /// Update consecutive rolls count
  Player updateConsecutiveRolls(int count) =>
      copyWith(consecutiveRolls: count);

  /// Add an achievement
  Player addAchievement(AchievementType achievement) {
    if (achievements.contains(achievement)) return this;
    final updatedAchievements = [...achievements, achievement];
    return copyWith(achievements: updatedAchievements);
  }

  /// Get tokens that are at home
  List<Token> get tokensAtHome =>
      tokens.where((token) => token.isAtHome).toList();

  /// Get tokens that are in play
  List<Token> get tokensInPlay =>
      tokens.where((token) => token.canMove).toList();

  /// Get tokens that have finished
  List<Token> get tokensFinished =>
      tokens.where((token) => token.hasFinished).toList();

  /// Check if all tokens have finished (player won)
  bool get hasWon => tokensFinished.length == tokens.length;

  /// Get number of tokens at home
  int get tokensAtHomeCount => tokensAtHome.length;

  /// Get token by ID
  Token? getTokenById(String tokenId) {
    try {
      return tokens.firstWhere((token) => token.id == tokenId);
    } catch (e) {
      return null;
    }
  }

  /// Get number of tokens in play
  int get tokensInPlayCount => tokensInPlay.length;

  /// Get number of finished tokens
  int get tokensFinishedCount => tokensFinished.length;

  /// Calculate win percentage
  double get winPercentage {
    if (totalGamesPlayed == 0) return 0.0;
    return (totalGamesWon / totalGamesPlayed) * 100;
  }

  /// Check if player can make any moves with given dice value
  bool canMakeMove(int diceValue, List<Position> boardPath) {
    for (final token in tokens) {
      if (_canTokenMove(token, diceValue, boardPath)) {
        return true;
      }
    }
    return false;
  }

  /// Check if a specific token can move
  bool _canTokenMove(Token token, int diceValue, List<Position> boardPath) {
    // Token at home can only move with a 6
    if (token.isAtHome) return diceValue == 6;

    // Finished tokens cannot move
    if (token.hasFinished) return false;

    // Check if there's a valid destination
    final currentIndex = token.currentPosition.pathIndex;
    if (currentIndex == null) return false;

    final newIndex = currentIndex + diceValue;
    return newIndex < boardPath.length;
  }

  /// Get valid moves for this player given a dice value
  List<Token> getValidMoves(int diceValue, List<Position> boardPath) {
    return tokens
        .where((token) => _canTokenMove(token, diceValue, boardPath))
        .toList();
  }

  @override
  List<Object?> get props => [
        id,
        name,
        color,
        tokens,
        avatar,
        score,
        isCurrentTurn,
        isHuman,
        aiDifficulty,
        totalGamesPlayed,
        totalGamesWon,
        achievements,
        consecutiveRolls,
        lastMoveTime,
      ];

  @override
  String toString() {
    return 'Player(id: $id, name: $name, color: $color, score: $score, tokens: ${tokens.length})';
  }
}

/// Extension for Player statistics and analysis
extension PlayerAnalytics on Player {
  /// Get player's current ranking based on finished tokens
  int getRanking(List<Player> allPlayers) {
    // Sort players by number of finished tokens (descending)
    final sortedPlayers = [...allPlayers]
      ..sort((a, b) => b.tokensFinishedCount.compareTo(a.tokensFinishedCount));

    return sortedPlayers.indexOf(this) + 1;
  }

  /// Calculate progress percentage (0-100)
  double get progressPercentage {
    final totalTokens = tokens.length;
    final finishedTokens = tokensFinishedCount;
    return (finishedTokens / totalTokens) * 100;
  }

  /// Get player's current status summary
  String get statusSummary {
    if (hasWon) return 'Winner!';
    if (tokensInPlayCount > 0) return 'In Progress';
    if (tokensAtHomeCount == tokens.length) return 'Not Started';
    return 'Playing';
  }

  /// Check if player is close to winning (3+ tokens finished)
  bool get isCloseToWinning => tokensFinishedCount >= 3;

  /// Get estimated completion time based on current progress
  Duration? getEstimatedCompletionTime() {
    if (lastMoveTime == null || tokensFinishedCount == 0) return null;

    final avgTimePerToken = DateTime.now().difference(lastMoveTime!);
    final remainingTokens = tokens.length - tokensFinishedCount;

    return avgTimePerToken * remainingTokens;
  }
}