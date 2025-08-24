import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../core/enums/game_enums.dart';
import 'player.dart';
import 'position.dart';

part 'game_state.g.dart';

/// Represents the complete state of a Ludo game
@JsonSerializable()
class GameState extends Equatable {
  const GameState({
    required this.gameId,
    required this.players,
    required this.currentPlayerIndex,
    required this.status,
    required this.gameMode,
    this.lastDiceRoll = 0,
    this.consecutiveSixes = 0,
    this.turnTimeLimit = 30,
    this.lastMoveTime,
    this.gameStartTime,
    this.gameEndTime,
    this.winner,
    this.theme = GameTheme.classic,
    this.spectators = const [],
    this.chatMessages = const [],
    this.moveHistory = const [],
    this.settings = const {},
  });

  /// Unique identifier for the game
  final String gameId;

  /// List of players in the game (2-4 players)
  final List<Player> players;

  /// Index of the current player whose turn it is
  final int currentPlayerIndex;

  /// Current status of the game
  final GameStatus status;

  /// Game mode (single, local, online multiplayer)
  final GameMode gameMode;

  /// Last dice roll value
  final int lastDiceRoll;

  /// Number of consecutive sixes rolled by current player
  final int consecutiveSixes;

  /// Time limit for each turn in seconds
  final int turnTimeLimit;

  /// Timestamp of the last move
  final DateTime? lastMoveTime;

  /// Timestamp when the game started
  final DateTime? gameStartTime;

  /// Timestamp when the game ended
  final DateTime? gameEndTime;

  /// Winner of the game (if finished)
  final Player? winner;

  /// Current theme of the game
  final GameTheme theme;

  /// List of spectators (for online games)
  final List<String> spectators;

  /// Chat messages in the game
  final List<ChatMessage> chatMessages;

  /// History of all moves made in the game
  final List<GameMove> moveHistory;

  /// Additional game settings
  final Map<String, dynamic> settings;

  /// Creates a new game
  factory GameState.create({
    required List<Player> players,
    required GameMode gameMode,
    GameTheme theme = GameTheme.classic,
    int turnTimeLimit = 30,
    Map<String, dynamic> settings = const {},
  }) {
    return GameState(
      gameId: const Uuid().v4(),
      players: players,
      currentPlayerIndex: 0,
      status: GameStatus.waiting,
      gameMode: gameMode,
      theme: theme,
      turnTimeLimit: turnTimeLimit,
      settings: settings,
    );
  }

