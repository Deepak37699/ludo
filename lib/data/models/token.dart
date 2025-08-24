import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../core/enums/game_enums.dart';
import 'position.dart';

part 'token.g.dart';

/// Represents a single token (game piece) in the Ludo game
@JsonSerializable()
class Token extends Equatable {
  const Token({
    required this.id,
    required this.color,
    required this.currentPosition,
    required this.state,
    this.isSelected = false,
    this.animationProgress = 0.0,
    this.moveHistory = const [],
  });

  /// Unique identifier for the token
  final String id;

  /// Color of the token (determines which player owns it)
  final PlayerColor color;

  /// Current position on the board
  final Position currentPosition;

  /// Current state of the token
  final TokenState state;

  /// Whether this token is currently selected by the player
  final bool isSelected;

  /// Animation progress for smooth movement (0.0 to 1.0)
  final double animationProgress;

  /// History of positions this token has visited
  final List<Position> moveHistory;

  /// Creates a new token with a unique ID
  factory Token.create({
    required PlayerColor color,
    required Position startPosition,
  }) {
    return Token(
      id: const Uuid().v4(),
      color: color,
      currentPosition: startPosition,
      state: TokenState.home,
    );
  }

  /// Creates a Token from JSON
  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);

  /// Converts Token to JSON
  Map<String, dynamic> toJson() => _$TokenToJson(this);

  /// Creates a copy of this token with optional parameter overrides
  Token copyWith({
    String? id,
    PlayerColor? color,
    Position? currentPosition,
    TokenState? state,
    bool? isSelected,
    double? animationProgress,
    List<Position>? moveHistory,
  }) {
    return Token(
      id: id ?? this.id,
      color: color ?? this.color,
      currentPosition: currentPosition ?? this.currentPosition,
      state: state ?? this.state,
      isSelected: isSelected ?? this.isSelected,
      animationProgress: animationProgress ?? this.animationProgress,
      moveHistory: moveHistory ?? this.moveHistory,
    );
  }

  /// Move the token to a new position
  Token moveTo(Position newPosition) {
    final newHistory = List<Position>.from(moveHistory)..add(currentPosition);
    TokenState newState = state;

    // Determine new state based on position type
    switch (newPosition.type) {
      case PositionType.home:
        newState = TokenState.home;
        break;
      case PositionType.safe:
        newState = TokenState.safe;
        break;
      case PositionType.finish:
        newState = TokenState.finished;
        break;
      default:
        newState = TokenState.active;
    }

    return copyWith(
      currentPosition: newPosition,
      state: newState,
      moveHistory: newHistory,
      isSelected: false,
      animationProgress: 0.0,
    );
  }

  /// Select or deselect the token
  Token toggleSelection() => copyWith(isSelected: !isSelected);

  /// Update animation progress
  Token updateAnimation(double progress) =>
      copyWith(animationProgress: progress.clamp(0.0, 1.0));

  /// Reset token to home position
  Token resetToHome(Position homePosition) {
    return copyWith(
      currentPosition: homePosition,
      state: TokenState.home,
      isSelected: false,
      animationProgress: 0.0,
      moveHistory: [],
    );
  }

  /// Check if token can be moved (not in home or finished)
  bool get canMove => state == TokenState.active || state == TokenState.safe;

  /// Check if token is at home
  bool get isAtHome => state == TokenState.home;

  /// Check if token has finished
  bool get hasFinished => state == TokenState.finished;

  /// Check if token is in a safe zone
  bool get isInSafeZone => state == TokenState.safe || currentPosition.isSafe;

  /// Get the total distance traveled by this token
  int get distanceTraveled => moveHistory.length;

  /// Check if token can capture another token at the given position
  bool canCapture(Token otherToken) {
    return color != otherToken.color &&
        currentPosition == otherToken.currentPosition &&
        !otherToken.isInSafeZone &&
        canMove;
  }

  @override
  List<Object?> get props => [
        id,
        color,
        currentPosition,
        state,
        isSelected,
        animationProgress,
        moveHistory,
      ];

  @override
  String toString() {
    return 'Token(id: $id, color: $color, position: $currentPosition, state: $state)';
  }
}

/// Extension for Token animations and effects
extension TokenAnimations on Token {
  /// Calculate interpolated position for smooth animation
  Position getInterpolatedPosition(Position targetPosition, double progress) {
    if (progress >= 1.0) return targetPosition;
    if (progress <= 0.0) return currentPosition;

    final startX = currentPosition.x.toDouble();
    final startY = currentPosition.y.toDouble();
    final endX = targetPosition.x.toDouble();
    final endY = targetPosition.y.toDouble();

    final interpolatedX = startX + (endX - startX) * progress;
    final interpolatedY = startY + (endY - startY) * progress;

    return Position(
      x: interpolatedX.round(),
      y: interpolatedY.round(),
      type: progress > 0.5 ? targetPosition.type : currentPosition.type,
      ownerColor: targetPosition.ownerColor,
      pathIndex: targetPosition.pathIndex,
    );
  }

  /// Get scale factor for token emphasis effects
  double getScaleFactor() {
    if (isSelected) return 1.2;
    if (animationProgress > 0) return 1.0 + (animationProgress * 0.1);
    return 1.0;
  }

  /// Get rotation angle for token movement animation
  double getRotationAngle() {
    return animationProgress * 360.0;
  }
}