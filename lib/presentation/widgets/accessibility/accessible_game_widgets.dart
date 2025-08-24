import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/token.dart';
import '../../../data/models/position.dart';
import '../../../core/enums/game_enums.dart';
import '../../providers/accessibility_provider.dart';

/// Accessible token widget with semantic labels and announcements
class AccessibleToken extends ConsumerWidget {
  final Token token;
  final Position position;
  final bool isSelected;
  final bool canMove;
  final List<Position> validMoves;
  final VoidCallback? onTap;
  final double size;

  const AccessibleToken({
    super.key,
    required this.token,
    required this.position,
    this.isSelected = false,
    this.canMove = false,
    this.validMoves = const [],
    this.onTap,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityActions = ref.watch(accessibilityActionsProvider);
    final accessibleColors = ref.watch(accessibleColorsProvider);
    
    return Semantics(
      label: accessibilityActions.getTokenSemanticLabel(token),
      hint: canMove 
          ? accessibilityActions.getInteractionHint('select token and view available moves')
          : 'This token cannot move',
      enabled: canMove,
      selected: isSelected,
      onTap: canMove ? () => _handleTokenTap(ref) : null,
      child: GestureDetector(
        onTap: canMove ? () => _handleTokenTap(ref) : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accessibleColors.playerColors[token.color],
            border: Border.all(
              color: isSelected ? Colors.white : Colors.black.withOpacity(0.3),
              width: isSelected ? 3.0 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isSelected || canMove
              ? Icon(
                  canMove ? Icons.touch_app : Icons.circle,
                  size: size * 0.6,
                  color: Colors.white.withOpacity(0.8),
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _handleTokenTap(WidgetRef ref) async {
    final accessibilityActions = ref.read(accessibilityActionsProvider);
    
    // Provide haptic feedback
    await accessibilityActions.hapticFeedback(HapticFeedbackType.light);
    
    // Announce token selection and available moves
    await accessibilityActions.announceAvailableMoves(validMoves, token);
    
    // Call the original onTap callback
    onTap?.call();
  }
}

/// Accessible board position widget
class AccessibleBoardPosition extends ConsumerWidget {
  final Position position;
  final Token? occupyingToken;
  final bool isValidMove;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final double size;

  const AccessibleBoardPosition({
    super.key,
    required this.position,
    this.occupyingToken,
    this.isValidMove = false,
    this.isHighlighted = false,
    this.onTap,
    this.size = 25.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityActions = ref.watch(accessibilityActionsProvider);
    final accessibleColors = ref.watch(accessibleColorsProvider);
    
    return Semantics(
      label: accessibilityActions.getPositionSemanticLabel(position, token: occupyingToken),
      hint: isValidMove 
          ? accessibilityActions.getInteractionHint('move token to this position')
          : occupyingToken != null 
              ? 'Position occupied'
              : 'Position not available for move',
      enabled: isValidMove,
      button: isValidMove,
      onTap: isValidMove ? () => _handlePositionTap(ref) : null,
      child: GestureDetector(
        onTap: isValidMove ? () => _handlePositionTap(ref) : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _getPositionColor(accessibleColors),
            border: Border.all(
              color: isHighlighted ? Colors.blue : Colors.black.withOpacity(0.2),
              width: isHighlighted ? 2.0 : 0.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: _buildPositionContent(),
        ),
      ),
    );
  }

  Widget _buildPositionContent() {
    if (isValidMove) {
      return Center(
        child: Container(
          width: size * 0.4,
          height: size * 0.4,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.my_location,
            size: size * 0.3,
            color: Colors.white,
          ),
        ),
      );
    }
    
    if (occupyingToken != null) {
      return AccessibleToken(
        token: occupyingToken!,
        position: position,
        size: size * 0.8,
      );
    }
    
    return const SizedBox.shrink();
  }

  Color _getPositionColor(AccessibleColors accessibleColors) {
    switch (position.type) {
      case PositionType.home:
        return accessibleColors.playerColors[position.ownerColor] ?? Colors.grey.shade200;
      case PositionType.start:
        return accessibleColors.playerColors[position.ownerColor]?.withOpacity(0.3) ?? Colors.grey.shade300;
      case PositionType.path:
        return Colors.grey.shade100;
      case PositionType.finish:
        return accessibleColors.playerColors[position.ownerColor]?.withOpacity(0.5) ?? Colors.grey.shade200;
      case PositionType.safe:
        return Colors.green.shade100;
    }
  }

  Future<void> _handlePositionTap(WidgetRef ref) async {
    final accessibilityActions = ref.read(accessibilityActionsProvider);
    
    // Provide haptic feedback
    await accessibilityActions.hapticFeedback(HapticFeedbackType.medium);
    
    // Announce the move
    await accessibilityActions.announceSuccess('Position selected');
    
    // Call the original onTap callback
    onTap?.call();
  }
}

/// Accessible dice widget with detailed announcements
class AccessibleDice extends ConsumerWidget {
  final int value;
  final bool isRolling;
  final bool canRoll;
  final VoidCallback? onRoll;
  final double size;

  const AccessibleDice({
    super.key,
    required this.value,
    this.isRolling = false,
    this.canRoll = true,
    this.onRoll,
    this.size = 60.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityActions = ref.watch(accessibilityActionsProvider);
    final textScaleFactor = ref.watch(textScaleFactorProvider);
    
    return Semantics(
      label: isRolling 
          ? 'Dice is rolling'
          : 'Dice showing $value',
      hint: canRoll 
          ? accessibilityActions.getInteractionHint('roll dice')
          : 'Cannot roll dice right now',
      enabled: canRoll && !isRolling,
      button: canRoll && !isRolling,
      onTap: canRoll && !isRolling ? () => _handleDiceRoll(ref) : null,
      child: GestureDetector(
        onTap: canRoll && !isRolling ? () => _handleDiceRoll(ref) : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 0.15),
            border: Border.all(
              color: canRoll ? Colors.blue : Colors.grey,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
              if (canRoll)
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: isRolling
              ? Center(
                  child: SizedBox(
                    width: size * 0.4,
                    height: size * 0.4,
                    child: const CircularProgressIndicator(),
                  ),
                )
              : Center(
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: size * 0.4 * textScaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _handleDiceRoll(WidgetRef ref) async {
    final accessibilityActions = ref.read(accessibilityActionsProvider);
    
    // Provide haptic feedback
    await accessibilityActions.hapticFeedback(HapticFeedbackType.heavy);
    
    // Announce dice roll start
    await accessibilityActions.announceSuccess('Rolling dice');
    
    // Call the original onRoll callback
    onRoll?.call();
  }
}

/// Accessible game board with navigation support
class AccessibleGameBoard extends ConsumerStatefulWidget {
  final List<Token> tokens;
  final Position? selectedPosition;
  final List<Position> validMoves;
  final Function(Position)? onPositionTap;
  final Function(Token)? onTokenTap;
  final double boardSize;

  const AccessibleGameBoard({
    super.key,
    required this.tokens,
    this.selectedPosition,
    this.validMoves = const [],
    this.onPositionTap,
    this.onTokenTap,
    this.boardSize = 350.0,
  });

  @override
  ConsumerState<AccessibleGameBoard> createState() => _AccessibleGameBoardState();
}

class _AccessibleGameBoardState extends ConsumerState<AccessibleGameBoard> {
  Position? _focusedPosition;
  final FocusNode _boardFocusNode = FocusNode();

  @override
  void dispose() {
    _boardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityActions = ref.watch(accessibilityActionsProvider);
    final gameHelper = ref.watch(gameAccessibilityProvider);
    
    return Semantics(
      label: 'Ludo game board',
      hint: gameHelper.getBoardNavigationHelp(),
      child: Focus(
        focusNode: _boardFocusNode,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: () => _boardFocusNode.requestFocus(),
          child: Container(
            width: widget.boardSize,
            height: widget.boardSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              painter: AccessibleBoardPainter(
                tokens: widget.tokens,
                selectedPosition: widget.selectedPosition,
                validMoves: widget.validMoves,
                focusedPosition: _focusedPosition,
                accessibleColors: ref.watch(accessibleColorsProvider),
              ),
              child: _buildInteractiveLayer(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveLayer() {
    // Build invisible interactive layer for screen readers
    return Stack(
      children: [
        // This would contain positioned widgets for each interactive element
        // For simplicity, showing a basic structure
        ...widget.tokens.map((token) => _buildTokenWidget(token)),
        ...widget.validMoves.map((position) => _buildPositionWidget(position)),
      ],
    );
  }

  Widget _buildTokenWidget(Token token) {
    final position = token.currentPosition;
    final cellSize = widget.boardSize / 15;
    
    return Positioned(
      left: position.x * cellSize,
      top: position.y * cellSize,
      child: AccessibleToken(
        token: token,
        position: position,
        isSelected: widget.selectedPosition == position,
        canMove: widget.validMoves.isNotEmpty,
        validMoves: widget.validMoves,
        onTap: () => widget.onTokenTap?.call(token),
        size: cellSize * 0.8,
      ),
    );
  }

  Widget _buildPositionWidget(Position position) {
    final cellSize = widget.boardSize / 15;
    
    return Positioned(
      left: position.x * cellSize,
      top: position.y * cellSize,
      child: AccessibleBoardPosition(
        position: position,
        isValidMove: widget.validMoves.contains(position),
        isHighlighted: _focusedPosition == position,
        onTap: () => widget.onPositionTap?.call(position),
        size: cellSize,
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Handle keyboard navigation for accessibility
    // This would implement arrow key navigation, enter to select, etc.
    return KeyEventResult.ignored;
  }
}

/// Accessible board painter with high contrast support
class AccessibleBoardPainter extends CustomPainter {
  final List<Token> tokens;
  final Position? selectedPosition;
  final List<Position> validMoves;
  final Position? focusedPosition;
  final AccessibleColors accessibleColors;

  const AccessibleBoardPainter({
    required this.tokens,
    this.selectedPosition,
    required this.validMoves,
    this.focusedPosition,
    required this.accessibleColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 15;
    
    // Draw high contrast board
    _drawAccessibleBoard(canvas, size, cellSize);
    
    // Draw focus indicators
    if (focusedPosition != null) {
      _drawFocusIndicator(canvas, focusedPosition!, cellSize);
    }
    
    // Draw selection indicators
    if (selectedPosition != null) {
      _drawSelectionIndicator(canvas, selectedPosition!, cellSize);
    }
    
    // Draw valid move indicators
    for (final position in validMoves) {
      _drawValidMoveIndicator(canvas, position, cellSize);
    }
  }

  void _drawAccessibleBoard(Canvas canvas, Size size, double cellSize) {
    final paint = Paint();
    
    // Draw background
    paint.color = accessibleColors.backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw grid with high contrast
    paint
      ..color = accessibleColors.textColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i <= 15; i++) {
      // Vertical lines
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        paint,
      );
      // Horizontal lines
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        paint,
      );
    }
    
    // Draw home areas with accessible colors
    _drawHomeAreas(canvas, size, cellSize);
  }

  void _drawHomeAreas(Canvas canvas, Size size, double cellSize) {
    final paint = Paint();
    final homeSize = cellSize * 6;
    
    // Red home
    paint.color = accessibleColors.playerColors[PlayerColor.red]?.withOpacity(0.3) ?? Colors.red.shade100;
    canvas.drawRect(Rect.fromLTWH(0, 0, homeSize, homeSize), paint);
    
    // Blue home
    paint.color = accessibleColors.playerColors[PlayerColor.blue]?.withOpacity(0.3) ?? Colors.blue.shade100;
    canvas.drawRect(Rect.fromLTWH(size.width - homeSize, 0, homeSize, homeSize), paint);
    
    // Green home
    paint.color = accessibleColors.playerColors[PlayerColor.green]?.withOpacity(0.3) ?? Colors.green.shade100;
    canvas.drawRect(Rect.fromLTWH(0, size.height - homeSize, homeSize, homeSize), paint);
    
    // Yellow home
    paint.color = accessibleColors.playerColors[PlayerColor.yellow]?.withOpacity(0.3) ?? Colors.yellow.shade100;
    canvas.drawRect(Rect.fromLTWH(size.width - homeSize, size.height - homeSize, homeSize, homeSize), paint);
  }

  void _drawFocusIndicator(Canvas canvas, Position position, double cellSize) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    final rect = Rect.fromLTWH(
      position.x * cellSize,
      position.y * cellSize,
      cellSize,
      cellSize,
    );
    
    canvas.drawRect(rect, paint);
  }

  void _drawSelectionIndicator(Canvas canvas, Position position, double cellSize) {
    final paint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;
    
    final center = Offset(
      position.x * cellSize + cellSize / 2,
      position.y * cellSize + cellSize / 2,
    );
    
    canvas.drawCircle(center, cellSize / 4, paint);
  }

  void _drawValidMoveIndicator(Canvas canvas, Position position, double cellSize) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    final center = Offset(
      position.x * cellSize + cellSize / 2,
      position.y * cellSize + cellSize / 2,
    );
    
    canvas.drawCircle(center, cellSize / 6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! AccessibleBoardPainter ||
           oldDelegate.tokens != tokens ||
           oldDelegate.selectedPosition != selectedPosition ||
           oldDelegate.validMoves != validMoves ||
           oldDelegate.focusedPosition != focusedPosition;
  }
}