import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/token.dart';
import '../../../core/enums/game_enums.dart';

/// Widget representing a game token/piece
class TokenWidget extends StatefulWidget {
  final Token token;
  final double size;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final bool showAnimation;

  const TokenWidget({
    super.key,
    required this.token,
    this.size = 24,
    this.onTap,
    this.isHighlighted = false,
    this.showAnimation = true,
  });

  @override
  State<TokenWidget> createState() => _TokenWidgetState();
}

class _TokenWidgetState extends State<TokenWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(TokenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _animationController.forward();
    } else if (!widget.isHighlighted && oldWidget.isHighlighted) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.token.isSelected 
                ? widget.token.getScaleFactor() 
                : (widget.isHighlighted ? _scaleAnimation.value : 1.0),
            child: Transform.rotate(
              angle: widget.isHighlighted ? _rotationAnimation.value : 0.0,
              child: _buildToken(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToken() {
    final tokenColor = _getTokenColor();
    
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: tokenColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: _getBorderColor(),
          width: widget.token.isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: widget.token.isSelected ? 6 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildTokenContent(),
    );
  }

  Widget _buildTokenContent() {
    // Show different content based on token state
    if (widget.token.hasFinished) {
      return Icon(
        Icons.star,
        color: Colors.white,
        size: widget.size * 0.6,
      );
    }
    
    if (widget.token.isInSafeZone) {
      return Icon(
        Icons.shield,
        color: Colors.white,
        size: widget.size * 0.5,
      );
    }
    
    // Default token appearance
    return Center(
      child: Container(
        width: widget.size * 0.4,
        height: widget.size * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Color _getTokenColor() {
    switch (widget.token.color) {
      case PlayerColor.red:
        return const Color(0xFFE53E3E);
      case PlayerColor.blue:
        return const Color(0xFF3182CE);
      case PlayerColor.green:
        return const Color(0xFF38A169);
      case PlayerColor.yellow:
        return const Color(0xFFD69E2E);
    }
  }

  Color _getBorderColor() {
    if (widget.token.isSelected) {
      return Colors.white;
    }
    if (widget.isHighlighted) {
      return Colors.amber;
    }
    return Colors.black54;
  }
}

/// Widget for showing multiple tokens stacked
class TokenStackWidget extends StatelessWidget {
  final List<Token> tokens;
  final double size;
  final VoidCallback? onTap;

  const TokenStackWidget({
    super.key,
    required this.tokens,
    this.size = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) return const SizedBox.shrink();
    if (tokens.length == 1) {
      return TokenWidget(
        token: tokens.first,
        size: size,
        onTap: onTap,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + (tokens.length - 1) * 4,
        height: size + (tokens.length - 1) * 4,
        child: Stack(
          children: tokens.asMap().entries.map((entry) {
            final index = entry.key;
            final token = entry.value;
            return Positioned(
              left: index * 4.0,
              top: index * 4.0,
              child: TokenWidget(
                token: token,
                size: size,
                showAnimation: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Widget for token in home area
class HomeTokenWidget extends StatelessWidget {
  final Token token;
  final double size;
  final VoidCallback? onTap;
  final bool canMove;

  const HomeTokenWidget({
    super.key,
    required this.token,
    this.size = 30,
    this.onTap,
    this.canMove = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canMove ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _getTokenColor().withOpacity(canMove ? 1.0 : 0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: canMove ? Colors.white : Colors.grey,
            width: 2,
          ),
          boxShadow: canMove ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: canMove
            ? const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 16,
              )
            : null,
      ),
    ).animate(target: canMove ? 1 : 0)
      .scale(duration: 200.ms)
      .shimmer(duration: canMove ? 1000.ms : 0.ms);
  }

  Color _getTokenColor() {
    switch (token.color) {
      case PlayerColor.red:
        return const Color(0xFFE53E3E);
      case PlayerColor.blue:
        return const Color(0xFF3182CE);
      case PlayerColor.green:
        return const Color(0xFF38A169);
      case PlayerColor.yellow:
        return const Color(0xFFD69E2E);
    }
  }
}

/// Widget for finished tokens
class FinishedTokenWidget extends StatelessWidget {
  final Token token;
  final double size;
  final int position; // Position in finish area (0-5)

  const FinishedTokenWidget({
    super.key,
    required this.token,
    this.size = 20,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getTokenColor(),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.emoji_events,
        color: Colors.white,
        size: size * 0.6,
      ),
    ).animate()
      .scale(delay: Duration(milliseconds: position * 100))
      .shimmer(delay: Duration(milliseconds: position * 100));
  }

  Color _getTokenColor() {
    switch (token.color) {
      case PlayerColor.red:
        return const Color(0xFFE53E3E);
      case PlayerColor.blue:
        return const Color(0xFF3182CE);
      case PlayerColor.green:
        return const Color(0xFF38A169);
      case PlayerColor.yellow:
        return const Color(0xFFD69E2E);
    }
  }
}