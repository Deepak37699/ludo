import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../data/models/token.dart';
import '../../../data/models/position.dart';
import '../../../data/models/game_state.dart';
import '../../../core/enums/game_enums.dart';
import '../../../services/performance/performance_optimizer.dart';
import '../../../services/performance/performance_monitor.dart';

/// Optimized game board painter with performance enhancements
class OptimizedGameBoardPainter extends CustomPainter {
  final GameState gameState;
  final List<Position> validMoves;
  final Position? selectedPosition;
  final double animationProgress;
  final bool enableShadows;
  final bool enableGradients;
  
  // Performance optimization fields
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  late final Paint _boardPaint;
  late final Paint _pathPaint;
  late final Paint _homePaint;
  late final Paint _safePaint;
  late final Paint _shadowPaint;
  
  // Cache for expensive calculations
  static final Map<String, Path> _pathCache = {};
  static final Map<String, List<Offset>> _gridCache = {};
  
  OptimizedGameBoardPainter({
    required this.gameState,
    required this.validMoves,
    this.selectedPosition,
    this.animationProgress = 0.0,
    this.enableShadows = true,
    this.enableGradients = true,
  }) {
    _initializePaints();
  }

  /// Initialize paint objects with optimization
  void _initializePaints() {
    _boardPaint = _optimizer.getOptimizedPaint()
      ..color = Colors.brown.shade200
      ..style = PaintingStyle.fill;
    
    _pathPaint = _optimizer.getOptimizedPaint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0;
    
    _homePaint = _optimizer.getOptimizedPaint()
      ..style = PaintingStyle.fill;
    
    _safePaint = _optimizer.getOptimizedPaint()
      ..color = Colors.green.shade100
      ..style = PaintingStyle.fill;
    
    _shadowPaint = _optimizer.getOptimizedPaint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    PerformanceMonitor().measureSync('board_paint', () {
      _paintOptimized(canvas, size);
    });
  }

  /// Optimized painting method
  void _paintOptimized(Canvas canvas, Size size) {
    final cellSize = size.width / 15;
    
    // Use cached grid if available
    final gridKey = '${size.width}_${size.height}';
    List<Offset> gridPoints;
    
    if (_gridCache.containsKey(gridKey)) {
      gridPoints = _gridCache[gridKey]!;
    } else {
      gridPoints = _calculateGridPoints(size, cellSize);
      _gridCache[gridKey] = gridPoints;
    }
    
    // Paint layers in optimized order
    _paintBackground(canvas, size);
    _paintBoard(canvas, size, cellSize);
    _paintPaths(canvas, size, cellSize);
    _paintHomeAreas(canvas, size, cellSize);
    _paintSafeZones(canvas, size, cellSize);
    _paintValidMoves(canvas, size, cellSize);
    _paintTokens(canvas, size, cellSize);
    _paintSelection(canvas, size, cellSize);
    
    if (enableShadows) {
      _paintShadows(canvas, size, cellSize);
    }
  }

  /// Calculate grid points for the board
  List<Offset> _calculateGridPoints(Size size, double cellSize) {
    final points = <Offset>[];
    
    for (int i = 0; i <= 15; i++) {
      for (int j = 0; j <= 15; j++) {
        points.add(Offset(i * cellSize, j * cellSize));
      }
    }
    
    return points;
  }

  /// Paint optimized background
  void _paintBackground(Canvas canvas, Size size) {
    if (enableGradients) {
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.brown.shade100,
          Colors.brown.shade300,
        ],
      );
      