  /// Creates a GameState from JSON
  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);

  /// Converts GameState to JSON
  Map<String, dynamic> toJson() => _$GameStateToJson(this);

  /// Creates a copy of this game state with optional parameter overrides
  GameState copyWith({
    String? gameId,
    List<Player>? players,
    int? currentPlayerIndex,
    GameStatus? status,
    GameMode? gameMode,
    int? lastDiceRoll,
    int? consecutiveSixes,
    int? turnTimeLimit,
    DateTime? lastMoveTime,
    DateTime? gameStartTime,
    DateTime? gameEndTime,
    Player? winner,
    GameTheme? theme,
    List<String>? spectators,
    List<ChatMessage>? chatMessages,
    List<GameMove>? moveHistory,
    Map<String, dynamic>? settings,
  }) {
    return GameState(
      gameId: gameId ?? this.gameId,
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      status: status ?? this.status,
      gameMode: gameMode ?? this.gameMode,
      lastDiceRoll: lastDiceRoll ?? this.lastDiceRoll,
      consecutiveSixes: consecutiveSixes ?? this.consecutiveSixes,
      turnTimeLimit: turnTimeLimit ?? this.turnTimeLimit,
      lastMoveTime: lastMoveTime ?? this.lastMoveTime,
      gameStartTime: gameStartTime ?? this.gameStartTime,
      gameEndTime: gameEndTime ?? this.gameEndTime,
      winner: winner ?? this.winner,
      theme: theme ?? this.theme,
      spectators: spectators ?? this.spectators,
      chatMessages: chatMessages ?? this.chatMessages,
      moveHistory: moveHistory ?? this.moveHistory,
      settings: settings ?? this.settings,
    );
  }

  /// Get the current player
  Player get currentPlayer => players[currentPlayerIndex];

  /// Start the game
  GameState startGame() {
    final updatedPlayers = players.asMap().entries.map((entry) {
      return entry.value.setTurn(entry.key == 0);
    }).toList();

    return copyWith(
      players: updatedPlayers,
      status: GameStatus.playing,
      gameStartTime: DateTime.now(),
    );
  }

  /// Roll the dice
  GameState rollDice(int diceValue) {
    final newConsecutiveSixes = diceValue == 6 ? consecutiveSixes + 1 : 0;

    return copyWith(
      lastDiceRoll: diceValue,
      consecutiveSixes: newConsecutiveSixes,
      lastMoveTime: DateTime.now(),
    );
  }

  /// Move to next player's turn
  GameState nextTurn() {
    // If player rolled a 6 and hasn't reached max consecutive sixes, keep turn
    if (lastDiceRoll == 6 && consecutiveSixes < 3) {
      return this;
    }

    // Calculate next player index
    int nextIndex = (currentPlayerIndex + 1) % players.length;

    // Skip finished players
    while (players[nextIndex].hasWon && nextIndex != currentPlayerIndex) {
      nextIndex = (nextIndex + 1) % players.length;
    }

    // Update player turn status
    final updatedPlayers = players.asMap().entries.map((entry) {
      return entry.value.setTurn(entry.key == nextIndex);
    }).toList();

    return copyWith(
      players: updatedPlayers,
      currentPlayerIndex: nextIndex,
      consecutiveSixes: 0,
      lastMoveTime: DateTime.now(),
    );
  }

  /// Update a player in the game
  GameState updatePlayer(String playerId, Player updatedPlayer) {
    final updatedPlayers = players.map((player) {
      return player.id == playerId ? updatedPlayer : player;
    }).toList();

    return copyWith(players: updatedPlayers);
  }

  /// Add a move to the history
  GameState addMove(GameMove move) {
    final updatedHistory = [...moveHistory, move];
    return copyWith(moveHistory: updatedHistory);
  }

  /// Add a chat message
  GameState addChatMessage(ChatMessage message) {
    final updatedMessages = [...chatMessages, message];
    return copyWith(chatMessages: updatedMessages);
  }

  /// Check if game is finished
  GameState checkForWinner() {
    final winner = players.firstWhere(
      (player) => player.hasWon,
      orElse: () => players.first, // Return first player if no winner found
    );

    if (winner.hasWon) {
      return copyWith(
        status: GameStatus.finished,
        winner: winner,
        gameEndTime: DateTime.now(),
      );
    }

    return this;
  }

  /// Pause the game
  GameState pauseGame() => copyWith(status: GameStatus.paused);

  /// Resume the game
  GameState resumeGame() => copyWith(status: GameStatus.playing);

  /// Cancel the game
  GameState cancelGame() => copyWith(
        status: GameStatus.cancelled,
        gameEndTime: DateTime.now(),
      );

  /// Get game duration
  Duration? get gameDuration {
    if (gameStartTime == null) return null;
    final endTime = gameEndTime ?? DateTime.now();
    return endTime.difference(gameStartTime!);
  }

  /// Check if it's time to timeout the current turn
  bool get isTurnTimeout {
    if (lastMoveTime == null) return false;
    final elapsed = DateTime.now().difference(lastMoveTime!);
    return elapsed.inSeconds > turnTimeLimit;
  }

  /// Get remaining time for current turn
  Duration get remainingTurnTime {
    if (lastMoveTime == null) return Duration(seconds: turnTimeLimit);
    final elapsed = DateTime.now().difference(lastMoveTime!);
    final remaining = turnTimeLimit - elapsed.inSeconds;
    return Duration(seconds: remaining.clamp(0, turnTimeLimit));
  }

  /// Get players sorted by ranking
  List<Player> get playersByRanking {
    return [...players]
      ..sort((a, b) => b.tokensFinishedCount.compareTo(a.tokensFinishedCount));
  }

  /// Check if game can be started
  bool get canStart => players.length >= 2 && status == GameStatus.waiting;

  /// Check if current player can roll dice
  bool get canRollDice =>
      status == GameStatus.playing && !currentPlayer.hasWon;

  @override
  List<Object?> get props => [
        gameId,
        players,
        currentPlayerIndex,
        status,
        gameMode,
        lastDiceRoll,
        consecutiveSixes,
        turnTimeLimit,
        lastMoveTime,
        gameStartTime,
        gameEndTime,
        winner,
        theme,
        spectators,
        chatMessages,
        moveHistory,
        settings,
      ];

  @override
  String toString() {
    return 'GameState(id: $gameId, status: $status, currentPlayer: ${currentPlayer.name})';
  }
}

/// Represents a chat message in the game
@JsonSerializable()
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.message,
    required this.timestamp,
    this.isSystemMessage = false,
  });

  final String id;
  final String playerId;
  final String playerName;
  final String message;
  final DateTime timestamp;
  final bool isSystemMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  @override
  List<Object?> get props => [id, playerId, playerName, message, timestamp, isSystemMessage];
}

/// Represents a move made in the game
@JsonSerializable()
class GameMove extends Equatable {
  const GameMove({
    required this.id,
    required this.playerId,
    required this.tokenId,
    required this.fromPosition,
    required this.toPosition,
    required this.diceValue,
    required this.timestamp,
    this.capturedTokenId,
    this.moveType = MoveType.normal,
  });

  final String id;
  final String playerId;
  final String tokenId;
  final Position fromPosition;
  final Position toPosition;
  final int diceValue;
  final DateTime timestamp;
  final String? capturedTokenId;
  final MoveType moveType;

  factory GameMove.fromJson(Map<String, dynamic> json) =>
      _$GameMoveFromJson(json);

  Map<String, dynamic> toJson() => _$GameMoveToJson(this);

  @override
  List<Object?> get props => [
        id,
        playerId,
        tokenId,
        fromPosition,
        toPosition,
        diceValue,
        timestamp,
        capturedTokenId,
        moveType,
      ];
}

/// Types of moves that can be made
enum MoveType {
  normal,
  capture,
  homeEntry,
  finish,
}