import 'package:hive/hive.dart';
import '../../data/models/game_state.dart';
import '../../data/models/player.dart';
import '../../data/models/token.dart';
import '../../data/models/position.dart';
import '../../core/enums/game_enums.dart';
import '../storage/offline_storage_service.dart';

// Enum Adapters

/// PlayerColor enum adapter
class PlayerColorAdapter extends TypeAdapter<PlayerColor> {
  @override
  final int typeId = 0;

  @override
  PlayerColor read(BinaryReader reader) {
    final index = reader.readByte();
    return PlayerColor.values[index];
  }

  @override
  void write(BinaryWriter writer, PlayerColor obj) {
    writer.writeByte(obj.index);
  }
}

/// TokenState enum adapter
class TokenStateAdapter extends TypeAdapter<TokenState> {
  @override
  final int typeId = 1;

  @override
  TokenState read(BinaryReader reader) {
    final index = reader.readByte();
    return TokenState.values[index];
  }

  @override
  void write(BinaryWriter writer, TokenState obj) {
    writer.writeByte(obj.index);
  }
}

/// GameStatus enum adapter
class GameStatusAdapter extends TypeAdapter<GameStatus> {
  @override
  final int typeId = 2;

  @override
  GameStatus read(BinaryReader reader) {
    final index = reader.readByte();
    return GameStatus.values[index];
  }

  @override
  void write(BinaryWriter writer, GameStatus obj) {
    writer.writeByte(obj.index);
  }
}

/// GameMode enum adapter
class GameModeAdapter extends TypeAdapter<GameMode> {
  @override
  final int typeId = 3;

  @override
  GameMode read(BinaryReader reader) {
    final index = reader.readByte();
    return GameMode.values[index];
  }

  @override
  void write(BinaryWriter writer, GameMode obj) {
    writer.writeByte(obj.index);
  }
}

/// PositionType enum adapter
class PositionTypeAdapter extends TypeAdapter<PositionType> {
  @override
  final int typeId = 4;

  @override
  PositionType read(BinaryReader reader) {
    final index = reader.readByte();
    return PositionType.values[index];
  }

  @override
  void write(BinaryWriter writer, PositionType obj) {
    writer.writeByte(obj.index);
  }
}

/// AIDifficulty enum adapter
class AIDifficultyAdapter extends TypeAdapter<AIDifficulty> {
  @override
  final int typeId = 5;

  @override
  AIDifficulty read(BinaryReader reader) {
    final index = reader.readByte();
    return AIDifficulty.values[index];
  }

  @override
  void write(BinaryWriter writer, AIDifficulty obj) {
    writer.writeByte(obj.index);
  }
}

/// AchievementType enum adapter
class AchievementTypeAdapter extends TypeAdapter<AchievementType> {
  @override
  final int typeId = 6;

  @override
  AchievementType read(BinaryReader reader) {
    final index = reader.readByte();
    return AchievementType.values[index];
  }

  @override
  void write(BinaryWriter writer, AchievementType obj) {
    writer.writeByte(obj.index);
  }
}

// Model Adapters

/// Position model adapter
class PositionAdapter extends TypeAdapter<Position> {
  @override
  final int typeId = 7;

