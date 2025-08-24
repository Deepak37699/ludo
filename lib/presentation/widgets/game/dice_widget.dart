import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animated dice widget for the Ludo game
class DiceWidget extends StatefulWidget {
  final int value;
  final VoidCallback? onTap;
  final bool isRolling;
  final double size;
  final Color? backgroundColor;
  final Color? dotColor;
  final bool isEnabled;

  const DiceWidget({
    super.key,
    required this.value,
    this.onTap,
    this.isRolling = false,
    this.size = 80,
    this.backgroundColor,
    this.dotColor,
    this.isEnabled = true,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with TickerProviderStateMixin {
  late AnimationController _rollController;
  late AnimationController _scaleController;
  
  @override
  void initState() {
    super.initState();
    _rollController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _startRolling();
    } else if (!widget.isRolling && oldWidget.isRolling) {
      _stopRolling();
    }
  }

  void _startRolling() {
    _rollController.repeat();
    _scaleController.forward();
  }

  void _stopRolling() {
    _rollController.stop();
    _rollController.reset();
    _scaleController.reverse();
  }

  @override
  void dispose() {
    _rollController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? Colors.white;
    final dotColor = widget.dotColor ?? theme.primaryColor;

    return GestureDetector(
      onTap: widget.isEnabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rollController, _scaleController]),
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_scaleController.value * 0.1),
            child: Transform.rotate(
              angle: _rollController.value * 2 * 3.14159,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: widget.isRolling
                    ? _buildRollingDice(dotColor)
                    : _buildStaticDice(widget.value, dotColor),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRollingDice(Color dotColor) {
    return Center(
      child: Icon(
        Icons.casino,
        size: widget.size * 0.5,
        color: dotColor.withOpacity(0.7),
      ),
    );
  }

  Widget _buildStaticDice(int value, Color dotColor) {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: DicePainter(value: value, dotColor: dotColor),
    );
  }
}

/// Custom painter for drawing dice dots
class DicePainter extends CustomPainter {
  final int value;
  final Color dotColor;

  DicePainter({required this.value, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final double dotRadius = size.width * 0.08;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double offsetX = size.width * 0.25;
    final double offsetY = size.height * 0.25;

    switch (value) {
      case 1:
        _drawDot(canvas, paint, centerX, centerY, dotRadius);
        break;
      case 2:
        _drawDot(canvas, paint, centerX - offsetX, centerY - offsetY, dotRadius);
        _drawDot(canvas, paint, centerX + offsetX, centerY + offsetY, dotRadius);
        break;
      case 3:
        _drawDot(canvas, paint, centerX - offsetX, centerY - offsetY, dotRadius);
        _drawDot(canvas, paint, centerX, centerY, dotRadius);
        _drawDot(canvas, paint, centerX + offsetX, centerY + offsetY, dotRadius);
        break;
      case 4:
        _drawDot(canvas, paint, centerX - offsetX, centerY - offsetY, dotRadius);
        _drawDot(canvas, paint, centerX + offsetX, centerY - offsetY, dotRadius);
        _drawDot(canvas, paint, centerX - offsetX, centerY + offsetY, dotRadius);
        _drawDot(canvas, paint, centerX + offsetX, centerY + offsetY, dotRadius);
        break;
      case 5:
        _drawDot(canvas, paint, centerX - offsetX, centerY - offsetY, dotRadius);
        _drawDot(canvas, paint, centerX + offsetX, centerY - offsetY, dotRadius);
        _drawDot(canvas, paint, centerX, centerY, dotRadius);
        _drawDot(canvas, paint, centerX - offsetX, centerY + offsetY, dotRadius);
        _drawDot(canvas, paint, centerX + offsetX, centerY + offsetY, dotRadius);
        break;
      case 6:
        _drawDot(canvas, paint, centerX - offsetX, centerY - offsetY, dotRadius);
        _drawDot(canvas, paint, centerX + offsetX, centerY - offsetY, dotRadius);
        _drawDot(canvas, paint, centerX - offsetX, centerY, dotRadius);
        _drawDot(canvas, paint, centerX + offsetX, centerY, dotRadius);
        _drawDot(canvas, paint, centerX - offsetX, centerY + offsetY, dotRadius);
        _drawDot(canvas, paint, centerX + offsetX, centerY + offsetY, dotRadius);
        break;
    }
  }

  void _drawDot(Canvas canvas, Paint paint, double x, double y, double radius) {
    canvas.drawCircle(Offset(x, y), radius, paint);
  }

  @override
  bool shouldRepaint(DicePainter oldDelegate) {
    return value != oldDelegate.value || dotColor != oldDelegate.dotColor;
  }
}

/// Dice roll button widget
class DiceRollButton extends StatelessWidget {
  final int? lastRoll;
  final bool isRolling;
  final bool canRoll;
  final VoidCallback? onRoll;
  final String? message;

  const DiceRollButton({
    super.key,
    this.lastRoll,
    this.isRolling = false,
    this.canRoll = true,
    this.onRoll,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        DiceWidget(
          value: lastRoll ?? 1,
          isRolling: isRolling,
          onTap: canRoll && !isRolling ? onRoll : null,
          isEnabled: canRoll && !isRolling,
          size: 100,
        ),
        
        const SizedBox(height: 12),
        
        Text(
          isRolling 
              ? 'Rolling...' 
              : canRoll 
                  ? 'Tap to Roll'
                  : 'Wait for turn',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: canRoll ? theme.primaryColor : theme.disabledColor,
          ),
        ),
        
        if (lastRoll != null && !isRolling) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getRollColor(lastRoll!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Rolled $lastRoll',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getRollColor(int roll) {
    switch (roll) {
      case 6:
        return Colors.green;
      case 5:
        return Colors.blue;
      case 4:
        return Colors.orange;
      case 3:
        return Colors.purple;
      case 2:
        return Colors.red;
      case 1:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}