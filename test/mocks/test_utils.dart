import 'package:mocktail/mocktail.dart';
import 'package:ludo_game/data/models/game_state.dart';
import 'package:ludo_game/data/models/player.dart';
import 'package:ludo_game/data/models/token.dart';
import 'package:ludo_game/data/models/position.dart';
import 'package:ludo_game/services/game/game_logic_service.dart';
import 'package:ludo_game/services/ai/ai_service.dart';
import 'package:ludo_game/services/auth/auth_service.dart';
import 'package:ludo_game/services/storage/offline_storage_service.dart';
import 'package:ludo_game/services/audio/audio_service.dart';
import 'package:ludo_game/core/enums/game_enums.dart';

// Mock Services
class MockGameLogicService extends Mock implements GameLogicService {}
class MockAIService extends Mock implements AIService {}
class MockAuthService extends Mock implements AuthService {}
class MockOfflineStorageService extends Mock implements OfflineStorageService {}
class MockAudioService extends Mock implements AudioService {}

// Mock Models
class MockGameState extends Mock implements GameState {}
class MockPlayer extends Mock implements Player {}
class MockToken extends Mock implements Token {}
class MockPosition extends Mock implements Position {}

/// Test data factory for creating consistent test objects
class TestDataFactory {
  /// Creates a basic home position for testing
  static Position createHomePosition({
    PlayerColor color = PlayerColor.red,
    int x = 1,
    int y = 1,
  }) {
    return Position(
      x: x,
      y: y,
      type: PositionType.home,
      ownerColor: color,
      pathIndex: null,
    );
  }

  /// Creates a start position for testing
  static Position createStartPosition({
    PlayerColor color = PlayerColor.red,
    int x = 6,
    int y = 1,
  }) {
    return Position(
      x: x,
      y: y,
      type: PositionType.start,
      ownerColor: color,
      pathIndex: 0,
    );
  }

  /// Creates a path position for testing
  static Position createPathPosition({
    int x = 7,
    int y = 1,
    int pathIndex = 1,
  }) {
    return Position(
      x: x,
      y: y,
      type: PositionType.path,
      ownerColor: null,
      pathIndex: pathIndex,
    );
  }

  /// Creates a finish position for testing
  static Position createFinishPosition({
    PlayerColor color = PlayerColor.red,
    int x = 7,
    int y = 7,
  }) {
    return Position(
      x: x,
      y: y,
      type: PositionType.finish,
      ownerColor: color,
      pathIndex: 51,
    );
  }

  /// Creates a safe position for testing
  static Position createSafePosition({
    int x = 2,
    int y = 8,
    int pathIndex = 8,
  }) {
    return Position(
      x: x,
      y: y,
      type: PositionType.safe,
      ownerColor: null,
      pathIndex: pathIndex,
    );
  }

  /// Creates a token for testing
  static Token createToken({
    String id = 'test_token',
    PlayerColor color = PlayerColor.red,
    Position? position,
    TokenState state = TokenState.home,
    bool isAnimating = false,
    List<Position>? moveHistory,
  }) {
    return Token(
      id: id,
      color: color,
      currentPosition: position ?? createHomePosition(color: color),
      state: state,
      isAnimating: isAnimating,
      moveHistory: moveHistory ?? [],
    );
  }

  /// Creates a list of tokens for a player
  static List<Token> createTokens({
    PlayerColor color = PlayerColor.red,
    int count = 4,
    TokenState state = TokenState.home,
    String idPrefix = 'token',
  }) {
    return List.generate(count, (index) => createToken(
      id: '${idPrefix}_$index',
      color: color,
      state: state,
      position: createHomePosition(color: color),
    ));
  }

  /// Creates a player for testing
  static Player createPlayer({
    String id = 'test_player',
    String name = 'Test Player',
    PlayerColor color = PlayerColor.red,
    bool isHuman = true,
    List<Token>? tokens,
    int score = 0,
    bool isOnline = false,
    AIDifficulty? aiDifficulty,
    String? profileImageUrl,
    List<String>? achievements,
  }) {
    return Player(
      id: id,
      name: name,
      color: color,
      isHuman: isHuman,
      tokens: tokens ?? createTokens(color: color),
      score: score,
      isOnline: isOnline,
      aiDifficulty: aiDifficulty,
      profileImageUrl: profileImageUrl,
      achievements: achievements ?? [],
    );
  }

  /// Creates multiple players for testing
  static List<Player> createPlayers({
    int count = 2,
    List<PlayerColor>? colors,
    List<bool>? isHumanList,
  }) {
    final playerColors = colors ?? [PlayerColor.red, PlayerColor.blue, PlayerColor.green, PlayerColor.yellow];
    final humanFlags = isHumanList ?? [true, false, false, false];

    return List.generate(count, (index) => createPlayer(
      id: 'player_$index',
      name: 'Player ${index + 1}',
      color: playerColors[index % playerColors.length],
      isHuman: humanFlags[index % humanFlags.length],
      tokens: createTokens(
        color: playerColors[index % playerColors.length],
        idPrefix: 'player_${index}_token',
      ),
    ));
  }

