import 'package:flutter/material.dart';
import '../../../data/models/token.dart';
import '../../../data/models/position.dart';
import '../../../core/enums/game_enums.dart';
import '../../../services/animation/animation_service.dart';

/// Animated token widget that handles smooth movements and visual effects
class AnimatedToken extends StatefulWidget {
  final Token token;
  final Position targetPosition;
  final double size;
  final bool isSelected;
  final bool isHighlighted;
  final bool canMove;
  final VoidCallback? onTap;
  final VoidCallback? onAnimationComplete;
  final List<Position>? movementPath;
  final Duration? animationDuration;

  const AnimatedToken({
    super.key,
    required this.token,
    required this.targetPosition,
    this.size = 24.0,
    this.isSelected = false,
    this.isHighlighted = false,
    this.canMove = false,
    this.onTap,
    this.onAnimationComplete,
    this.movementPath,
    this.animationDuration,
  });

  @override
  State<AnimatedToken> createState() => _AnimatedTokenState();
}

class _AnimatedTokenState extends State<AnimatedToken>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late AnimationController _shakeController;

  late Animation<Offset> _moveAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<Offset> _shakeAnimation;

  Position? _lastPosition;
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _lastPosition = widget.token.currentPosition;
  }

  void _initializeAnimations() {
    // Movement animation controller
    _moveController = AnimationController(
      duration: widget.animationDuration ?? AnimationService.defaultTokenMoveDuration,
      vsync: this,
    );

    // Scale animation for selection
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Pulse animation for highlighting
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Bounce animation for landing
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Shake animation for invalid moves
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _setupAnimations();
    _setupListeners();
  }

  void _setupAnimations() {
    // Scale animation
    _scaleAnimation = AnimationService.createScaleAnimation(
      controller: _scaleController,
      fromScale: 1.0,
      toScale: 1.2,
    );

    // Pulse animation
    _pulseAnimation = AnimationService.createPulseAnimation(
      controller: _pulseController,
      minScale: 0.95,
      maxScale: 1.05,
    );

    // Bounce animation
    _bounceAnimation = AnimationService.createBounceAnimation(
      controller: _bounceController,
      bounceHeight: 8.0,
    );

    // Shake animation
    _shakeAnimation = AnimationService.createShakeAnimation(
      controller: _shakeController,
      shakeDistance: 3.0,
    );
  }

  void _setupListeners() {
    _moveController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isMoving = false;
        widget.onAnimationComplete?.call();
        
        // Trigger bounce animation when landing
        _bounceController.forward().then((_) {
          _bounceController.reset();
        });
      }
    });

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.isHighlighted) {
          _pulseController.reverse().then((_) {
            if (mounted && widget.isHighlighted) {
              _pulseController.forward();
            }
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedToken oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle position changes
    if (widget.token.currentPosition != _lastPosition) {
      _animateToNewPosition();
    }

    // Handle selection changes
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _scaleController.forward();
      } else {
        _scaleController.reverse();
      }
    }

    // Handle highlighting changes
    if (widget.isHighlighted != oldWidget.isHighlighted) {
      if (widget.isHighlighted) {
        _pulseController.forward();
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  void _animateToNewPosition() {
    if (_isMoving) return;

    _isMoving = true;
    final startPosition = _lastPosition ?? widget.token.currentPosition;
    
    _moveAnimation = AnimationService.createTokenMoveAnimation(
      controller: _moveController,
      startPosition: startPosition,
      endPosition: widget.targetPosition,
      pathPositions: widget.movementPath ?? [],
    );

    _lastPosition = widget.targetPosition;
    _moveController.forward(from: 0.0);
  }

  void _playShakeAnimation() {
    if (_shakeController.isAnimating) return;
    _shakeController.forward().then((_) {
      _shakeController.reset();
    });
  }

  @override
  void dispose() {
    _moveController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _moveController,
        _scaleController,
        _pulseController,
        _bounceController,
        _shakeController,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: _moveController.isAnimating
              ? _moveAnimation.value
              : Offset(widget.targetPosition.x.toDouble(), widget.targetPosition.y.toDouble()),
          child: Transform.translate(
            offset: _shakeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _bounceAnimation.value),
              child: Transform.scale(
                scale: _scaleAnimation.value * _pulseAnimation.value,
                child: GestureDetector(
                  onTap: widget.canMove ? widget.onTap : _playShakeAnimation,
                  child: _buildToken(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToken() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getTokenColor(),
        border: Border.all(
          color: _getBorderColor(),
          width: _getBorderWidth(),
        ),
        boxShadow: _getTokenShadow(),
      ),
      child: widget.isSelected || widget.isHighlighted
          ? Icon(
              Icons.circle,
              size: widget.size * 0.6,
              color: Colors.white.withOpacity(0.8),
            )
          : null,
    );
  }

  Color _getTokenColor() {
    switch (widget.token.color) {
      case PlayerColor.red:
        return Colors.red.shade600;
      case PlayerColor.blue:
        return Colors.blue.shade600;
      case PlayerColor.green:
        return Colors.green.shade600;
      case PlayerColor.yellow:
        return Colors.yellow.shade600;
    }
  }

  Color _getBorderColor() {
    if (widget.isSelected) {
      return Colors.white;
    } else if (widget.isHighlighted) {
      return Colors.amber;
    } else if (widget.canMove) {
      return Colors.white.withOpacity(0.8);
    } else {
      return Colors.black.withOpacity(0.3);
    }
  }

  double _getBorderWidth() {
    if (widget.isSelected || widget.isHighlighted) {
      return 3.0;
    } else if (widget.canMove) {
      return 2.0;
    } else {
      return 1.0;
    }
  }

  List<BoxShadow> _getTokenShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: widget.isSelected ? 8.0 : 4.0,
        offset: Offset(0, widget.isSelected ? 4.0 : 2.0),
      ),
      if (widget.isHighlighted)
        BoxShadow(
          color: Colors.amber.withOpacity(0.5),
          blurRadius: 12.0,
          spreadRadius: 2.0,
        ),
    ];
  }
}

