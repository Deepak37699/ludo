import '../../data/models/position.dart';
import '../../core/enums/game_enums.dart';

/// Service class for managing the Ludo board layout and positions
class BoardService {
  static const int boardSize = 15;
  static const int pathLength = 52;
  static const int homePositions = 4;
  static const int finishPositions = 6;

  /// Get the complete board layout with all positions
  static Map<String, Position> getBoardLayout() {
    final Map<String, Position> layout = {};
    
    // Add main path positions
    final mainPath = getMainPath();
    for (int i = 0; i < mainPath.length; i++) {
      layout['path_$i'] = mainPath[i];
    }
    
    // Add home positions for each player
    for (final color in PlayerColor.values) {
      final homePositions = getHomePositions(color);
      for (int i = 0; i < homePositions.length; i++) {
        layout['${color.name}_home_$i'] = homePositions[i];
      }
    }
    
    // Add finish positions for each player
    for (final color in PlayerColor.values) {
      final finishPositions = getFinishPositions(color);
      for (int i = 0; i < finishPositions.length; i++) {
        layout['${color.name}_finish_$i'] = finishPositions[i];
      }
    }
    
    // Add safe positions
    final safePositions = getSafePositions();
    for (int i = 0; i < safePositions.length; i++) {
      layout['safe_$i'] = safePositions[i];
    }
    
    return layout;
  }

  /// Get the main circular path around the board (52 positions)
  static List<Position> getMainPath() {
    List<Position> path = [];
    
    // Starting positions for each color (where tokens enter the main path)
    final startPositions = {
      PlayerColor.red: 1,    // Bottom left start
      PlayerColor.blue: 14,  // Top left start  
      PlayerColor.green: 27, // Top right start
      PlayerColor.yellow: 40, // Bottom right start
    };
    
    // Bottom row (left to right)
    for (int x = 1; x <= 6; x++) {
      path.add(Position(
        x: x,
        y: 14,
        type: x == 2 ? PositionType.safe : PositionType.regular,
        pathIndex: path.length,
      ));
    }
    
    // Bottom middle column (up)
    for (int y = 13; y >= 9; y--) {
      path.add(Position(
        x: 7,
        y: y,
        type: PositionType.regular,
        pathIndex: path.length,
      ));
    }
    
    // Left column (up)
    for (int y = 8; y >= 1; y--) {
      path.add(Position(
        x: 0,
        y: y,
        type: y == 8 ? PositionType.safe : PositionType.regular,
        pathIndex: path.length,
      ));
    }
    
    // Top row (left to right)
    for (int x = 1; x <= 6; x++) {
      path.add(Position(
        x: x,
        y: 0,
        type: x == 2 ? PositionType.safe : PositionType.regular,
        pathIndex: path.length,
      ));
    }
    
    // Top middle column (up)
    for (int y = 1; y <= 5; y++) {
      path.add(Position(
        x: 7,
        y: y,
        type: PositionType.regular,
        pathIndex: path.length,
      ));
    }
    
    // Right column (down)
    for (int y = 6; y <= 13; y++) {
      path.add(Position(
        x: 14,
        y: y,
        type: y == 6 ? PositionType.safe : PositionType.regular,
        pathIndex: path.length,
      ));
    }
    
    // Bottom row (right to left)
    for (int x = 13; x >= 8; x--) {
      path.add(Position(
        x: x,
        y: 14,
        type: x == 12 ? PositionType.safe : PositionType.regular,
        pathIndex: path.length,
      ));
    }
    
    // Right middle column (down)
    for (int y = 13; y >= 9; y--) {
      path.add(Position(
        x: 7,
        y: y,
        type: PositionType.regular,
        pathIndex: path.length,
      ));
    }
    
    return path;
  }

  /// Get home positions for a specific player color
  static List<Position> getHomePositions(PlayerColor color) {
    List<Position> positions = [];
    
    late int baseX, baseY;
    
    switch (color) {
      case PlayerColor.red:
        baseX = 1;
        baseY = 10;
        break;
      case PlayerColor.blue:
        baseX = 1;
        baseY = 1;
        break;
      case PlayerColor.green:
        baseX = 10;
        baseY = 1;
        break;
      case PlayerColor.yellow:
        baseX = 10;
        baseY = 10;
        break;
    }
    
    // Create 4 home positions in a 2x2 grid
    for (int i = 0; i < 4; i++) {
      positions.add(Position(
        x: baseX + (i % 2),
        y: baseY + (i ~/ 2),
        type: PositionType.home,
        ownerColor: color,
      ));
    }
    
    return positions;
  }

  /// Get finish positions for a specific player color (the colored column leading to center)
  static List<Position> getFinishPositions(PlayerColor color) {
    List<Position> positions = [];
    
    switch (color) {
      case PlayerColor.red:
        // Red finish path (vertical column from bottom)
        for (int y = 13; y >= 8; y--) {
          positions.add(Position(
            x: 1,
            y: y,
            type: PositionType.finish,
            ownerColor: color,
            pathIndex: 52 + positions.length, // After main path
          ));
        }
        break;
        
      case PlayerColor.blue:
        // Blue finish path (horizontal row from left)
        for (int x = 1; x <= 6; x++) {
          positions.add(Position(
            x: x,
            y: 1,
            type: PositionType.finish,
            ownerColor: color,
            pathIndex: 52 + positions.length,
          ));
        }
        break;
        
      case PlayerColor.green:
        // Green finish path (vertical column from top)
        for (int y = 1; y <= 6; y++) {
          positions.add(Position(
            x: 13,
            y: y,
            type: PositionType.finish,
            ownerColor: color,
            pathIndex: 52 + positions.length,
          ));
        }
        break;
        
      case PlayerColor.yellow:
        // Yellow finish path (horizontal row from right)
        for (int x = 13; x >= 8; x--) {
          positions.add(Position(
            x: x,
            y: 13,
            type: PositionType.finish,
            ownerColor: color,
            pathIndex: 52 + positions.length,
          ));
        }
        break;
    }
    
    return positions;
  }

