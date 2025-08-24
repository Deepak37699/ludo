/// Enums for the Ludo game
library;

/// Represents the four player colors in Ludo
enum PlayerColor {
  red('Red', 0xFFE53E3E),
  blue('Blue', 0xFF3182CE),
  green('Green', 0xFF38A169),
  yellow('Yellow', 0xFFD69E2E);

  const PlayerColor(this.displayName, this.colorValue);

  final String displayName;
  final int colorValue;
}

/// Represents the current state of a token
enum TokenState {
  home('Home'),
  active('Active'),
  safe('Safe'),
  finished('Finished');

  const TokenState(this.displayName);

  final String displayName;
}

/// Represents the current status of the game
enum GameStatus {
  waiting('Waiting for players'),
  playing('Game in progress'),
  paused('Game paused'),
  finished('Game finished'),
  cancelled('Game cancelled');

  const GameStatus(this.displayName);

  final String displayName;
}

/// Represents different game modes
enum GameMode {
  singlePlayer('Single Player'),
  vsAI('Vs AI'),
  local('Local Multiplayer'),
  localMultiplayer('Local Multiplayer'),
  online('Online'),
  onlineMultiplayer('Online Multiplayer'),
  quickPlay('Quick Play');

  const GameMode(this.displayName);

  final String displayName;
}

/// Represents different types of positions on the board
enum PositionType {
  regular('Regular'),
  path('Path'),
  safe('Safe'),
  home('Home'),
  homeEntrance('Home Entrance'),
  finish('Finish'),
  start('Start');

  const PositionType(this.displayName);

  final String displayName;
}

/// Represents the difficulty level for AI players
enum AIDifficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard'),
  expert('Expert');

  const AIDifficulty(this.displayName);

  final String displayName;
}

/// Represents different types of achievements
enum AchievementType {
  firstWin('First Win'),
  winStreak('Win Streak'),
  totalWins('Total Wins'),
  perfectGame('Perfect Game'),
  quickWin('Quick Win'),
  comeback('Comeback'),
  defender('Defender'),
  hunter('Hunter');

  const AchievementType(this.displayName);

  final String displayName;
}

/// Represents different sound effects in the game
enum SoundEffect {
  diceRoll('dice_roll'),
  tokenMove('token_move'),
  tokenCapture('token_capture'),
  tokenSafe('token_safe'),
  tokenFinish('token_finish'),
  gameWin('game_win'),
  gameLose('game_lose'),
  buttonClick('button_click'),
  notification('notification');

  const SoundEffect(this.fileName);

  final String fileName;
}

/// Represents different themes available in the game
enum GameTheme {
  classic('Classic'),
  royal('Royal'),
  modern('Modern'),
  nature('Nature'),
  space('Space'),
  ocean('Ocean');

  const GameTheme(this.displayName);

  final String displayName;
}