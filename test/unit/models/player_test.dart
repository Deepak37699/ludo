import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/data/models/player.dart';
import 'package:ludo_game/data/models/token.dart';
import 'package:ludo_game/data/models/position.dart';
import 'package:ludo_game/core/enums/game_enums.dart';

void main() {
  group('Player', () {
    late List<Token> tokens;
    late Position homePosition;

    setUp(() {
      homePosition = Position(
        x: 0,
        y: 0,
        type: PositionType.home,
        ownerColor: PlayerColor.red,
        pathIndex: null,
      );

      tokens = List.generate(4, (index) => Token(
        id: 'token_$index',
        color: PlayerColor.red,
        currentPosition: homePosition,
        state: TokenState.home,
      ));
    });

    group('constructor', () {
      test('creates player with required parameters', () {
        final player = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: tokens,
        );

        expect(player.id, 'player1');
        expect(player.name, 'Test Player');
        expect(player.color, PlayerColor.red);
        expect(player.isHuman, true);
        expect(player.tokens, tokens);
        expect(player.score, 0);
        expect(player.isOnline, false);
        expect(player.aiDifficulty, null);
        expect(player.profileImageUrl, null);
        expect(player.achievements, isEmpty);
      });

      test('creates player with optional parameters', () {
        final player = Player(
          id: 'player2',
          name: 'AI Player',
          color: PlayerColor.blue,
          isHuman: false,
          tokens: tokens,
          score: 100,
          isOnline: true,
          aiDifficulty: AIDifficulty.hard,
          profileImageUrl: 'https://example.com/avatar.jpg',
          achievements: ['first_win', 'speed_demon'],
        );

        expect(player.score, 100);
        expect(player.isOnline, true);
        expect(player.aiDifficulty, AIDifficulty.hard);
        expect(player.profileImageUrl, 'https://example.com/avatar.jpg');
        expect(player.achievements, ['first_win', 'speed_demon']);
      });
    });

    group('activeTokens', () {
      test('returns tokens in active state', () {
        final activeTokens = [
          tokens[0].copyWith(state: TokenState.active),
          tokens[1].copyWith(state: TokenState.active),
        ];
        
        final playerTokens = [
          ...activeTokens,
          tokens[2].copyWith(state: TokenState.home),
          tokens[3].copyWith(state: TokenState.finished),
        ];

        final player = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: playerTokens,
        );

        expect(player.activeTokens.length, 2);
        expect(player.activeTokens, containsAll(activeTokens));
      });

      test('returns empty list when no active tokens', () {
        final player = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: tokens, // All in home state
        );

        expect(player.activeTokens, isEmpty);
      });
    });

    group('homeTokens', () {
      test('returns tokens in home state', () {
        final homeTokens = [tokens[0], tokens[1]];
        
        final playerTokens = [
          ...homeTokens,
          tokens[2].copyWith(state: TokenState.active),
          tokens[3].copyWith(state: TokenState.finished),
        ];

        final player = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: playerTokens,
        );

        expect(player.homeTokens.length, 2);
        expect(player.homeTokens, containsAll(homeTokens));
      });
    });

    group('finishedTokens', () {
      test('returns tokens in finished state', () {
        final finishedTokens = [
          tokens[0].copyWith(state: TokenState.finished),
          tokens[1].copyWith(state: TokenState.finished),
        ];
        
        final playerTokens = [
          ...finishedTokens,
          tokens[2].copyWith(state: TokenState.active),
          tokens[3].copyWith(state: TokenState.home),
        ];

        final player = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: playerTokens,
        );

        expect(player.finishedTokens.length, 2);
        expect(player.finishedTokens, containsAll(finishedTokens));
      });
    });

    group('hasWon', () {
      test('returns true when all tokens are finished', () {
        final finishedTokens = tokens.map((token) => 
          token.copyWith(state: TokenState.finished)
        ).toList();

        final player = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: finishedTokens,
        );

        expect(player.hasWon, true);
      });

      test('returns false when not all tokens are finished', () {
        final mixedTokens = [
          tokens[0].copyWith(state: TokenState.finished),
          tokens[1].copyWith(state: TokenState.finished),
          tokens[2].copyWith(state: TokenState.active),
          tokens[3].copyWith(state: TokenState.home),
        ];

        final player = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: mixedTokens,
        );

        expect(player.hasWon, false);
      });
    });

    group('canPlay', () {
      test('returns true when player has movable tokens', () {
        final activeToken = tokens[0].copyWith(
          state: TokenState.active,
          isAnimating: false,
        );
        
        final playerTokens = [
          activeToken,
          ...tokens.skip(1),
        ];

        final player = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: playerTokens,
        );

        expect(player.canPlay, true);
      });

      test('returns false when no movable tokens', () {
        final animatingTokens = tokens.map((token) => 
          token.copyWith(isAnimating: true)
        ).toList();

        final player = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: animatingTokens,
        );

        expect(player.canPlay, false);
      });
    });

    group('getTokenById', () {
      test('returns token with matching ID', () {
        final player = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: tokens,
        );

        final foundToken = player.getTokenById('token_2');
        expect(foundToken, isNotNull);
        expect(foundToken?.id, 'token_2');
      });

      test('returns null when token not found', () {
        final player = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: tokens,
        );

        final foundToken = player.getTokenById('nonexistent');
        expect(foundToken, isNull);
      });
    });

    group('copyWith', () {
      test('creates copy with updated values', () {
        final originalPlayer = Player(
          id: 'player1',
          name: 'Original Name',
          color: PlayerColor.red,
          isHuman: true,
          tokens: tokens,
          score: 50,
        );

        final copiedPlayer = originalPlayer.copyWith(
          name: 'Updated Name',
          score: 100,
          isOnline: true,
        );

        expect(copiedPlayer.id, originalPlayer.id);
        expect(copiedPlayer.name, 'Updated Name');
        expect(copiedPlayer.color, originalPlayer.color);
        expect(copiedPlayer.isHuman, originalPlayer.isHuman);
        expect(copiedPlayer.tokens, originalPlayer.tokens);
        expect(copiedPlayer.score, 100);
        expect(copiedPlayer.isOnline, true);
      });

      test('creates copy with same values when no parameters provided', () {
        final originalPlayer = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: tokens,
          score: 75,
          achievements: ['test_achievement'],
        );

        final copiedPlayer = originalPlayer.copyWith();

        expect(copiedPlayer.id, originalPlayer.id);
        expect(copiedPlayer.name, originalPlayer.name);
        expect(copiedPlayer.color, originalPlayer.color);
        expect(copiedPlayer.isHuman, originalPlayer.isHuman);
        expect(copiedPlayer.tokens, originalPlayer.tokens);
        expect(copiedPlayer.score, originalPlayer.score);
        expect(copiedPlayer.achievements, originalPlayer.achievements);
      });
    });

    group('updateToken', () {
      test('updates specific token in player tokens list', () {
        final player = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: tokens,
        );

        final updatedToken = tokens[1].copyWith(state: TokenState.active);
        final updatedPlayer = player.updateToken(updatedToken);

        expect(updatedPlayer.tokens[1].state, TokenState.active);
        expect(updatedPlayer.tokens[0].state, TokenState.home);
        expect(updatedPlayer.tokens[2].state, TokenState.home);
        expect(updatedPlayer.tokens[3].state, TokenState.home);
      });

      test('returns same player when token not found', () {
        final player = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: tokens,
        );

        final nonExistentToken = Token(
          id: 'nonexistent',
          color: PlayerColor.red,
          currentPosition: homePosition,
          state: TokenState.active,
        );

        final updatedPlayer = player.updateToken(nonExistentToken);

        expect(updatedPlayer.tokens, player.tokens);
      });
    });

    group('addAchievement', () {
      test('adds new achievement to player', () {
        final player = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: tokens,
          achievements: ['existing_achievement'],
        );

        final updatedPlayer = player.addAchievement('new_achievement');

        expect(updatedPlayer.achievements, 
               contains('new_achievement'));
        expect(updatedPlayer.achievements, 
               contains('existing_achievement'));
        expect(updatedPlayer.achievements.length, 2);
      });

      test('does not add duplicate achievement', () {
        final player = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: tokens,
          achievements: ['existing_achievement'],
        );

        final updatedPlayer = player.addAchievement('existing_achievement');

        expect(updatedPlayer.achievements.length, 1);
        expect(updatedPlayer.achievements, contains('existing_achievement'));
      });
    });

    group('equality', () {
      test('players with same properties are equal', () {
        final player1 = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: tokens,
        );

        final player2 = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: tokens,
        );

        expect(player1, equals(player2));
        expect(player1.hashCode, equals(player2.hashCode));
      });

      test('players with different properties are not equal', () {
        final player1 = Player(
          id: 'player1',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: tokens,
        );

        final player2 = Player(
          id: 'player2',
          name: 'Test Player',
          color: PlayerColor.red,
          isHuman: true,
          tokens: tokens,
        );

        expect(player1, isNot(equals(player2)));
      });
    });
  });
}