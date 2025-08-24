import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/data/models/token.dart';
import 'package:ludo_game/data/models/position.dart';
import 'package:ludo_game/core/enums/game_enums.dart';

void main() {
  group('Token', () {
    late Position startPosition;
    late Position homePosition;

    setUp(() {
      startPosition = Position(
        x: 1,
        y: 2,
        type: PositionType.start,
        ownerColor: PlayerColor.red,
        pathIndex: 0,
      );
      
      homePosition = Position(
        x: 0,
        y: 0,
        type: PositionType.home,
        ownerColor: PlayerColor.red,
        pathIndex: null,
      );
    });

    group('constructor', () {
      test('creates token with required parameters', () {
        final token = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: startPosition,
          state: TokenState.home,
        );

        expect(token.id, 'token1');
        expect(token.color, PlayerColor.red);
        expect(token.currentPosition, startPosition);
        expect(token.state, TokenState.home);
        expect(token.isAnimating, false);
        expect(token.moveHistory, isEmpty);
      });

      test('creates token with optional parameters', () {
        final token = Token(
          id: 'token2',
          color: PlayerColor.blue,
          currentPosition: startPosition,
          state: TokenState.active,
          isAnimating: true,
          moveHistory: [homePosition],
        );

        expect(token.isAnimating, true);
        expect(token.moveHistory, [homePosition]);
      });
    });

    group('canMove', () {
      test('returns true when token is in active state', () {
        final token = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: startPosition,
          state: TokenState.active,
        );

        expect(token.canMove, true);
      });

      test('returns false when token is in home state', () {
        final token = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: homePosition,
          state: TokenState.home,
        );

        expect(token.canMove, false);
      });

      test('returns false when token is finished', () {
        final token = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: startPosition,
          state: TokenState.finished,
        );

        expect(token.canMove, false);
      });

      test('returns false when token is animating', () {
        final token = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: startPosition,
          state: TokenState.active,
          isAnimating: true,
        );

        expect(token.canMove, false);
      });
    });

    group('isInHome', () {
      test('returns true when token state is home', () {
        final token = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: homePosition,
          state: TokenState.home,
        );

        expect(token.isInHome, true);
      });

      test('returns false when token state is not home', () {
        final token = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: startPosition,
          state: TokenState.active,
        );

        expect(token.isInHome, false);
      });
    });

    group('isFinished', () {
      test('returns true when token state is finished', () {
        final token = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: startPosition,
          state: TokenState.finished,
        );

        expect(token.isFinished, true);
      });

      test('returns false when token state is not finished', () {
        final token = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: startPosition,
          state: TokenState.active,
        );

        expect(token.isFinished, false);
      });
    });

    group('copyWith', () {
      test('creates copy with updated values', () {
        final originalToken = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: homePosition,
          state: TokenState.home,
        );

        final copiedToken = originalToken.copyWith(
          currentPosition: startPosition,
          state: TokenState.active,
          isAnimating: true,
        );

        expect(copiedToken.id, originalToken.id);
        expect(copiedToken.color, originalToken.color);
        expect(copiedToken.currentPosition, startPosition);
        expect(copiedToken.state, TokenState.active);
        expect(copiedToken.isAnimating, true);
        expect(copiedToken.moveHistory, originalToken.moveHistory);
      });

      test('creates copy with same values when no parameters provided', () {
        final originalToken = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: homePosition,
          state: TokenState.home,
          isAnimating: true,
          moveHistory: [startPosition],
        );

        final copiedToken = originalToken.copyWith();

        expect(copiedToken.id, originalToken.id);
        expect(copiedToken.color, originalToken.color);
        expect(copiedToken.currentPosition, originalToken.currentPosition);
        expect(copiedToken.state, originalToken.state);
        expect(copiedToken.isAnimating, originalToken.isAnimating);
        expect(copiedToken.moveHistory, originalToken.moveHistory);
      });
    });

    group('moveTo', () {
      test('updates position and adds to move history', () {
        final token = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: homePosition,
          state: TokenState.home,
        );

        final newToken = token.moveTo(startPosition);

        expect(newToken.currentPosition, startPosition);
        expect(newToken.moveHistory, [homePosition, startPosition]);
        expect(newToken.state, TokenState.active);
      });

      test('preserves other properties when moving', () {
        final token = Token(
          id: 'token1',
          color: PlayerColor.blue,
          currentPosition: homePosition,
          state: TokenState.home,
          isAnimating: false,
        );

        final newToken = token.moveTo(startPosition);

        expect(newToken.id, token.id);
        expect(newToken.color, token.color);
        expect(newToken.isAnimating, token.isAnimating);
      });
    });

    group('addToHistory', () {
      test('adds position to move history', () {
        final token = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: startPosition,
          state: TokenState.active,
          moveHistory: [homePosition],
        );

        final newPosition = Position(
          x: 2,
          y: 3,
          type: PositionType.path,
          ownerColor: null,
          pathIndex: 1,
        );

        final newToken = token.addToHistory(newPosition);

        expect(newToken.moveHistory, [homePosition, newPosition]);
        expect(newToken.currentPosition, token.currentPosition);
      });

      test('limits history size to maximum', () {
        final longHistory = List.generate(50, (index) => Position(
          x: index,
          y: index,
          type: PositionType.path,
          ownerColor: null,
          pathIndex: index,
        ));

        final token = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: startPosition,
          state: TokenState.active,
          moveHistory: longHistory,
        );

        final newPosition = Position(
          x: 100,
          y: 100,
          type: PositionType.path,
          ownerColor: null,
          pathIndex: 100,
        );

        final newToken = token.addToHistory(newPosition);

        expect(newToken.moveHistory.length, 30); // Max history size
        expect(newToken.moveHistory.last, newPosition);
      });
    });

    group('equality', () {
      test('tokens with same properties are equal', () {
        final token1 = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: startPosition,
          state: TokenState.active,
        );

        final token2 = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: startPosition,
          state: TokenState.active,
        );

        expect(token1, equals(token2));
        expect(token1.hashCode, equals(token2.hashCode));
      });

      test('tokens with different properties are not equal', () {
        final token1 = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: startPosition,
          state: TokenState.active,
        );

        final token2 = Token(
          id: 'token2',
          color: PlayerColor.red,
          currentPosition: startPosition,
          state: TokenState.active,
        );

        expect(token1, isNot(equals(token2)));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final token = Token(
          id: 'token1',
          color: PlayerColor.red,
          currentPosition: startPosition,
          state: TokenState.active,
        );

        final tokenString = token.toString();

        expect(tokenString, contains('token1'));
        expect(tokenString, contains('red'));
        expect(tokenString, contains('active'));
      });
    });
  });
}