  /// Creates a game state for testing
  static GameState createGameState({
    String id = 'test_game',
    List<Player>? players,
    int currentPlayerIndex = 0,
    int? diceValue,
    GameStatus status = GameStatus.playing,
    GameMode mode = GameMode.vsAI,
    Player? winner,
    int turnCount = 0,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? lastDiceRoll,
    int consecutiveSixes = 0,
    bool isOnline = false,
    String? roomCode,
  }) {
    return GameState(
      id: id,
      players: players ?? createPlayers(),
      currentPlayerIndex: currentPlayerIndex,
      diceValue: diceValue,
      gameStatus: status,
      gameMode: mode,
      winner: winner,
      turnCount: turnCount,
      startTime: startTime,
      endTime: endTime,
      lastDiceRoll: lastDiceRoll,
      consecutiveSixes: consecutiveSixes,
      isOnline: isOnline,
      roomCode: roomCode,
    );
  }

  /// Creates a game state with tokens in various states for testing
  static GameState createAdvancedGameState() {
    // Create players with tokens in different states
    final redTokens = [
      createToken(id: 'red_1', color: PlayerColor.red, state: TokenState.home),
      createToken(id: 'red_2', color: PlayerColor.red, state: TokenState.active, 
                 position: createPathPosition(pathIndex: 10)),
      createToken(id: 'red_3', color: PlayerColor.red, state: TokenState.active,
                 position: createPathPosition(pathIndex: 25)),
      createToken(id: 'red_4', color: PlayerColor.red, state: TokenState.finished,
                 position: createFinishPosition()),
    ];

    final blueTokens = [
      createToken(id: 'blue_1', color: PlayerColor.blue, state: TokenState.home),
      createToken(id: 'blue_2', color: PlayerColor.blue, state: TokenState.home),
      createToken(id: 'blue_3', color: PlayerColor.blue, state: TokenState.active,
                 position: createPathPosition(pathIndex: 5)),
      createToken(id: 'blue_4', color: PlayerColor.blue, state: TokenState.active,
                 position: createPathPosition(pathIndex: 15)),
    ];

    final players = [
      createPlayer(
        id: 'human_player',
        name: 'Human Player',
        color: PlayerColor.red,
        isHuman: true,
        tokens: redTokens,
        score: 75,
      ),
      createPlayer(
        id: 'ai_player',
        name: 'AI Player',
        color: PlayerColor.blue,
        isHuman: false,
        tokens: blueTokens,
        score: 30,
        aiDifficulty: AIDifficulty.medium,
      ),
    ];

    return createGameState(
      id: 'advanced_game',
      players: players,
      currentPlayerIndex: 0,
      turnCount: 25,
      diceValue: 4,
      startTime: DateTime.now().subtract(const Duration(minutes: 15)),
    );
  }

  /// Creates a winning game state for testing
  static GameState createWinningGameState({
    int winnerIndex = 0,
  }) {
    final players = createPlayers();
    
    // Make all tokens of the winner finished
    final finishedTokens = players[winnerIndex].tokens.map((token) =>
      token.copyWith(state: TokenState.finished)
    ).toList();
    
    final winningPlayer = players[winnerIndex].copyWith(tokens: finishedTokens);
    players[winnerIndex] = winningPlayer;

    return createGameState(
      players: players,
      status: GameStatus.finished,
      winner: winningPlayer,
      turnCount: 50,
      endTime: DateTime.now(),
    );
  }

