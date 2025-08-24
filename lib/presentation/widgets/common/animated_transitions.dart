import 'package:flutter/material.dart';
import '../../../services/animation/animation_service.dart';

/// Page transition animations for smooth navigation
class AnimatedPageTransition extends StatefulWidget {
  final Widget child;
  final PageTransitionType type;
  final Duration duration;
  final Curve curve;

  const AnimatedPageTransition({
    super.key,
    required this.child,
    this.type = PageTransitionType.slideFromRight,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<AnimatedPageTransition> createState() => _AnimatedPageTransitionState();
}

class _AnimatedPageTransitionState extends State<AnimatedPageTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _setupAnimations();
    _controller.forward();
  }

  void _setupAnimations() {
    switch (widget.type) {
      case PageTransitionType.slideFromRight:
        _slideAnimation = AnimationService.createSlideAnimation(
          controller: _controller,
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
          curve: widget.curve,
        );
        break;
      case PageTransitionType.slideFromLeft:
        _slideAnimation = AnimationService.createSlideAnimation(
          controller: _controller,
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
          curve: widget.curve,
        );
        break;
      case PageTransitionType.slideFromBottom:
        _slideAnimation = AnimationService.createSlideAnimation(
          controller: _controller,
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
          curve: widget.curve,
        );
        break;
      case PageTransitionType.slideFromTop:
        _slideAnimation = AnimationService.createSlideAnimation(
          controller: _controller,
          begin: const Offset(0.0, -1.0),
          end: Offset.zero,
          curve: widget.curve,
        );
        break;
      case PageTransitionType.fade:
        _fadeAnimation = AnimationService.createFadeAnimation(
          controller: _controller,
          curve: widget.curve,
        );
        break;
      case PageTransitionType.scale:
        _scaleAnimation = AnimationService.createScaleAnimation(
          controller: _controller,
          fromScale: 0.0,
          toScale: 1.0,
          curve: widget.curve,
        );
        break;
      case PageTransitionType.fadeAndSlide:
        _slideAnimation = AnimationService.createSlideAnimation(
          controller: _controller,
          begin: const Offset(0.0, 0.3),
          end: Offset.zero,
          curve: widget.curve,
        );
        _fadeAnimation = AnimationService.createFadeAnimation(
          controller: _controller,
          curve: widget.curve,
        );
        break;
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
        Widget result = widget.child;

        // Apply slide transition
        if (_slideAnimation != null) {
          result = SlideTransition(
            position: _slideAnimation,
            child: result,
          );
        }

        // Apply fade transition
        if (_fadeAnimation != null) {
          result = FadeTransition(
            opacity: _fadeAnimation,
            child: result,
          );
        }

        // Apply scale transition
        if (_scaleAnimation != null) {
          result = ScaleTransition(
            scale: _scaleAnimation,
            child: result,
          );
        }

        return result;
      },
    );
  }
}

/// Types of page transitions
enum PageTransitionType {
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  slideFromTop,
  fade,
  scale,
  fadeAndSlide,
}

/// Staggered list animation for smooth list item appearances
class StaggeredListAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Curve curve;
  final Axis scrollDirection;

  const StaggeredListAnimation({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
    this.scrollDirection = Axis.vertical,
  });

  @override
  State<StaggeredListAnimation> createState() => _StaggeredListAnimationState();
}

class _StaggeredListAnimationState extends State<StaggeredListAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.itemDuration + 
          (widget.staggerDelay * (widget.children.length - 1)),
      vsync: this,
    );
    _setupAnimations();
    _controller.forward();
  }

  void _setupAnimations() {
    _slideAnimations = AnimationService.createStaggeredSlideAnimation(
      controller: _controller,
      itemCount: widget.children.length,
      staggerDelay: widget.staggerDelay,
      begin: widget.scrollDirection == Axis.vertical 
          ? const Offset(0.0, 1.0) 
          : const Offset(1.0, 0.0),
      end: Offset.zero,
    );

    _fadeAnimations = List.generate(widget.children.length, (index) {
      final startTime = (widget.staggerDelay.inMilliseconds * index) / 
          _controller.duration!.inMilliseconds;
      final endTime = (startTime + 
          (widget.itemDuration.inMilliseconds / _controller.duration!.inMilliseconds))
          .clamp(0.0, 1.0);

      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startTime, endTime, curve: widget.curve),
        ),
      );
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
        return widget.scrollDirection == Axis.vertical
            ? Column(
                children: _buildAnimatedChildren(),
              )
            : Row(
                children: _buildAnimatedChildren(),
              );
      },
    );
  }

  List<Widget> _buildAnimatedChildren() {
    return widget.children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;

      return SlideTransition(
        position: _slideAnimations[index],
        child: FadeTransition(
          opacity: _fadeAnimations[index],
          child: child,
        ),
      );
    }).toList();
  }
}