  @override
  Position read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Position(
      x: fields[0],
      y: fields[1],
      type: fields[2],
      ownerColor: fields[3],
      pathIndex: fields[4],
    );
  }

  @override
  void write(BinaryWriter writer, Position obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.x)
      ..writeByte(1)
      ..write(obj.y)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.ownerColor)
      ..writeByte(4)
      ..write(obj.pathIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Token model adapter
class TokenAdapter extends TypeAdapter<Token> {
  @override
  final int typeId = 8;

  @override
  Token read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Token(
      id: fields[0],
      color: fields[1],
      currentPosition: fields[2],
      state: fields[3],
      isAnimating: fields[4] ?? false,
      moveHistory: (fields[5] as List?)?.cast<Position>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, Token obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.color)
      ..writeByte(2)
      ..write(obj.currentPosition)
      ..writeByte(3)
      ..write(obj.state)
      ..writeByte(4)
      ..write(obj.isAnimating)
      ..writeByte(5)
      ..write(obj.moveHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Player model adapter
class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 9;

  @override
  Player read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Player(
      id: fields[0],
      name: fields[1],
      color: fields[2],
      isHuman: fields[3],
      tokens: (fields[4] as List).cast<Token>(),
      score: fields[5] ?? 0,
      isOnline: fields[6] ?? false,
      aiDifficulty: fields[7],
      profileImageUrl: fields[8],
      achievements: (fields[9] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.color)
      ..writeByte(3)
      ..write(obj.isHuman)
      ..writeByte(4)
      ..write(obj.tokens)
      ..writeByte(5)
      ..write(obj.score)
      ..writeByte(6)
      ..write(obj.isOnline)
      ..writeByte(7)
      ..write(obj.aiDifficulty)
      ..writeByte(8)
      ..write(obj.profileImageUrl)
      ..writeByte(9)
      ..write(obj.achievements);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// GameState model adapter
class GameStateAdapter extends TypeAdapter<GameState> {
  @override
  final int typeId = 13;

  @override
  GameState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameState(
      id: fields[0],
      players: (fields[1] as List).cast<Player>(),
      currentPlayerIndex: fields[2],
      diceValue: fields[3],
      gameStatus: fields[4],
      gameMode: fields[5],
      winner: fields[6],
      turnCount: fields[7] ?? 0,
      startTime: fields[8],
      endTime: fields[9],
      lastDiceRoll: fields[10],
      consecutiveSixes: fields[11] ?? 0,
      chatMessages: (fields[12] as List?)?.cast<ChatMessage>() ?? [],
      moveHistory: (fields[13] as List?)?.cast<GameMove>() ?? [],
      isOnline: fields[14] ?? false,
      roomCode: fields[15],
    );
  }

  @override
  void write(BinaryWriter writer, GameState obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.players)
      ..writeByte(2)
      ..write(obj.currentPlayerIndex)
      ..writeByte(3)
      ..write(obj.diceValue)
      ..writeByte(4)
      ..write(obj.gameStatus)
      ..writeByte(5)
      ..write(obj.gameMode)
      ..writeByte(6)
      ..write(obj.winner)
      ..writeByte(7)
      ..write(obj.turnCount)
      ..writeByte(8)
      ..write(obj.startTime)
      ..writeByte(9)
      ..write(obj.endTime)
      ..writeByte(10)
      ..write(obj.lastDiceRoll)
      ..writeByte(11)
      ..write(obj.consecutiveSixes)
      ..writeByte(12)
      ..write(obj.chatMessages)
      ..writeByte(13)
      ..write(obj.moveHistory)
      ..writeByte(14)
      ..write(obj.isOnline)
      ..writeByte(15)
      ..write(obj.roomCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// UserStats model adapter
class UserStatsAdapter extends TypeAdapter<UserStats> {
  @override
  final int typeId = 10;

  @override
  UserStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserStats(
      gamesPlayed: fields[0] ?? 0,
      gamesWon: fields[1] ?? 0,
      tokensKilled: fields[2] ?? 0,
      tokensFinished: fields[3] ?? 0,
      totalPlayTime: Duration(microseconds: fields[4] ?? 0),
      winStreak: fields[5] ?? 0,
      maxWinStreak: fields[6] ?? 0,
      lastPlayed: fields[7] ?? DateTime.now(),
      aiWins: (fields[8] as Map?)?.cast<AIDifficulty, int>() ?? {},
    );
  }

  @override
  void write(BinaryWriter writer, UserStats obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.gamesPlayed)
      ..writeByte(1)
      ..write(obj.gamesWon)
      ..writeByte(2)
      ..write(obj.tokensKilled)
      ..writeByte(3)
      ..write(obj.tokensFinished)
      ..writeByte(4)
      ..write(obj.totalPlayTime.inMicroseconds)
      ..writeByte(5)
      ..write(obj.winStreak)
      ..writeByte(6)
      ..write(obj.maxWinStreak)
      ..writeByte(7)
      ..write(obj.lastPlayed)
      ..writeByte(8)
      ..write(obj.aiWins);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Achievement model adapter
class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 11;

  @override
  Achievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Achievement(
      id: fields[0],
      title: fields[1],
      description: fields[2],
      type: fields[3],
      isUnlocked: fields[4] ?? false,
      unlockedAt: fields[5],
      progress: fields[6] ?? 0,
      target: fields[7],
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.isUnlocked)
      ..writeByte(5)
      ..write(obj.unlockedAt)
      ..writeByte(6)
      ..write(obj.progress)
      ..writeByte(7)
      ..write(obj.target);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// GameHistory model adapter
class GameHistoryAdapter extends TypeAdapter<GameHistory> {
  @override
  final int typeId = 12;

  @override
  GameHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameHistory(
      id: fields[0],
      mode: fields[1],
      playerNames: (fields[2] as List).cast<String>(),
      winnerName: fields[3],
      gameDuration: Duration(microseconds: fields[4]),
      completedAt: fields[5],
      totalMoves: fields[6] ?? 0,
      aiDifficulty: fields[7],
    );
  }

  @override
  void write(BinaryWriter writer, GameHistory obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mode)
      ..writeByte(2)
      ..write(obj.playerNames)
      ..writeByte(3)
      ..write(obj.winnerName)
      ..writeByte(4)
      ..write(obj.gameDuration.inMicroseconds)
      ..writeByte(5)
      ..write(obj.completedAt)
      ..writeByte(6)
      ..write(obj.totalMoves)
      ..writeByte(7)
      ..write(obj.aiDifficulty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}