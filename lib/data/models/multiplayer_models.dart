import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'game_state.dart';
import 'player.dart';
import 'position.dart';
import '../../core/enums/game_enums.dart';

part 'multiplayer_models.g.dart';

/// Connection states for multiplayer
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Room status for multiplayer games
enum RoomStatus {
  waiting,
  inGame,
  finished,
}

/// Multiplayer event types
enum MultiplayerEventType {
  roomJoined,
  roomLeft,
  playerJoined,
  playerLeft,
  roomFull,
  gameStarted,
  gameStateUpdated,
  moveMade,
  diceRolled,
  turnChanged,
  gameEnded,
  playerReady,
  chatMessage,
  error,
  invalidMove,
}

/// Game room model for multiplayer sessions
@JsonSerializable()
class GameRoom extends Equatable {
  const GameRoom({
    required this.id,
    required this.name,
    required this.hostId,
    required this.hostName,
    required this.gameMode,
    required this.maxPlayers,
    required this.players,
    required this.status,
    required this.createdAt,
    this.isPrivate = false,
    this.password,
    this.gameState,
  });

  /// Unique room identifier
  final String id;

  /// Room display name
  final String name;

  /// Host player ID
  final String hostId;

  /// Host player name
  final String hostName;

  /// Game mode for this room
  final GameMode gameMode;

  /// Maximum number of players allowed
  final int maxPlayers;

  /// Current players in the room
  final List<Player> players;

  /// Current room status
  final RoomStatus status;

  /// Whether the room is private
  final bool isPrivate;

  /// Room password (if private)
  final String? password;

  /// Current game state (if game is active)
  final GameState? gameState;

  /// Room creation time
  final DateTime createdAt;

  /// Create from JSON
  factory GameRoom.fromJson(Map<String, dynamic> json) => _$GameRoomFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$GameRoomToJson(this);

  /// Create a copy with modifications
  GameRoom copyWith({
    String? id,
    String? name,
    String? hostId,
    String? hostName,
    GameMode? gameMode,
    int? maxPlayers,
    List<Player>? players,
    RoomStatus? status,
    bool? isPrivate,
    String? password,
    GameState? gameState,
    DateTime? createdAt,
  }) {
    return GameRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      gameMode: gameMode ?? this.gameMode,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      players: players ?? this.players,
      status: status ?? this.status,
      isPrivate: isPrivate ?? this.isPrivate,
      password: password ?? this.password,
      gameState: gameState ?? this.gameState,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if room is full
  bool get isFull => players.length >= maxPlayers;

  /// Check if room can be joined
  bool get canJoin => !isFull && status == RoomStatus.waiting;

  /// Check if current user is host
  bool get isHost => false; // This should be implemented based on current user

  @override
  List<Object?> get props => [
        id,
        name,
        hostId,
        hostName,
        gameMode,
        maxPlayers,
        players,
        status,
        isPrivate,
        password,
        gameState,
        createdAt,
      ];
}

/// Multiplayer event model
@JsonSerializable()
class MultiplayerEvent extends Equatable {
  const MultiplayerEvent({
    required this.type,
    required this.data,
    this.timestamp,
  });

  /// Event type
  final MultiplayerEventType type;

  /// Event data
  final dynamic data;

  /// Event timestamp
  final DateTime? timestamp;

  /// Create from JSON
  factory MultiplayerEvent.fromJson(Map<String, dynamic> json) => _$MultiplayerEventFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$MultiplayerEventToJson(this);

  @override
  List<Object?> get props => [type, data, timestamp];
}

/// Game move model for multiplayer
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
  });

  /// Move identifier
  final String id;

  /// Player who made the move
  final String playerId;

  /// Token that was moved
  final String tokenId;

  /// Starting position
  final Position fromPosition;

  /// Ending position
  final Position toPosition;

  /// Dice value used for the move
  final int diceValue;

  /// Token that was captured (if any)
  final String? capturedTokenId;

  /// Move timestamp
  final DateTime timestamp;

  /// Create from JSON
  factory GameMove.fromJson(Map<String, dynamic> json) => _$GameMoveFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$GameMoveToJson(this);

  @override
  List<Object?> get props => [
        id,
        playerId,
        tokenId,
        fromPosition,
        toPosition,
        diceValue,
        capturedTokenId,
        timestamp,
      ];
}

/// Dice result model for multiplayer
@JsonSerializable()
class DiceResult extends Equatable {
  const DiceResult({
    required this.playerId,
    required this.value,
    required this.timestamp,
  });

  /// Player who rolled the dice
  final String playerId;

  /// Dice value (1-6)
  final int value;

  /// Roll timestamp
  final DateTime timestamp;

  /// Create from JSON
  factory DiceResult.fromJson(Map<String, dynamic> json) => _$DiceResultFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$DiceResultToJson(this);

  @override
  List<Object?> get props => [playerId, value, timestamp];
}

/// Game result model for multiplayer
@JsonSerializable()
class GameResult extends Equatable {
  const GameResult({
    required this.gameId,
    required this.winnerId,
    required this.winnerName,
    required this.players,
    required this.duration,
    required this.endTime,
  });

  /// Game identifier
  final String gameId;

  /// Winner player ID
  final String winnerId;

  /// Winner player name
  final String winnerName;

  /// All players and their final scores
  final List<Player> players;

  /// Game duration
  final Duration duration;

  /// Game end time
  final DateTime endTime;

  /// Create from JSON
  factory GameResult.fromJson(Map<String, dynamic> json) => _$GameResultFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$GameResultToJson(this);

  @override
  List<Object?> get props => [
        gameId,
        winnerId,
        winnerName,
        players,
        duration,
        endTime,
      ];
}

/// Chat message model for multiplayer
@JsonSerializable()
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.message,
    required this.timestamp,
    this.type = ChatMessageType.text,
  });

  /// Message identifier
  final String id;

  /// Player who sent the message
  final String playerId;

  /// Player name
  final String playerName;

  /// Message content
  final String message;

  /// Message type
  final ChatMessageType type;

  /// Message timestamp
  final DateTime timestamp;

  /// Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  @override
  List<Object?> get props => [
        id,
        playerId,
        playerName,
        message,
        type,
        timestamp,
      ];
}

/// Chat message types
enum ChatMessageType {
  text,
  system,
  emote,
}

/// Multiplayer exception
class MultiplayerException implements Exception {
  const MultiplayerException(this.message, this.code);

  final String message;
  final String code;

  @override
  String toString() => 'MultiplayerException: $message (Code: $code)';
}