/// Token trail effect for showing movement path
class TokenTrail extends StatefulWidget {
  final List<Position> path;
  final PlayerColor color;
  final Duration animationDuration;

  const TokenTrail({
    super.key,
    required this.path,
    required this.color,
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<TokenTrail> createState() => _TokenTrailState();
}

class _TokenTrailState extends State<TokenTrail>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: TokenTrailPainter(
            path: widget.path,
            color: _getTrailColor(),
            progress: _animation.value,
          ),
        );
      },
    );
  }

  Color _getTrailColor() {
    switch (widget.color) {
      case PlayerColor.red:
        return Colors.red.withOpacity(0.6);
      case PlayerColor.blue:
        return Colors.blue.withOpacity(0.6);
      case PlayerColor.green:
        return Colors.green.withOpacity(0.6);
      case PlayerColor.yellow:
        return Colors.yellow.withOpacity(0.6);
    }
  }
}

/// Custom painter for token trail
class TokenTrailPainter extends CustomPainter {
  final List<Position> path;
  final Color color;
  final double progress;

  TokenTrailPainter({
    required this.path,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final totalLength = path.length - 1;
    final visibleLength = totalLength * progress;

    for (int i = 0; i < visibleLength.floor() && i < path.length - 1; i++) {
      final start = Offset(path[i].x.toDouble(), path[i].y.toDouble());
      final end = Offset(path[i + 1].x.toDouble(), path[i + 1].y.toDouble());
      
      // Fade effect for trail segments
      final segmentOpacity = (1.0 - (i / totalLength)).clamp(0.0, 1.0);
      paint.color = color.withOpacity(segmentOpacity);
      
      canvas.drawLine(start, end, paint);
    }

    // Draw partial segment if needed
    final remainingProgress = visibleLength - visibleLength.floor();
    if (remainingProgress > 0 && visibleLength.floor() < path.length - 1) {
      final i = visibleLength.floor();
      final start = Offset(path[i].x.toDouble(), path[i].y.toDouble());
      final end = Offset(path[i + 1].x.toDouble(), path[i + 1].y.toDouble());
      final partialEnd = Offset.lerp(start, end, remainingProgress)!;
      
      final segmentOpacity = (1.0 - (i / totalLength)).clamp(0.0, 1.0);
      paint.color = color.withOpacity(segmentOpacity);
      
      canvas.drawLine(start, partialEnd, paint);
    }
  }

  @override
  bool shouldRepaint(TokenTrailPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.path != path;
  }
}

/// Token capture effect
class TokenCaptureEffect extends StatefulWidget {
  final Position position;
  final PlayerColor color;
  final VoidCallback? onComplete;

  const TokenCaptureEffect({
    super.key,
    required this.position,
    required this.color,
    this.onComplete,
  });

  @override
  State<TokenCaptureEffect> createState() => _TokenCaptureEffectState();
}

class _TokenCaptureEffectState extends State<TokenCaptureEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationService.captureAnimationDuration,
      vsync: this,
    );

    _scaleAnimation = AnimationService.createCaptureAnimation(
      controller: _controller,
    );

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0),
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
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
        return Positioned(
          left: widget.position.x.toDouble() - 15,
          top: widget.position.y.toDouble() - 15,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getCaptureColor(),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCaptureColor() {
    switch (widget.color) {
      case PlayerColor.red:
        return Colors.red.shade700;
      case PlayerColor.blue:
        return Colors.blue.shade700;
      case PlayerColor.green:
        return Colors.green.shade700;
      case PlayerColor.yellow:
        return Colors.yellow.shade700;
    }
  }
}