/// Animated card widget with hover and tap effects
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final double elevation;
  final double hoverElevation;
  final BorderRadius? borderRadius;
  final Color? color;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 200),
    this.elevation = 2.0,
    this.hoverElevation = 8.0,
    this.borderRadius,
    this.color,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.hoverElevation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool hovering) {
    setState(() {
      _isHovered = hovering;
    });
    if (hovering && !_isPressed) {
      _controller.forward();
    } else if (!hovering && !_isPressed) {
      _controller.reverse();
    }
  }

  void _handleTapDown() {
    setState(() {
      _isPressed = true;
    });
    _controller.forward();
  }

  void _handleTapUp() {
    setState(() {
      _isPressed = false;
    });
    if (!_isHovered) {
      _controller.reverse();
    }
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    if (!_isHovered) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => _handleHover(true),
          onExit: (_) => _handleHover(false),
          child: GestureDetector(
            onTapDown: (_) => _handleTapDown(),
            onTapUp: (_) => _handleTapUp(),
            onTapCancel: _handleTapCancel,
            child: Transform.scale(
              scale: _isPressed ? _scaleAnimation.value : 1.0,
              child: Card(
                elevation: _elevationAnimation.value,
                borderOnForeground: false,
                color: widget.color,
                shape: RoundedRectangleBorder(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Animated counter for displaying changing numbers
class AnimatedCounter extends StatefulWidget {
  final int value;
  final Duration duration;
  final TextStyle? textStyle;
  final String prefix;
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 500),
    this.textStyle,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _previousValue = widget.value;
    _animation = IntTween(begin: _previousValue, end: widget.value)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _previousValue = oldWidget.value;
      _animation = IntTween(begin: _previousValue, end: widget.value)
          .animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
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
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix}${_animation.value}${widget.suffix}',
          style: widget.textStyle,
        );
      },
    );
  }
}

/// Animated progress bar with smooth transitions
class AnimatedProgressBar extends StatefulWidget {
  final double progress;
  final Duration duration;
  final Color? backgroundColor;
  final Color? valueColor;
  final double height;
  final BorderRadius? borderRadius;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.duration = const Duration(milliseconds: 500),
    this.backgroundColor,
    this.valueColor,
    this.height = 8.0,
    this.borderRadius,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _previousProgress = widget.progress;
    _animation = Tween<double>(begin: _previousProgress, end: widget.progress)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _previousProgress = oldWidget.progress;
      _animation = Tween<double>(begin: _previousProgress, end: widget.progress)
          .animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
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
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.grey.shade300,
            borderRadius: widget.borderRadius ?? 
                BorderRadius.circular(widget.height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: widget.valueColor ?? theme.primaryColor,
                borderRadius: widget.borderRadius ?? 
                    BorderRadius.circular(widget.height / 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom route transition builder
class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final PageTransitionType transitionType;
  final Duration transitionDuration;

  CustomPageRoute({
    required this.child,
    this.transitionType = PageTransitionType.slideFromRight,
    this.transitionDuration = const Duration(milliseconds: 300),
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: transitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(animation, child, transitionType);
          },
        );

  static Widget _buildTransition(
    Animation<double> animation,
    Widget child,
    PageTransitionType type,
  ) {
    switch (type) {
      case PageTransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      case PageTransitionType.slideFromLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      default:
        return child;
    }
  }
}