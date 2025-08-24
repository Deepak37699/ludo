import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../data/models/position.dart';
import '../../../data/models/token.dart';
import '../../../core/enums/game_enums.dart';
import '../../../services/themes/theme_service.dart';
import '../../../services/game/board_service.dart';

/// Themed board painter that applies selected theme to the game board
class ThemedBoardPainter extends CustomPainter {
  final BoardThemeData? boardTheme;
  final GameThemeData? gameTheme;
  final List<Token> tokens;
  final Position? highlightedPosition;
  final List<Position> validMoves;
  final double cellSize;

  const ThemedBoardPainter({
    this.boardTheme,
    this.gameTheme,
    this.tokens = const [],
    this.highlightedPosition,
    this.validMoves = const [],
    this.cellSize = 25.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final theme = boardTheme;
    if (theme == null) {
      _paintDefaultBoard(canvas, size);
      return;
    }

    // Apply board theme
    _paintThemedBoard(canvas, size, theme);
    _paintTokens(canvas, size, theme);
    _paintHighlights(canvas, size, theme);
  }

  void _paintThemedBoard(Canvas canvas, Size size, BoardThemeData theme) {
    final paint = Paint();
    
    // Draw background
    paint.color = theme.boardBackgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw background pattern if available
    if (theme.backgroundPattern != null) {
      _paintBackgroundPattern(canvas, size, theme);
    }
    
    // Draw board border
    paint
      ..color = theme.boardBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw grid lines
    _paintGrid(canvas, size, theme);
    
    // Draw home areas
    _paintHomeAreas(canvas, size, theme);
    
    // Draw main path
    _paintMainPath(canvas, size, theme);
    
    // Draw safe zones
    _paintSafeZones(canvas, size, theme);
    
    // Draw center design
    _paintCenterDesign(canvas, size, theme);
    
    // Draw finish areas
    _paintFinishAreas(canvas, size, theme);
  }

  void _paintBackgroundPattern(Canvas canvas, Size size, BoardThemeData theme) {
    final paint = Paint()..color = theme.boardBorderColor.withOpacity(0.1);
    
    switch (theme.backgroundPattern) {
      case 'royal_pattern':
        _paintRoyalPattern(canvas, size, paint);
        break;
      case 'space_pattern':
        _paintSpacePattern(canvas, size, paint);
        break;
      case 'wood_pattern':
        _paintWoodPattern(canvas, size, paint);
        break;
    }
  }

  void _paintRoyalPattern(Canvas canvas, Size size, Paint paint) {
    // Draw diamond pattern
    final spacing = cellSize;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final path = Path()
          ..moveTo(x, y - spacing/4)
          ..lineTo(x + spacing/4, y)
          ..lineTo(x, y + spacing/4)
          ..lineTo(x - spacing/4, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _paintSpacePattern(Canvas canvas, Size size, Paint paint) {
    // Draw star pattern
    final spacing = cellSize * 2;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        _drawStar(canvas, Offset(x, y), cellSize / 4, paint);
      }
    }
  }

  void _paintWoodPattern(Canvas canvas, Size size, Paint paint) {
    // Draw wood grain pattern
    paint.strokeWidth = 1.0;
    for (double y = 0; y < size.height; y += cellSize / 2) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 10 * math.sin(y / 20)),
        paint,
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final outerRadius = radius;
    final innerRadius = radius * 0.4;
    
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi) / 5;
      final r = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _paintGrid(Canvas canvas, Size size, BoardThemeData theme) {
    final paint = Paint()
      ..color = theme.boardBorderColor.withOpacity(0.3)
      ..strokeWidth = 0.5;
    
    // Vertical lines
    for (int i = 0; i <= 15; i++) {
      final x = i * cellSize;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Horizontal lines
    for (int i = 0; i <= 15; i++) {
      final y = i * cellSize;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _paintHomeAreas(Canvas canvas, Size size, BoardThemeData theme) {
    final paint = Paint();
    
    // Home area size (6x6 grid)
    final homeSize = cellSize * 6;
    
    // Red home (top-left)
    paint.color = theme.homeAreaColors[PlayerColor.red] ?? Colors.red.shade100;
    canvas.drawRect(Rect.fromLTWH(0, 0, homeSize, homeSize), paint);
    
    // Blue home (top-right)
    paint.color = theme.homeAreaColors[PlayerColor.blue] ?? Colors.blue.shade100;
    canvas.drawRect(Rect.fromLTWH(size.width - homeSize, 0, homeSize, homeSize), paint);
    
    // Green home (bottom-left)
    paint.color = theme.homeAreaColors[PlayerColor.green] ?? Colors.green.shade100;
    canvas.drawRect(Rect.fromLTWH(0, size.height - homeSize, homeSize, homeSize), paint);
    
    // Yellow home (bottom-right)
    paint.color = theme.homeAreaColors[PlayerColor.yellow] ?? Colors.yellow.shade100;
    canvas.drawRect(Rect.fromLTWH(size.width - homeSize, size.height - homeSize, homeSize, homeSize), paint);
    
    // Draw home area borders
    paint
      ..color = theme.boardBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, homeSize, homeSize), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - homeSize, 0, homeSize, homeSize), paint);
    canvas.drawRect(Rect.fromLTWH(0, size.height - homeSize, homeSize, homeSize), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - homeSize, size.height - homeSize, homeSize, homeSize), paint);
  }

  void _paintMainPath(Canvas canvas, Size size, BoardThemeData theme) {
    final paint = Paint()..color = theme.pathColor;
    
    // Main path consists of the outer track
    final pathWidth = cellSize;
    final homeSize = cellSize * 6;
    
    // Top horizontal path
    canvas.drawRect(
      Rect.fromLTWH(homeSize, cellSize, size.width - 2 * homeSize, pathWidth),
      paint,
    );
    
    // Bottom horizontal path
    canvas.drawRect(
      Rect.fromLTWH(homeSize, size.height - 2 * cellSize, size.width - 2 * homeSize, pathWidth),
      paint,
    );
    
    // Left vertical path
    canvas.drawRect(
      Rect.fromLTWH(cellSize, homeSize, pathWidth, size.height - 2 * homeSize),
      paint,
    );
    
    // Right vertical path
    canvas.drawRect(
      Rect.fromLTWH(size.width - 2 * cellSize, homeSize, pathWidth, size.height - 2 * homeSize),
      paint,
    );
  }

  void _paintSafeZones(Canvas canvas, Size size, BoardThemeData theme) {
    final paint = Paint()..color = theme.safeZoneColor;
    final safeSize = cellSize * 0.8;
    final offset = (cellSize - safeSize) / 2;
    
    // Safe zones at specific positions
    final safePositions = [
      Offset(cellSize * 2 + offset, cellSize + offset), // Red safe zone
      Offset(cellSize * 8 + offset, cellSize + offset), // Top middle
      Offset(size.width - cellSize * 2 - safeSize + offset, cellSize + offset), // Blue safe zone
      // Add more safe positions...
    ];
    
    for (final pos in safePositions) {
      canvas.drawRect(
        Rect.fromLTWH(pos.dx, pos.dy, safeSize, safeSize),
        paint,
      );
    }
  }

  void _paintCenterDesign(Canvas canvas, Size size, BoardThemeData theme) {
    final center = Offset(size.width / 2, size.height / 2);
    final centerSize = cellSize * 3;
    final paint = Paint();
    
    switch (theme.centerDesign) {
      case BoardCenterDesign.classic:
        _paintClassicCenter(canvas, center, centerSize, theme, paint);
        break;
      case BoardCenterDesign.royal:
        _paintRoyalCenter(canvas, center, centerSize, theme, paint);
        break;
      case BoardCenterDesign.space:
        _paintSpaceCenter(canvas, center, centerSize, theme, paint);
        break;
      case BoardCenterDesign.nature:
        _paintNatureCenter(canvas, center, centerSize, theme, paint);
        break;
      case BoardCenterDesign.minimal:
        _paintMinimalCenter(canvas, center, centerSize, theme, paint);
        break;
    }
  }

  void _paintClassicCenter(Canvas canvas, Offset center, double size, BoardThemeData theme, Paint paint) {
    // Draw triangular sections
    paint.color = theme.finishAreaColors[PlayerColor.red] ?? Colors.red.shade200;
    _drawTriangle(canvas, center, size, 0, paint);
    
    paint.color = theme.finishAreaColors[PlayerColor.blue] ?? Colors.blue.shade200;
    _drawTriangle(canvas, center, size, math.pi / 2, paint);
    
    paint.color = theme.finishAreaColors[PlayerColor.green] ?? Colors.green.shade200;
    _drawTriangle(canvas, center, size, math.pi, paint);
    
    paint.color = theme.finishAreaColors[PlayerColor.yellow] ?? Colors.yellow.shade200;
    _drawTriangle(canvas, center, size, 3 * math.pi / 2, paint);
    
    // Draw center circle
    paint.color = theme.boardBackgroundColor;
    canvas.drawCircle(center, size / 6, paint);
  }

  void _paintRoyalCenter(Canvas canvas, Offset center, double size, BoardThemeData theme, Paint paint) {
    // Draw ornate design
    paint.color = Colors.amber.shade200;
    canvas.drawCircle(center, size / 2, paint);
    
    paint
      ..color = Colors.amber.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, size / 2, paint);
    canvas.drawCircle(center, size / 4, paint);
    
    // Draw crown symbol
    paint
      ..color = Colors.amber.shade700
      ..style = PaintingStyle.fill;
    _drawCrown(canvas, center, size / 3, paint);
  }

  void _paintSpaceCenter(Canvas canvas, Offset center, double size, BoardThemeData theme, Paint paint) {
    // Draw planet with rings
    paint.color = Colors.indigo.shade800;
    canvas.drawCircle(center, size / 2, paint);
    
    paint
      ..color = Colors.cyan.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    // Draw orbital rings
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, size / 2 + i * 10, paint);
    }
    
    // Draw stars
    paint
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * math.pi) / 8;
      final starPos = Offset(
        center.dx + (size / 2 + 25) * math.cos(angle),
        center.dy + (size / 2 + 25) * math.sin(angle),
      );
      _drawStar(canvas, starPos, 3, paint);
    }
  }

  void _paintNatureCenter(Canvas canvas, Offset center, double size, BoardThemeData theme, Paint paint) {
    // Draw tree design
    paint.color = Colors.brown.shade400;
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 5, center.dy, 10, size / 3),
      paint,
    );
    
    paint.color = Colors.green.shade400;
    canvas.drawCircle(
      Offset(center.dx, center.dy - size / 6),
      size / 4,
      paint,
    );
    
    // Draw leaves
    for (int i = 0; i < 12; i++) {
      final angle = (i * 2 * math.pi) / 12;
      final leafPos = Offset(
        center.dx + (size / 3) * math.cos(angle),
        center.dy - size / 6 + (size / 3) * math.sin(angle),
      );
      paint.color = Colors.green.shade300;
      canvas.drawCircle(leafPos, 5, paint);
    }
  }

  void _paintMinimalCenter(Canvas canvas, Offset center, double size, BoardThemeData theme, Paint paint) {
    // Simple circle design
    paint
      ..color = theme.boardBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, size / 2, paint);
    canvas.drawCircle(center, size / 4, paint);
  }

  void _drawTriangle(Canvas canvas, Offset center, double size, double rotation, Paint paint) {
    final path = Path();
    final radius = size / 2;
    
    for (int i = 0; i < 3; i++) {
      final angle = rotation + (i * 2 * math.pi) / 3;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCrown(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final baseWidth = size;
    final height = size * 0.6;
    
    // Crown base
    path.moveTo(center.dx - baseWidth / 2, center.dy + height / 2);
    path.lineTo(center.dx + baseWidth / 2, center.dy + height / 2);
    
    // Crown peaks
    path.lineTo(center.dx + baseWidth / 3, center.dy - height / 2);
    path.lineTo(center.dx, center.dy);
    path.lineTo(center.dx - baseWidth / 3, center.dy - height / 2);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _paintFinishAreas(Canvas canvas, Size size, BoardThemeData theme) {
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);
    final finishWidth = cellSize;
    
    // Red finish area (from left)
    paint.color = theme.finishAreaColors[PlayerColor.red] ?? Colors.red.shade200;
    canvas.drawRect(
      Rect.fromLTWH(cellSize * 2, center.dy - finishWidth / 2, cellSize * 4, finishWidth),
      paint,
    );
    
    // Blue finish area (from top)
    paint.color = theme.finishAreaColors[PlayerColor.blue] ?? Colors.blue.shade200;
    canvas.drawRect(
      Rect.fromLTWH(center.dx - finishWidth / 2, cellSize * 2, finishWidth, cellSize * 4),
      paint,
    );
    
    // Green finish area (from right)
    paint.color = theme.finishAreaColors[PlayerColor.green] ?? Colors.green.shade200;
    canvas.drawRect(
      Rect.fromLTWH(size.width - cellSize * 6, center.dy - finishWidth / 2, cellSize * 4, finishWidth),
      paint,
    );
    
    // Yellow finish area (from bottom)
    paint.color = theme.finishAreaColors[PlayerColor.yellow] ?? Colors.yellow.shade200;
    canvas.drawRect(
      Rect.fromLTWH(center.dx - finishWidth / 2, size.height - cellSize * 6, finishWidth, cellSize * 4),
      paint,
    );
  }

  void _paintTokens(Canvas canvas, Size size, BoardThemeData theme) {
    for (final token in tokens) {
      _paintToken(canvas, token, theme);
    }
  }

  void _paintToken(Canvas canvas, Token token, BoardThemeData theme) {
    final paint = Paint();
    final position = token.currentPosition;
    final center = Offset(
      position.x * cellSize + cellSize / 2,
      position.y * cellSize + cellSize / 2,
    );
    
    // Get token color from game theme
    final tokenColor = gameTheme?.playerColors[token.color] ?? _getDefaultTokenColor(token.color);
    
    // Apply token style from board theme
    switch (theme.tokenStyle) {
      case TokenStyle.flat:
        paint.color = tokenColor;
        canvas.drawCircle(center, cellSize / 3, paint);
        break;
        
      case TokenStyle.glossy:
        // Draw shadow
        paint.color = Colors.black.withOpacity(0.3);
        canvas.drawCircle(center + const Offset(2, 2), cellSize / 3, paint);
        
        // Draw token
        paint.color = tokenColor;
        canvas.drawCircle(center, cellSize / 3, paint);
        
        // Draw highlight
        final gradient = RadialGradient(
          colors: [
            tokenColor.withOpacity(0.8),
            tokenColor,
          ],
        );
        paint.shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: cellSize / 3),
        );
        canvas.drawCircle(center, cellSize / 3, paint);
        break;
        
      case TokenStyle.neon:
        // Draw glow effect
        for (int i = 5; i > 0; i--) {
          paint.color = tokenColor.withOpacity(0.1 * i);
          canvas.drawCircle(center, cellSize / 3 + i * 2, paint);
        }
        
        // Draw token
        paint.color = tokenColor;
        canvas.drawCircle(center, cellSize / 3, paint);
        break;
        
      case TokenStyle.wooden:
        // Draw wood texture
        paint.color = tokenColor.withRed((tokenColor.red * 0.8).round());
        canvas.drawCircle(center, cellSize / 3, paint);
        
        // Draw wood grain
        paint
          ..color = tokenColor.withOpacity(0.3)
          ..strokeWidth = 1.0;
        for (int i = 0; i < 3; i++) {
          canvas.drawLine(
            center + Offset(-cellSize / 6, -cellSize / 6 + i * 4),
            center + Offset(cellSize / 6, -cellSize / 6 + i * 4),
            paint,
          );
        }
        break;
        
      case TokenStyle.metallic:
        // Draw metallic effect
        final metallicGradient = RadialGradient(
          colors: [
            tokenColor.withOpacity(0.6),
            tokenColor,
            tokenColor.withOpacity(0.4),
          ],
          stops: const [0.0, 0.7, 1.0],
        );
        paint.shader = metallicGradient.createShader(
          Rect.fromCircle(center: center, radius: cellSize / 3),
        );
        canvas.drawCircle(center, cellSize / 3, paint);
        
        // Draw metallic border
        paint
          ..shader = null
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(center, cellSize / 3, paint);
        break;
    }
    
    // Draw token border
    paint
      ..shader = null
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, cellSize / 3, paint);
  }

  void _paintHighlights(Canvas canvas, Size size, BoardThemeData theme) {
    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    // Highlight valid moves
    for (final position in validMoves) {
      final center = Offset(
        position.x * cellSize + cellSize / 2,
        position.y * cellSize + cellSize / 2,
      );
      canvas.drawCircle(center, cellSize / 4, paint);
    }
    
    // Highlight selected position
    if (highlightedPosition != null) {
      paint.color = Colors.blue.withOpacity(0.5);
      final center = Offset(
        highlightedPosition!.x * cellSize + cellSize / 2,
        highlightedPosition!.y * cellSize + cellSize / 2,
      );
      canvas.drawCircle(center, cellSize / 2, paint);
    }
  }

  void _paintDefaultBoard(Canvas canvas, Size size) {
    // Fallback to basic board painting
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    paint
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  Color _getDefaultTokenColor(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return Colors.red.shade600;
      case PlayerColor.blue:
        return Colors.blue.shade600;
      case PlayerColor.green:
        return Colors.green.shade600;
      case PlayerColor.yellow:
        return Colors.yellow.shade700;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! ThemedBoardPainter ||
           oldDelegate.boardTheme != boardTheme ||
           oldDelegate.gameTheme != gameTheme ||
           oldDelegate.tokens != tokens ||
           oldDelegate.highlightedPosition != highlightedPosition ||
           oldDelegate.validMoves != validMoves;
  }
}