  /// Creates a chat message for testing
  static ChatMessage createChatMessage({
    String id = 'msg_1',
    String playerId = 'player_1',
    String playerName = 'Player 1',
    String message = 'Hello!',
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      playerId: playerId,
      playerName: playerName,
      message: message,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Creates a game move for testing
  static GameMove createGameMove({
    String id = 'move_1',
    String playerId = 'player_1',
    String tokenId = 'token_1',
    Position? fromPosition,
    Position? toPosition,
    int diceValue = 6,
    DateTime? timestamp,
    bool captured = false,
  }) {
    return GameMove(
      id: id,
      playerId: playerId,
      tokenId: tokenId,
      fromPosition: fromPosition ?? createHomePosition(),
      toPosition: toPosition ?? createStartPosition(),
      diceValue: diceValue,
      timestamp: timestamp ?? DateTime.now(),
      captured: captured,
    );
  }

  /// Creates user stats for testing
  static UserStats createUserStats({
    int gamesPlayed = 10,
    int gamesWon = 6,
    int tokensKilled = 15,
    int tokensFinished = 20,
    Duration? totalPlayTime,
    int winStreak = 3,
    int maxWinStreak = 5,
    DateTime? lastPlayed,
    Map<AIDifficulty, int>? aiWins,
  }) {
    return UserStats(
      gamesPlayed: gamesPlayed,
      gamesWon: gamesWon,
      tokensKilled: tokensKilled,
      tokensFinished: tokensFinished,
      totalPlayTime: totalPlayTime ?? const Duration(hours: 5, minutes: 30),
      winStreak: winStreak,
      maxWinStreak: maxWinStreak,
      lastPlayed: lastPlayed ?? DateTime.now(),
      aiWins: aiWins ?? {
        AIDifficulty.easy: 3,
        AIDifficulty.medium: 2,
        AIDifficulty.hard: 1,
      },
    );
  }

  /// Creates an achievement for testing
  static Achievement createAchievement({
    String id = 'first_win',
    String title = 'First Victory',
    String description = 'Win your first game',
    AchievementType type = AchievementType.gameplay,
    bool isUnlocked = false,
    DateTime? unlockedAt,
    int progress = 0,
    int target = 1,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      type: type,
      isUnlocked: isUnlocked,
      unlockedAt: unlockedAt,
      progress: progress,
      target: target,
    );
  }

  /// Creates game history for testing
  static GameHistory createGameHistory({
    String id = 'game_history_1',
    GameMode mode = GameMode.vsAI,
    List<String>? playerNames,
    String? winnerName,
    Duration? gameDuration,
    DateTime? completedAt,
    int totalMoves = 25,
    AIDifficulty? aiDifficulty,
  }) {
    return GameHistory(
      id: id,
      mode: mode,
      playerNames: playerNames ?? ['Player 1', 'AI Player'],
      winnerName: winnerName ?? 'Player 1',
      gameDuration: gameDuration ?? const Duration(minutes: 12, seconds: 30),
      completedAt: completedAt ?? DateTime.now(),
      totalMoves: totalMoves,
      aiDifficulty: aiDifficulty ?? AIDifficulty.medium,
    );
  }
}

/// Test utilities for common testing operations
class TestUtils {
  /// Registers all fallback values for mocktail
  static void registerFallbackValues() {
    registerFallbackValue(TestDataFactory.createToken());
    registerFallbackValue(TestDataFactory.createPlayer());
    registerFallbackValue(TestDataFactory.createGameState());
    registerFallbackValue(TestDataFactory.createHomePosition());
    registerFallbackValue(PlayerColor.red);
    registerFallbackValue(TokenState.home);
    registerFallbackValue(GameStatus.playing);
    registerFallbackValue(GameMode.vsAI);
    registerFallbackValue(AIDifficulty.medium);
  }

  /// Sets up mock game logic service with default behaviors
  static void setupMockGameLogicService(MockGameLogicService mock) {
    when(() => mock.canMoveToken(
      token: any(named: 'token'),
      diceValue: any(named: 'diceValue'),
      gameState: any(named: 'gameState'),
    )).thenReturn(true);

    when(() => mock.getValidMoves(
      player: any(named: 'player'),
      diceValue: any(named: 'diceValue'),
      gameState: any(named: 'gameState'),
    )).thenReturn({});

    when(() => mock.validateGameRules(any())).thenReturn(true);

    when(() => mock.checkGameWinner(any())).thenReturn(null);
  }

  /// Sets up mock AI service with default behaviors
  static void setupMockAIService(MockAIService mock) {
    when(() => mock.calculateBestMove(
      aiPlayer: any(named: 'aiPlayer'),
      diceValue: any(named: 'diceValue'),
      gameState: any(named: 'gameState'),
      difficulty: any(named: 'difficulty'),
    )).thenReturn(null);

    when(() => mock.calculateMoveDelay(any()))
        .thenReturn(const Duration(milliseconds: 1000));
  }

  /// Sets up mock auth service with default behaviors
  static void setupMockAuthService(MockAuthService mock) {
    when(() => mock.isLoggedIn).thenReturn(true);
    when(() => mock.currentUser).thenReturn(null);
    when(() => mock.signInAnonymously()).thenAnswer((_) async => true);
    when(() => mock.signOut()).thenAnswer((_) async {});
  }

  /// Sets up mock audio service with default behaviors
  static void setupMockAudioService(MockAudioService mock) {
    when(() => mock.playSound(any())).thenAnswer((_) async {});
    when(() => mock.playBackgroundMusic(any())).thenAnswer((_) async {});
    when(() => mock.stopBackgroundMusic()).thenAnswer((_) async {});
    when(() => mock.setVolume(any())).thenAnswer((_) async {});
  }

  /// Creates a delay for testing animations
  static Future<void> pump(Duration duration) async {
    await Future.delayed(duration);
  }

  /// Verifies that a mock was called with specific parameters
  static void verifyMockCall<T>(
    MockGameLogicService mock,
    String method, {
    dynamic token,
    dynamic diceValue,
    dynamic gameState,
    dynamic player,
  }) {
    switch (method) {
      case 'canMoveToken':
        verify(() => mock.canMoveToken(
          token: token ?? any(named: 'token'),
          diceValue: diceValue ?? any(named: 'diceValue'),
          gameState: gameState ?? any(named: 'gameState'),
        )).called(1);
        break;
      case 'getValidMoves':
        verify(() => mock.getValidMoves(
          player: player ?? any(named: 'player'),
          diceValue: diceValue ?? any(named: 'diceValue'),
          gameState: gameState ?? any(named: 'gameState'),
        )).called(1);
        break;
    }
  }
}