import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../services/animation/animation_service.dart';

/// Animated dice widget with realistic rolling animations
class AnimatedDice extends StatefulWidget {
  final int value;
  final double size;
  final bool isRolling;
  final VoidCallback? onTap;
  final VoidCallback? onRollComplete;
  final Duration rollDuration;
  final bool enabled;

  const AnimatedDice({
    super.key,
    required this.value,
    this.size = 60.0,
    this.isRolling = false,
    this.onTap,
    this.onRollComplete,
    this.rollDuration = const Duration(milliseconds: 1200),
    this.enabled = true,
  });

  @override
  State<AnimatedDice> createState() => _AnimatedDiceState();
}

class _AnimatedDiceState extends State<AnimatedDice>
    with TickerProviderStateMixin {
  late AnimationController _rollController;
  late AnimationController _bounceController;
  late AnimationController _glowController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  int _displayValue = 1;
  bool _wasRolling = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _displayValue = widget.value;
  }

  void _initializeAnimations() {
    // Roll animation controller
    _rollController = AnimationController(
      duration: widget.rollDuration,
      vsync: this,
    );

    // Bounce animation controller
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Glow animation controller
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _setupAnimations();
    _setupListeners();
  }

  void _setupAnimations() {
    // Rotation animation
    _rotationAnimation = AnimationService.createDiceRollAnimation(
      controller: _rollController,
      rotations: 4,
    );

    // Bounce animation
    _bounceAnimation = AnimationService.createBounceAnimation(
      controller: _bounceController,
      bounceHeight: 8.0,
    );

    // Scale animation during roll
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.2, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 20,
      ),
    ]).animate(_rollController);

    // Glow animation
    _glowAnimation = AnimationService.createPulseAnimation(
      controller: _glowController,
      minScale: 0.8,
      maxScale: 1.2,
    );
  }

  void _setupListeners() {
    _rollController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onRollComplete?.call();
        _bounceController.forward().then((_) {
          _bounceController.reset();
        });
      }
    });

    // Update display value during roll
    _rollController.addListener(() {
      if (_rollController.isAnimating) {
        // Show random values during roll for visual effect
        if (_rollController.value < 0.8) {
          setState(() {
            _displayValue = math.Random().nextInt(6) + 1;
          });
        } else {
          // Show final value in last 20% of animation
          if (_displayValue != widget.value) {
            setState(() {
              _displayValue = widget.value;
            });
          }
        }
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedDice oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle rolling state changes
    if (widget.isRolling != oldWidget.isRolling) {
      if (widget.isRolling && !_rollController.isAnimating) {
        _startRollAnimation();
      }
    }

    // Handle value changes when not rolling
    if (widget.value != oldWidget.value && !widget.isRolling) {
      setState(() {
        _displayValue = widget.value;
      });
    }

    // Handle enabled state changes
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
        _glowController.reset();
      }
    }
  }

  void _startRollAnimation() {
    _rollController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _rollController.dispose();
    _bounceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled && !widget.isRolling ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rollController,
          _bounceController,
          _glowController,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size * 0.15),
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      if (widget.enabled)
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3 * _glowAnimation.value),
                          blurRadius: 16 * _glowAnimation.value,
                          spreadRadius: 4 * _glowAnimation.value,
                        ),
                    ],
                  ),
                  child: _buildDiceFace(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiceFace() {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: DiceFacePainter(
        value: _displayValue,
        dotColor: Colors.black87,
        isRolling: widget.isRolling,
      ),
    );
  }
}

/// Custom painter for dice face
class DiceFacePainter extends CustomPainter {
  final int value;
  final Color dotColor;
  final bool isRolling;