  /// Get all safe positions on the board
  static List<Position> getSafePositions() {
    return [
      // Safe positions are at the starting positions of each color
      const Position(x: 2, y: 14, type: PositionType.safe), // Red safe
      const Position(x: 0, y: 8, type: PositionType.safe),  // Blue safe
      const Position(x: 8, y: 0, type: PositionType.safe),  // Green safe
      const Position(x: 14, y: 6, type: PositionType.safe), // Yellow safe
    ];
  }

  /// Get the starting position on the main path for a specific color
  static Position getStartingPosition(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return const Position(x: 1, y: 14, type: PositionType.start, pathIndex: 0);
      case PlayerColor.blue:
        return const Position(x: 0, y: 8, type: PositionType.start, pathIndex: 13);
      case PlayerColor.green:
        return const Position(x: 8, y: 0, type: PositionType.start, pathIndex: 26);
      case PlayerColor.yellow:
        return const Position(x: 14, y: 6, type: PositionType.start, pathIndex: 39);
    }
  }

  /// Get the entrance position to finish area for a specific color
  static Position getFinishEntrancePosition(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return const Position(x: 1, y: 13, type: PositionType.homeEntrance);
      case PlayerColor.blue:
        return const Position(x: 1, y: 1, type: PositionType.homeEntrance);
      case PlayerColor.green:
        return const Position(x: 13, y: 1, type: PositionType.homeEntrance);
      case PlayerColor.yellow:
        return const Position(x: 13, y: 13, type: PositionType.homeEntrance);
    }
  }

  /// Check if a position is safe
  static bool isSafePosition(Position position) {
    return position.type == PositionType.safe || 
           position.type == PositionType.home ||
           position.type == PositionType.finish;
  }

  /// Check if two positions are the same
  static bool isSamePosition(Position pos1, Position pos2) {
    return pos1.x == pos2.x && pos1.y == pos2.y;
  }

  /// Get the center position of the board
  static Position getCenterPosition() {
    return const Position(
      x: 7,
      y: 7,
      type: PositionType.finish,
    );
  }

  /// Calculate the next position given current position and dice value
  static Position? calculateNextPosition(
    Position currentPosition,
    int diceValue,
    PlayerColor playerColor,
  ) {
    // If token is at home, it can only move to starting position with a 6
    if (currentPosition.type == PositionType.home) {
      if (diceValue == 6) {
        return getStartingPosition(playerColor);
      }
      return null;
    }

    // If token is on main path
    if (currentPosition.pathIndex != null && currentPosition.pathIndex! < 52) {
      int currentIndex = currentPosition.pathIndex!;
      int targetIndex = currentIndex + diceValue;

      // Check if token should enter finish area
      final entranceIndex = _getFinishEntranceIndex(playerColor);
      if (currentIndex < entranceIndex && targetIndex >= entranceIndex) {
        // Token passes through entrance, move to finish area
        int finishSteps = targetIndex - entranceIndex;
        final finishPositions = getFinishPositions(playerColor);
        if (finishSteps < finishPositions.length) {
          return finishPositions[finishSteps];
        }
        return null; // Can't move that far in finish area
      }

      // Normal move on main path
      if (targetIndex < 52) {
        final mainPath = getMainPath();
        return mainPath[targetIndex];
      }

      return null; // Would go beyond main path
    }

    // If token is in finish area
    if (currentPosition.type == PositionType.finish) {
      final finishPositions = getFinishPositions(playerColor);
      int currentFinishIndex = finishPositions.indexWhere(
        (pos) => isSamePosition(pos, currentPosition),
      );
      
      if (currentFinishIndex != -1) {
        int targetFinishIndex = currentFinishIndex + diceValue;
        if (targetFinishIndex < finishPositions.length) {
          return finishPositions[targetFinishIndex];
        } else if (targetFinishIndex == finishPositions.length) {
          // Token reaches the center (wins)
          return getCenterPosition();
        }
      }
    }

    return null;
  }

  /// Get the path index where a player enters their finish area
  static int _getFinishEntranceIndex(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return 50; // Before completing full circle
      case PlayerColor.blue:
        return 11; // Before turning right
      case PlayerColor.green:
        return 24; // Before turning down
      case PlayerColor.yellow:
        return 37; // Before turning left
    }
  }

  /// Check if a move is valid
  static bool isValidMove(
    Position currentPosition,
    Position targetPosition,
    int diceValue,
    PlayerColor playerColor,
  ) {
    final calculatedPosition = calculateNextPosition(
      currentPosition,
      diceValue,
      playerColor,
    );
    
    return calculatedPosition != null &&
           isSamePosition(calculatedPosition, targetPosition);
  }

  /// Get all positions that a token can reach from current position
  static List<Position> getPossibleMoves(
    Position currentPosition,
    PlayerColor playerColor,
  ) {
    List<Position> possibleMoves = [];
    
    for (int diceValue = 1; diceValue <= 6; diceValue++) {
      final nextPosition = calculateNextPosition(
        currentPosition,
        diceValue,
        playerColor,
      );
      
      if (nextPosition != null) {
        possibleMoves.add(nextPosition);
      }
    }
    
    return possibleMoves;
  }
}