      _boardPaint.shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    }
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      _boardPaint,
    );
  }

  /// Paint board grid with optimization
  void _paintBoard(Canvas canvas, Size size, double cellSize) {
    // Use cached path if available
    final pathKey = 'board_grid_${size.width}';
    Path gridPath;
    
    if (_pathCache.containsKey(pathKey)) {
      gridPath = _pathCache[pathKey]!;
    } else {
      gridPath = _createGridPath(size, cellSize);
      _pathCache[pathKey] = gridPath;
    }
    
    _pathPaint.color = Colors.black.withOpacity(0.1);
    _pathPaint.style = PaintingStyle.stroke;
    canvas.drawPath(gridPath, _pathPaint);
  }

  /// Create optimized grid path
  Path _createGridPath(Size size, double cellSize) {
    final path = _optimizer.getOptimizedPath();
    
    // Vertical lines
    for (int i = 0; i <= 15; i++) {
      final x = i * cellSize;
      path.moveTo(x, 0);
      path.lineTo(x, size.height);
    }
    
    // Horizontal lines
    for (int j = 0; j <= 15; j++) {
      final y = j * cellSize;
      path.moveTo(0, y);
      path.lineTo(size.width, y);
    }
    
    return path;
  }

  /// Paint game paths with optimization
  void _paintPaths(Canvas canvas, Size size, double cellSize) {
    _pathPaint.style = PaintingStyle.fill;
    _pathPaint.color = Colors.white.withOpacity(0.8);
    
    // Paint main path around the board
    final pathPositions = _getMainPathPositions();
    
    for (final position in pathPositions) {
      final rect = Rect.fromLTWH(
        position.x * cellSize,
        position.y * cellSize,
        cellSize,
        cellSize,
      );
      
      if (enableShadows) {
        canvas.drawRect(rect.translate(1, 1), _shadowPaint);
      }
      canvas.drawRect(rect, _pathPaint);
    }
  }

  /// Paint home areas with player colors
  void _paintHomeAreas(Canvas canvas, Size size, double cellSize) {
    final homeAreas = _getHomeAreas();
    
    for (final entry in homeAreas.entries) {
      final color = entry.key;
      final area = entry.value;
      
      _homePaint.color = _getPlayerColor(color).withOpacity(0.3);
      
      if (enableGradients) {
        final gradient = RadialGradient(
          center: Alignment.center,
          colors: [
            _getPlayerColor(color).withOpacity(0.5),
            _getPlayerColor(color).withOpacity(0.2),
          ],
        );
        
        _homePaint.shader = gradient.createShader(area);
      }
      
      if (enableShadows) {
        canvas.drawRect(area.translate(2, 2), _shadowPaint);
      }
      canvas.drawRect(area, _homePaint);
    }
  }

  /// Paint safe zones
  void _paintSafeZones(Canvas canvas, Size size, double cellSize) {
    final safeZones = _getSafeZonePositions();
    
    for (final position in safeZones) {
      final rect = Rect.fromLTWH(
        position.x * cellSize,
        position.y * cellSize,
        cellSize,
        cellSize,
      );
      
      if (enableShadows) {
        canvas.drawRect(rect.translate(1, 1), _shadowPaint);
      }
      canvas.drawRect(rect, _safePaint);
      
      // Draw safe zone indicator
      final center = rect.center;
      final starPath = _createStarPath(center, cellSize * 0.2);
      
      _pathPaint.color = Colors.green.shade700;
      _pathPaint.style = PaintingStyle.fill;
      canvas.drawPath(starPath, _pathPaint);
    }
  }

  /// Paint valid moves with animation
  void _paintValidMoves(Canvas canvas, Size size, double cellSize) {
    if (validMoves.isEmpty) return;
    
    final validMovePaint = _optimizer.getOptimizedPaint()
      ..color = Colors.green.withOpacity(0.6 + 0.2 * math.sin(animationProgress * math.pi * 2))
      ..style = PaintingStyle.fill;
    
    for (final position in validMoves) {
      final rect = Rect.fromLTWH(
        position.x * cellSize,
        position.y * cellSize,
        cellSize,
        cellSize,
      );
      
      // Animated pulsing effect
      final scale = 0.8 + 0.2 * math.sin(animationProgress * math.pi * 4);
      final scaledRect = Rect.fromCenter(
        center: rect.center,
        width: rect.width * scale,
        height: rect.height * scale,
      );
      
      canvas.drawOval(scaledRect, validMovePaint);
    }
    
    _optimizer.returnPaint(validMovePaint);
  }

  /// Paint tokens with optimization
  void _paintTokens(Canvas canvas, Size size, double cellSize) {
    final allTokens = gameState.players.expand((p) => p.tokens).toList();
    
    for (final token in allTokens) {
      _paintToken(canvas, token, cellSize);
    }
  }

  /// Paint individual token with optimization
  void _paintToken(Canvas canvas, Token token, double cellSize) {
    final position = token.currentPosition;
    final center = Offset(
      position.x * cellSize + cellSize / 2,
      position.y * cellSize + cellSize / 2,
    );
    
    final tokenPaint = _optimizer.getOptimizedPaint()
      ..color = _getPlayerColor(token.color)
      ..style = PaintingStyle.fill;
    
    final borderPaint = _optimizer.getOptimizedPaint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final radius = cellSize * 0.3;
    
    // Animated scale for selected token
    final scale = token.isSelected 
        ? 1.0 + 0.1 * math.sin(animationProgress * math.pi * 4)
        : 1.0;
    
    final scaledRadius = radius * scale;
    
    // Shadow
    if (enableShadows) {
      canvas.drawCircle(center.translate(2, 2), scaledRadius, _shadowPaint);
    }
    
    // Token body with gradient
    if (enableGradients) {
      final gradient = RadialGradient(
        colors: [
          _getPlayerColor(token.color),
          _getPlayerColor(token.color).withOpacity(0.7),
        ],
      );
      
      tokenPaint.shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: scaledRadius),
      );
    }
    
    canvas.drawCircle(center, scaledRadius, tokenPaint);
    canvas.drawCircle(center, scaledRadius, borderPaint);
    
    // Token number/ID
    final textPainter = TextPainter(
      text: TextSpan(
        text: token.id.substring(token.id.length - 1),
        style: TextStyle(
          color: Colors.white,
          fontSize: cellSize * 0.2,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
    
    _optimizer.returnPaint(tokenPaint);
    _optimizer.returnPaint(borderPaint);
  }

  /// Paint selection indicator
  void _paintSelection(Canvas canvas, Size size, double cellSize) {
    if (selectedPosition == null) return;
    
    final rect = Rect.fromLTWH(
      selectedPosition!.x * cellSize,
      selectedPosition!.y * cellSize,
      cellSize,
      cellSize,
    );
    
    final selectionPaint = _optimizer.getOptimizedPaint()
      ..color = Colors.blue.withOpacity(0.5 + 0.3 * math.sin(animationProgress * math.pi * 3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawRect(rect, selectionPaint);
    
    _optimizer.returnPaint(selectionPaint);
  }

  /// Paint shadows for depth effect
  void _paintShadows(Canvas canvas, Size size, double cellSize) {
    // This method adds depth shadows to various board elements
    // Implementation would add shadow effects to tokens, board areas, etc.
  }

  /// Create star path for safe zones
  Path _createStarPath(Offset center, double radius) {
    final path = _optimizer.getOptimizedPath();
    const points = 5;
    final angle = math.pi / points;
    
    for (int i = 0; i < points * 2; i++) {
      final currentRadius = i.isEven ? radius : radius * 0.5;
      final x = center.dx + currentRadius * math.cos(i * angle);
      final y = center.dy + currentRadius * math.sin(i * angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    return path;
  }

  /// Get main path positions
  List<Position> _getMainPathPositions() {
    // Return the positions that form the main path around the board
    // This is a simplified implementation
    final positions = <Position>[];
    
    // Top row
    for (int x = 1; x <= 13; x++) {
      if (x == 6) continue; // Skip center column
      positions.add(Position(x: x, y: 6, type: PositionType.regular));
    }
    
    // Right column  
    for (int y = 1; y <= 13; y++) {
      if (y == 6) continue; // Skip center row
      positions.add(Position(x: 8, y: y, type: PositionType.regular));
    }
    
    // Bottom row
    for (int x = 13; x >= 1; x--) {
      if (x == 8) continue; // Skip center column
      positions.add(Position(x: x, y: 8, type: PositionType.regular));
    }
    
    // Left column
    for (int y = 13; y >= 1; y--) {
      if (y == 8) continue; // Skip center row
      positions.add(Position(x: 6, y: y, type: PositionType.regular));
    }
    
    return positions;
  }

  /// Get home areas for each player
  Map<PlayerColor, Rect> _getHomeAreas() {
    return {
      PlayerColor.red: const Rect.fromLTWH(0, 0, 6, 6),
      PlayerColor.blue: const Rect.fromLTWH(9, 0, 6, 6),
      PlayerColor.green: const Rect.fromLTWH(0, 9, 6, 6),
      PlayerColor.yellow: const Rect.fromLTWH(9, 9, 6, 6),
    };
  }

  /// Get safe zone positions
  List<Position> _getSafeZonePositions() {
    return [
      Position(x: 2, y: 6, type: PositionType.safe),
      Position(x: 6, y: 2, type: PositionType.safe),
      Position(x: 8, y: 12, type: PositionType.safe),
      Position(x: 12, y: 8, type: PositionType.safe),
    ];
  }

  /// Get player color
  Color _getPlayerColor(PlayerColor playerColor) {
    switch (playerColor) {
      case PlayerColor.red:
        return Colors.red;
      case PlayerColor.blue:
        return Colors.blue;
      case PlayerColor.green:
        return Colors.green;
      case PlayerColor.yellow:
        return Colors.yellow;
    }
  }

  @override
  bool shouldRepaint(OptimizedGameBoardPainter oldDelegate) {
    return oldDelegate.gameState != gameState ||
           oldDelegate.validMoves != validMoves ||
           oldDelegate.selectedPosition != selectedPosition ||
           oldDelegate.animationProgress != animationProgress;
  }

  @override
  void dispose() {
    // Return paint objects to pool
    _optimizer.returnPaint(_boardPaint);
    _optimizer.returnPaint(_pathPaint);
    _optimizer.returnPaint(_homePaint);
    _optimizer.returnPaint(_safePaint);
    _optimizer.returnPaint(_shadowPaint);
    
    super.dispose();
  }
}