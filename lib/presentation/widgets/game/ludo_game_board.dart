import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/game_state.dart';
import '../../../data/models/position.dart';
import '../../../data/models/token.dart';
import '../../../core/enums/game_enums.dart';
import '../../../services/game/board_service.dart';
import '../../../services/game/move_validation_service.dart';
import '../../providers/game_provider.dart';
import '../widgets.dart';

/// Main Ludo game board widget
class LudoGameBoard extends ConsumerStatefulWidget {
  final GameState gameState;
  final Function(String tokenId, Position targetPosition)? onTokenMove;
  final Function(String tokenId)? onTokenSelect;

  const LudoGameBoard({
    super.key,
    required this.gameState,
    this.onTokenMove,
    this.onTokenSelect,
  });

  @override
  ConsumerState<LudoGameBoard> createState() => _LudoGameBoardState();
}

class _LudoGameBoardState extends ConsumerState<LudoGameBoard> {
  static const double boardSize = 350.0;
  static const double cellSize = boardSize / 15;
  
  String? selectedTokenId;
  List<Position> validMoves = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: boardSize,
      height: boardSize,
      child: Stack(
        children: [
          // Board background
          CustomPaint(
            size: const Size(boardSize, boardSize),
            painter: LudoBoardPainter(
              gameState: widget.gameState,
              validMoves: validMoves,
            ),
          ),
          
          // Tokens
          ...buildTokenWidgets(),
          
          // Tap detection
          ...buildTapDetectors(),
        ],
      ),
    );
  }

  List<Widget> buildTokenWidgets() {
    List<Widget> tokenWidgets = [];
    
    for (final player in widget.gameState.players) {
      for (final token in player.tokens) {
        final position = _getScreenPosition(token.currentPosition);
        
        tokenWidgets.add(
          Positioned(
            left: position.dx - cellSize / 2,
            top: position.dy - cellSize / 2,
            child: TokenWidget(
              token: token,
              size: cellSize * 0.8,
              isHighlighted: token.id == selectedTokenId,
              onTap: () => _onTokenTap(token),
            ),
          ),
        );
      }
    }
    
    return tokenWidgets;
  }

  List<Widget> buildTapDetectors() {
    if (selectedTokenId == null || validMoves.isEmpty) {
      return [];
    }

    return validMoves.map((position) {
      final screenPos = _getScreenPosition(position);
      
      return Positioned(
        left: screenPos.dx - cellSize / 2,
        top: screenPos.dy - cellSize / 2,
        child: GestureDetector(
          onTap: () => _onPositionTap(position),
          child: Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.green,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.green,
              size: 16,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _onTokenTap(Token token) {
    // Only allow selection of current player's tokens
    if (token.color != widget.gameState.currentPlayer.color) {
      return;
    }

    setState(() {
      if (selectedTokenId == token.id) {
        // Deselect if already selected
        selectedTokenId = null;
        validMoves = [];
      } else {
        // Select new token
        selectedTokenId = token.id;
        _calculateValidMoves(token);
      }
    });

    widget.onTokenSelect?.call(token.id);
  }

  void _onPositionTap(Position position) {
    if (selectedTokenId != null) {
      widget.onTokenMove?.call(selectedTokenId!, position);
      setState(() {
        selectedTokenId = null;
        validMoves = [];
      });
    }
  }

  void _calculateValidMoves(Token token) {
    final diceValue = widget.gameState.lastDiceRoll;
    if (diceValue == 0) {
      validMoves = [];
      return;
    }

    final targetPosition = BoardService.calculateNextPosition(
      token.currentPosition,
      diceValue,
      token.color,
    );

    if (targetPosition != null) {
      final validationResult = MoveValidationService.validateMove(
        token: token,
        targetPosition: targetPosition,
        diceValue: diceValue,
        gameState: widget.gameState,
      );

      if (validationResult.isValid) {
        validMoves = [targetPosition];
      } else {
        validMoves = [];
      }
    } else {
      validMoves = [];
    }
  }

  Offset _getScreenPosition(Position position) {
    final x = position.x * cellSize + cellSize / 2;
    final y = position.y * cellSize + cellSize / 2;
    return Offset(x, y);
  }
}

/// Custom painter for the Ludo board
class LudoBoardPainter extends CustomPainter {
  final GameState gameState;
  final List<Position> validMoves;

  LudoBoardPainter({
    required this.gameState,
    required this.validMoves,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 15;
    
    // Draw background
    _drawBackground(canvas, size);
    
    // Draw grid
    _drawGrid(canvas, size, cellSize);
    
    // Draw home areas
    _drawHomeAreas(canvas, cellSize);
    
    // Draw main path
    _drawMainPath(canvas, cellSize);
    
    // Draw finish areas
    _drawFinishAreas(canvas, cellSize);
    
    // Draw safe positions
    _drawSafePositions(canvas, cellSize);
    
    // Draw center
    _drawCenter(canvas, size);
    
    // Draw valid move indicators
    _drawValidMoveIndicators(canvas, cellSize);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5F5F5)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawGrid(Canvas canvas, Size size, double cellSize) {
    final paint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (int i = 0; i <= 15; i++) {
      final x = i * cellSize;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (int i = 0; i <= 15; i++) {
      final y = i * cellSize;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawHomeAreas(Canvas canvas, double cellSize) {
    final homeColors = {
      PlayerColor.red: const Color(0xFFE53E3E),
      PlayerColor.blue: const Color(0xFF3182CE),
      PlayerColor.green: const Color(0xFF38A169),
      PlayerColor.yellow: const Color(0xFFD69E2E),
    };

    final homeAreas = {
      PlayerColor.red: Rect.fromLTWH(1 * cellSize, 10 * cellSize, 4 * cellSize, 4 * cellSize),
      PlayerColor.blue: Rect.fromLTWH(1 * cellSize, 1 * cellSize, 4 * cellSize, 4 * cellSize),
      PlayerColor.green: Rect.fromLTWH(10 * cellSize, 1 * cellSize, 4 * cellSize, 4 * cellSize),
      PlayerColor.yellow: Rect.fromLTWH(10 * cellSize, 10 * cellSize, 4 * cellSize, 4 * cellSize),
    };

    for (final color in PlayerColor.values) {
      final paint = Paint()
        ..color = homeColors[color]!.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = homeColors[color]!
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final rect = homeAreas[color]!;
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);
    }
  }

  void _drawMainPath(Canvas canvas, double cellSize) {
    final pathPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final mainPath = BoardService.getMainPath();
    
    for (final position in mainPath) {
      final rect = Rect.fromLTWH(
        position.x * cellSize,
        position.y * cellSize,
        cellSize,
        cellSize,
      );
      
      canvas.drawRect(rect, pathPaint);
      canvas.drawRect(rect, borderPaint);
    }
  }

  void _drawFinishAreas(Canvas canvas, double cellSize) {
    final finishColors = {
      PlayerColor.red: const Color(0xFFE53E3E),
      PlayerColor.blue: const Color(0xFF3182CE),
      PlayerColor.green: const Color(0xFF38A169),
      PlayerColor.yellow: const Color(0xFFD69E2E),
    };

    for (final color in PlayerColor.values) {
      final finishPositions = BoardService.getFinishPositions(color);
      final paint = Paint()
        ..color = finishColors[color]!.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      for (final position in finishPositions) {
        final rect = Rect.fromLTWH(
          position.x * cellSize,
          position.y * cellSize,
          cellSize,
          cellSize,
        );
        canvas.drawRect(rect, paint);
      }
    }
  }

  void _drawSafePositions(Canvas canvas, double cellSize) {
    final safePaint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final safePositions = BoardService.getSafePositions();
    
    for (final position in safePositions) {
      final center = Offset(
        position.x * cellSize + cellSize / 2,
        position.y * cellSize + cellSize / 2,
      );
      
      // Draw safe zone background
      canvas.drawCircle(center, cellSize * 0.4, safePaint);
      
      // Draw star icon
      _drawStar(canvas, center, cellSize * 0.2, starPaint);
    }
  }

  void _drawCenter(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    final centerPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw center circle
    canvas.drawCircle(center, size.width * 0.08, centerPaint);
    canvas.drawCircle(center, size.width * 0.08, borderPaint);
    
    // Draw crown icon
    _drawCrown(canvas, center, size.width * 0.04);
  }

  void _drawValidMoveIndicators(Canvas canvas, double cellSize) {
    final indicatorPaint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (final position in validMoves) {
      final center = Offset(
        position.x * cellSize + cellSize / 2,
        position.y * cellSize + cellSize / 2,
      );
      
      canvas.drawCircle(center, cellSize * 0.3, indicatorPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const numberOfPoints = 5;
    final angle = (3.14159 * 2) / numberOfPoints;
    
    for (int i = 0; i < numberOfPoints; i++) {
      final x = center.dx + radius * math.cos(i * angle - math.pi / 2);
      final y = center.dy + radius * math.sin(i * angle - math.pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCrown(Canvas canvas, Offset center, double size) {
    final crownPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx - size, center.dy + size / 2);
    path.lineTo(center.dx - size / 2, center.dy - size / 2);
    path.lineTo(center.dx, center.dy);
    path.lineTo(center.dx + size / 2, center.dy - size / 2);
    path.lineTo(center.dx + size, center.dy + size / 2);
    path.close();

    canvas.drawPath(path, crownPaint);
  }

  @override
  bool shouldRepaint(LudoBoardPainter oldDelegate) {
    return gameState != oldDelegate.gameState ||
           validMoves != oldDelegate.validMoves;
  }
}