  DiceFacePainter({
    required this.value,
    required this.dotColor,
    this.isRolling = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.filled;

    final dotRadius = size.width * 0.08;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final offset = size.width * 0.25;

    // Add slight blur effect when rolling
    if (isRolling) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
    }

    switch (value) {
      case 1:
        _drawDot(canvas, paint, centerX, centerY, dotRadius);
        break;
      case 2:
        _drawDot(canvas, paint, centerX - offset, centerY - offset, dotRadius);
        _drawDot(canvas, paint, centerX + offset, centerY + offset, dotRadius);
        break;
      case 3:
        _drawDot(canvas, paint, centerX - offset, centerY - offset, dotRadius);
        _drawDot(canvas, paint, centerX, centerY, dotRadius);
        _drawDot(canvas, paint, centerX + offset, centerY + offset, dotRadius);
        break;
      case 4:
        _drawDot(canvas, paint, centerX - offset, centerY - offset, dotRadius);
        _drawDot(canvas, paint, centerX + offset, centerY - offset, dotRadius);
        _drawDot(canvas, paint, centerX - offset, centerY + offset, dotRadius);
        _drawDot(canvas, paint, centerX + offset, centerY + offset, dotRadius);
        break;
      case 5:
        _drawDot(canvas, paint, centerX - offset, centerY - offset, dotRadius);
        _drawDot(canvas, paint, centerX + offset, centerY - offset, dotRadius);
        _drawDot(canvas, paint, centerX, centerY, dotRadius);
        _drawDot(canvas, paint, centerX - offset, centerY + offset, dotRadius);
        _drawDot(canvas, paint, centerX + offset, centerY + offset, dotRadius);
        break;
      case 6:
        _drawDot(canvas, paint, centerX - offset, centerY - offset, dotRadius);
        _drawDot(canvas, paint, centerX + offset, centerY - offset, dotRadius);
        _drawDot(canvas, paint, centerX - offset, centerY, dotRadius);
        _drawDot(canvas, paint, centerX + offset, centerY, dotRadius);
        _drawDot(canvas, paint, centerX - offset, centerY + offset, dotRadius);
        _drawDot(canvas, paint, centerX + offset, centerY + offset, dotRadius);
        break;
    }
  }

  void _drawDot(Canvas canvas, Paint paint, double x, double y, double radius) {
    canvas.drawCircle(Offset(x, y), radius, paint);
  }

  @override
  bool shouldRepaint(DiceFacePainter oldDelegate) {
    return oldDelegate.value != value ||
           oldDelegate.dotColor != dotColor ||
           oldDelegate.isRolling != isRolling;
  }
}

/// Compact animated dice for smaller spaces
class CompactAnimatedDice extends StatelessWidget {
  final int value;
  final double size;
  final bool isRolling;
  final VoidCallback? onTap;

  const CompactAnimatedDice({
    super.key,
    required this.value,
    this.size = 32.0,
    this.isRolling = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.15),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isRolling
            ? const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Center(
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Dice trail effect for showing previous rolls
class DiceTrail extends StatefulWidget {
  final List<int> previousRolls;
  final double diceSize;

  const DiceTrail({
    super.key,
    required this.previousRolls,
    this.diceSize = 24.0,
  });

  @override
  State<DiceTrail> createState() => _DiceTrailState();
}

class _DiceTrailState extends State<DiceTrail>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _setupAnimations();
    _controller.forward();
  }

  void _setupAnimations() {
    _fadeAnimations = List.generate(widget.previousRolls.length, (index) {
      final startTime = (index * 0.1).clamp(0.0, 0.8);
      final endTime = (startTime + 0.3).clamp(0.0, 1.0);
      
      return Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startTime, endTime, curve: Curves.easeOut),
        ),
      );
    });
  }

  @override
  void didUpdateWidget(DiceTrail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.previousRolls != oldWidget.previousRolls) {
      _setupAnimations();
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: widget.previousRolls.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;
            
            return Opacity(
              opacity: index < _fadeAnimations.length 
                  ? _fadeAnimations[index].value 
                  : 0.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: CompactAnimatedDice(
                  value: value,
                  size: widget.diceSize,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}