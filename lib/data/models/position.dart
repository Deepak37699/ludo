import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../core/enums/game_enums.dart';

part 'position.g.dart';

/// Represents a position on the Ludo game board
@JsonSerializable()
class Position extends Equatable {
  const Position({
    required this.x,
    required this.y,
    required this.type,
    this.ownerColor,
    this.pathIndex,
  });

  /// X coordinate on the board (0-14)
  final int x;

  /// Y coordinate on the board (0-14)
  final int y;

  /// Type of position (regular, safe, home, etc.)
  final PositionType type;

  /// Which player owns this position (for home areas)
  final PlayerColor? ownerColor;

  /// Index in the path for movement calculation (0-51 for main path)
  final int? pathIndex;

  /// Creates a Position from JSON
  factory Position.fromJson(Map<String, dynamic> json) =>
      _$PositionFromJson(json);

  /// Converts Position to JSON
  Map<String, dynamic> toJson() => _$PositionToJson(this);

  /// Creates a copy of this position with optional parameter overrides
  Position copyWith({
    int? x,
    int? y,
    PositionType? type,
    PlayerColor? ownerColor,
    int? pathIndex,
  }) {
    return Position(
      x: x ?? this.x,
      y: y ?? this.y,
      type: type ?? this.type,
      ownerColor: ownerColor ?? this.ownerColor,
      pathIndex: pathIndex ?? this.pathIndex,
    );
  }

  /// Checks if this position is a safe zone
  bool get isSafe => type == PositionType.safe || type == PositionType.home;

  /// Checks if this position is owned by a specific player
  bool isOwnedBy(PlayerColor color) => ownerColor == color;

  /// Calculate distance to another position
  double distanceTo(Position other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return (dx * dx + dy * dy).sqrt();
  }

  /// Check if position is adjacent to another position
  bool isAdjacentTo(Position other) {
    final dx = (x - other.x).abs();
    final dy = (y - other.y).abs();
    return (dx == 1 && dy == 0) || (dx == 0 && dy == 1);
  }

  @override
  List<Object?> get props => [x, y, type, ownerColor, pathIndex];

  @override
  String toString() {
    return 'Position(x: $x, y: $y, type: $type, owner: $ownerColor, path: $pathIndex)';
  }
}

/// Extension for Position calculations
extension PositionCalculations on Position {
  /// Get the next position in the path
  Position? getNextPosition(List<Position> path) {
    if (pathIndex == null || pathIndex! >= path.length - 1) return null;
    return path[pathIndex! + 1];
  }

  /// Get the previous position in the path
  Position? getPreviousPosition(List<Position> path) {
    if (pathIndex == null || pathIndex! <= 0) return null;
    return path[pathIndex! - 1];
  }

  /// Check if this position is on the main path
  bool get isOnMainPath => pathIndex != null && pathIndex! < 52;

  /// Check if this position is in the finish area
  bool get isInFinishArea => type == PositionType.finish;
}