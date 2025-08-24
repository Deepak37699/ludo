import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/data/models/game_state.dart';
import 'package:ludo_game/data/models/player.dart';
import 'package:ludo_game/data/models/token.dart';
import 'package:ludo_game/data/models/position.dart';
import 'package:ludo_game/core/enums/game_enums.dart';

void main() {
  group('GameState', () {
    late List<Player> players;
    late Position homePosition;

    setUp(() {
      homePosition = Position(
        x: 0,
        y: 0,
        type: PositionType.home,
        ownerColor: PlayerColor.red,
        pathIndex: null,
      );

      final tokens = List.generate(4, (index) => Token(
        id: 'token_$index',
        color: PlayerColor.red,
        currentPosition: homePosition,
        state: TokenState.home,
      ));

      players = [
        Player(
          id: 'player1',
          name: 'Player 1',
          color: PlayerColor.red,
          isHuman: true,
          tokens: tokens,
        ),
        Player(
          id: 'player2',
          name: 'Player 2',
          color: PlayerColor.blue,
          isHuman: false,
          tokens: tokens.map((t) => t.copyWith(color: PlayerColor.blue)).toList(),
        ),
      ];
    });

    group('constructor', () {
      test('creates game state with required parameters', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.waiting,
          gameMode: GameMode.vsAI,
        );

        expect(gameState.id, 'game1');
        expect(gameState.players, players);
        expect(gameState.currentPlayerIndex, 0);
        expect(gameState.gameStatus, GameStatus.waiting);
        expect(gameMode.vsAI, GameMode.vsAI);
        expect(gameState.diceValue, isNull);
        expect(gameState.winner, isNull);
        expect(gameState.turnCount, 0);
        expect(gameState.consecutiveSixes, 0);
        expect(gameState.chatMessages, isEmpty);
        expect(gameState.moveHistory, isEmpty);
        expect(gameState.isOnline, false);
        expect(gameState.roomCode, isNull);
      });

      test('creates game state with optional parameters', () {
        final startTime = DateTime.now();
        final gameState = GameState(
          id: 'game2',
          players: players,
          currentPlayerIndex: 1,
          diceValue: 6,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.online,
          winner: players[0],
          turnCount: 10,
          startTime: startTime,
          consecutiveSixes: 2,
          isOnline: true,
          roomCode: 'ABCD1234',
        );

        expect(gameState.diceValue, 6);
        expect(gameState.winner, players[0]);
        expect(gameState.turnCount, 10);
        expect(gameState.startTime, startTime);
        expect(gameState.consecutiveSixes, 2);
        expect(gameState.isOnline, true);
        expect(gameState.roomCode, 'ABCD1234');
      });
    });

    group('currentPlayer', () {
      test('returns player at current index', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 1,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
        );

        expect(gameState.currentPlayer, players[1]);
      });

      test('handles invalid index gracefully', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 5, // Invalid index
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
        );

        expect(gameState.currentPlayer, players[0]); // Should wrap around
      });
    });

    group('isFinished', () {
      test('returns true when game status is finished', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.finished,
          gameMode: GameMode.vsAI,
        );

        expect(gameState.isFinished, true);
      });

      test('returns false when game status is not finished', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
        );

        expect(gameState.isFinished, false);
      });
    });

    group('canRollDice', () {
      test('returns true when dice value is null and game is playing', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
          diceValue: null,
        );

        expect(gameState.canRollDice, true);
      });

      test('returns false when dice already rolled', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
          diceValue: 4,
        );

        expect(gameState.canRollDice, false);
      });

      test('returns false when game is not playing', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.waiting,
          gameMode: GameMode.vsAI,
          diceValue: null,
        );

        expect(gameState.canRollDice, false);
      });
    });

    group('copyWith', () {
      test('creates copy with updated values', () {
        final originalGameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.waiting,
          gameMode: GameMode.vsAI,
          turnCount: 5,
        );

        final copiedGameState = originalGameState.copyWith(
          currentPlayerIndex: 1,
          gameStatus: GameStatus.playing,
          diceValue: 6,
          turnCount: 6,
        );

        expect(copiedGameState.id, originalGameState.id);
        expect(copiedGameState.players, originalGameState.players);
        expect(copiedGameState.currentPlayerIndex, 1);
        expect(copiedGameState.gameStatus, GameStatus.playing);
        expect(copiedGameState.diceValue, 6);
        expect(copiedGameState.turnCount, 6);
      });

      test('creates copy with same values when no parameters provided', () {
        final originalGameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
          diceValue: 4,
          turnCount: 10,
        );

        final copiedGameState = originalGameState.copyWith();

        expect(copiedGameState.id, originalGameState.id);
        expect(copiedGameState.players, originalGameState.players);
        expect(copiedGameState.currentPlayerIndex, originalGameState.currentPlayerIndex);
        expect(copiedGameState.gameStatus, originalGameState.gameStatus);
        expect(copiedGameState.diceValue, originalGameState.diceValue);
        expect(copiedGameState.turnCount, originalGameState.turnCount);
      });
    });

    group('nextTurn', () {
      test('advances to next player and increments turn count', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
          turnCount: 5,
          diceValue: 4,
        );

        final nextGameState = gameState.nextTurn();

        expect(nextGameState.currentPlayerIndex, 1);
        expect(nextGameState.turnCount, 6);
        expect(nextGameState.diceValue, isNull);
        expect(nextGameState.consecutiveSixes, 0);
      });

      test('wraps around to first player when at end', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 1, // Last player
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
          turnCount: 5,
        );

        final nextGameState = gameState.nextTurn();

        expect(nextGameState.currentPlayerIndex, 0);
      });

      test('preserves consecutive sixes when rolling six', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
          diceValue: 6,
          consecutiveSixes: 1,
        );

        final nextGameState = gameState.nextTurn(rolledSix: true);

        expect(nextGameState.currentPlayerIndex, 0); // Same player
        expect(nextGameState.consecutiveSixes, 2);
      });
    });

    group('updatePlayer', () {
      test('updates specific player in players list', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
        );

        final updatedPlayer = players[1].copyWith(score: 100);
        final updatedGameState = gameState.updatePlayer(updatedPlayer);

        expect(updatedGameState.players[1].score, 100);
        expect(updatedGameState.players[0].score, 0);
      });

      test('returns same game state when player not found', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
        );

        final nonExistentPlayer = Player(
          id: 'nonexistent',
          name: 'Ghost Player',
          color: PlayerColor.green,
          isHuman: true,
          tokens: [],
        );

        final updatedGameState = gameState.updatePlayer(nonExistentPlayer);

        expect(updatedGameState.players, gameState.players);
      });
    });

    group('addChatMessage', () {
      test('adds new chat message', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.online,
        );

        final message = ChatMessage(
          id: 'msg1',
          playerId: 'player1',
          playerName: 'Player 1',
          message: 'Hello!',
          timestamp: DateTime.now(),
        );

        final updatedGameState = gameState.addChatMessage(message);

        expect(updatedGameState.chatMessages.length, 1);
        expect(updatedGameState.chatMessages.first, message);
      });

      test('limits chat messages to maximum count', () {
        final messages = List.generate(60, (index) => ChatMessage(
          id: 'msg$index',
          playerId: 'player1',
          playerName: 'Player 1',
          message: 'Message $index',
          timestamp: DateTime.now(),
        ));

        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.online,
          chatMessages: messages,
        );

        final newMessage = ChatMessage(
          id: 'msgNew',
          playerId: 'player1',
          playerName: 'Player 1',
          message: 'New message',
          timestamp: DateTime.now(),
        );

        final updatedGameState = gameState.addChatMessage(newMessage);

        expect(updatedGameState.chatMessages.length, 50); // Max limit
        expect(updatedGameState.chatMessages.last, newMessage);
      });
    });

    group('addGameMove', () {
      test('adds new game move to history', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
        );

        final move = GameMove(
          id: 'move1',
          playerId: 'player1',
          tokenId: 'token_0',
          fromPosition: homePosition,
          toPosition: homePosition,
          diceValue: 6,
          timestamp: DateTime.now(),
        );

        final updatedGameState = gameState.addGameMove(move);

        expect(updatedGameState.moveHistory.length, 1);
        expect(updatedGameState.moveHistory.first, move);
      });
    });

    group('equality', () {
      test('game states with same properties are equal', () {
        final gameState1 = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
        );

        final gameState2 = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
        );

        expect(gameState1, equals(gameState2));
        expect(gameState1.hashCode, equals(gameState2.hashCode));
      });

      test('game states with different properties are not equal', () {
        final gameState1 = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
        );

        final gameState2 = GameState(
          id: 'game2',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
        );

        expect(gameState1, isNot(equals(gameState2)));
      });
    });

    group('getPlayerById', () {
      test('returns player with matching ID', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
        );

        final foundPlayer = gameState.getPlayerById('player2');
        expect(foundPlayer, isNotNull);
        expect(foundPlayer?.id, 'player2');
      });

      test('returns null when player not found', () {
        final gameState = GameState(
          id: 'game1',
          players: players,
          currentPlayerIndex: 0,
          gameStatus: GameStatus.playing,
          gameMode: GameMode.vsAI,
        );

        final foundPlayer = gameState.getPlayerById('nonexistent');
        expect(foundPlayer, isNull);
      });
    });
  });
}