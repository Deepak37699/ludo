import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../data/models/position.dart';
import '../../data/models/token.dart';
import '../../core/enums/game_enums.dart';

/// Animation service for handling all game animations
class AnimationService {
  static const Duration defaultTokenMoveDuration = Duration(milliseconds: 800);
  static const Duration diceRollDuration = Duration(milliseconds: 1200);
  static const Duration captureAnimationDuration = Duration(milliseconds: 600);
  static const Duration uiTransitionDuration = Duration(milliseconds: 300);

  /// Create token movement animation
  static Animation<Offset> createTokenMoveAnimation({
    required AnimationController controller,
    required Position startPosition,
    required Position endPosition,
    required List<Position> pathPositions,
    Curve curve = Curves.easeInOutCubic,
  }) {
    if (pathPositions.isEmpty) {
      // Direct movement
      return Tween<Offset>(
        begin: Offset(startPosition.x.toDouble(), startPosition.y.toDouble()),
        end: Offset(endPosition.x.toDouble(), endPosition.y.toDouble()),
      ).animate(CurvedAnimation(
        parent: controller,
        curve: curve,
      ));
    }

    // Path-based movement with multiple waypoints
    return _createPathAnimation(
      controller: controller,
      pathPositions: pathPositions,
      curve: curve,
    );
  }

  /// Create path-based animation for complex token movements
  static Animation<Offset> _createPathAnimation({
    required AnimationController controller,
    required List<Position> pathPositions,
    Curve curve = Curves.easeInOutCubic,
  }) {
    return TweenSequence<Offset>(
      pathPositions.asMap().entries.map((entry) {
        int index = entry.key;
        Position position = entry.value;
        
        if (index == 0) return TweenSequenceItem<Offset>(
          tween: ConstantTween<Offset>(
            Offset(position.x.toDouble(), position.y.toDouble())
          ),
          weight: 0.1,
        );

        Position prevPosition = pathPositions[index - 1];
        double weight = 1.0 / (pathPositions.length - 1);
        
        return TweenSequenceItem<Offset>(
          tween: Tween<Offset>(
            begin: Offset(prevPosition.x.toDouble(), prevPosition.y.toDouble()),
            end: Offset(position.x.toDouble(), position.y.toDouble()),
          ).chain(CurveTween(curve: curve)),
          weight: weight,
        );
      }).toList(),
    ).animate(controller);
  }

  /// Create bounce animation for token landing
  static Animation<double> createBounceAnimation({
    required AnimationController controller,
    double bounceHeight = 10.0,
  }) {
    return TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: -bounceHeight)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -bounceHeight, end: 0.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 70,
      ),
    ]).animate(controller);
  }

  /// Create scale animation for token selection
  static Animation<double> createScaleAnimation({
    required AnimationController controller,
    double fromScale = 1.0,
    double toScale = 1.2,
    Curve curve = Curves.elasticOut,
  }) {
    return Tween<double>(
      begin: fromScale,
      end: toScale,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Create rotation animation for dice roll
  static Animation<double> createDiceRollAnimation({
    required AnimationController controller,
    int rotations = 3,
  }) {
    return Tween<double>(
      begin: 0.0,
      end: rotations * 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    ));
  }

  /// Create shake animation for invalid moves
  static Animation<Offset> createShakeAnimation({
    required AnimationController controller,
    double shakeDistance = 5.0,
  }) {
    return TweenSequence<Offset>([
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: Offset(shakeDistance, 0),
        ),
        weight: 25,
      ),
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(
          begin: Offset(shakeDistance, 0),
          end: Offset(-shakeDistance, 0),
        ),
        weight: 25,
      ),
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(
          begin: Offset(-shakeDistance, 0),
          end: Offset(shakeDistance, 0),
        ),
        weight: 25,
      ),
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(
          begin: Offset(shakeDistance, 0),
          end: Offset.zero,
        ),
        weight: 25,
      ),
    ]).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticInOut,
    ));
  }

  /// Create fade animation for UI transitions
  static Animation<double> createFadeAnimation({
    required AnimationController controller,
    double from = 0.0,
    double to = 1.0,
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<double>(
      begin: from,
      end: to,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Create slide animation for UI transitions
  static Animation<Offset> createSlideAnimation({
    required AnimationController controller,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    Curve curve = Curves.easeInOutCubic,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Create capture effect animation
  static Animation<double> createCaptureAnimation({
    required AnimationController controller,
  }) {
    return TweenSequence<double>([
      // Expand
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      // Flash
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.5, end: 0.8)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      // Shrink and fade
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.8, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(controller);
  }

  /// Create pulse animation for highlighted elements
  static Animation<double> createPulseAnimation({
    required AnimationController controller,
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: maxScale)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: maxScale, end: minScale)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(controller);
  }

  /// Create staggered list animation
  static List<Animation<Offset>> createStaggeredSlideAnimation({
    required AnimationController controller,
    required int itemCount,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Offset begin = const Offset(0.0, 1.0),
    Offset end = Offset.zero,
  }) {
    final animations = <Animation<Offset>>[];
    final totalDuration = controller.duration!;
    final itemDuration = Duration(
      milliseconds: totalDuration.inMilliseconds - 
          (staggerDelay.inMilliseconds * (itemCount - 1))
    );

    for (int i = 0; i < itemCount; i++) {
      final startTime = (staggerDelay.inMilliseconds * i) / totalDuration.inMilliseconds;
      final endTime = startTime + (itemDuration.inMilliseconds / totalDuration.inMilliseconds);

      animations.add(
        Tween<Offset>(
          begin: begin,
          end: end,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Interval(startTime, endTime.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
        ))
      );
    }

    return animations;
  }

  /// Create number counter animation
  static Animation<int> createCounterAnimation({
    required AnimationController controller,
    required int from,
    required int to,
  }) {
    return IntTween(
      begin: from,
      end: to,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }

  /// Create progress bar animation
  static Animation<double> createProgressAnimation({
    required AnimationController controller,
    double from = 0.0,
    double to = 1.0,
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<double>(
      begin: from,
      end: to,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }
}

/// Animation configuration class
class AnimationConfig {
  final Duration duration;
  final Curve curve;
  final bool repeat;
  final bool reverse;

  const AnimationConfig({
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.repeat = false,
    this.reverse = false,
  });

  static const AnimationConfig fast = AnimationConfig(
    duration: Duration(milliseconds: 150),
    curve: Curves.easeOut,
  );

  static const AnimationConfig normal = AnimationConfig(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );

  static const AnimationConfig slow = AnimationConfig(
    duration: Duration(milliseconds: 600),
    curve: Curves.easeInOutCubic,
  );

  static const AnimationConfig bounce = AnimationConfig(
    duration: Duration(milliseconds: 400),
    curve: Curves.bounceOut,
  );

  static const AnimationConfig elastic = AnimationConfig(
    duration: Duration(milliseconds: 500),
    curve: Curves.elasticOut,
  );
}

/// Animation state tracker
class AnimationStateTracker {
  final Map<String, AnimationController> _controllers = {};
  final Map<String, bool> _animationStates = {};

  /// Register an animation controller
  void registerController(String id, AnimationController controller) {
    _controllers[id] = controller;
    _animationStates[id] = false;
  }

  /// Start animation
  Future<void> startAnimation(String id) async {
    final controller = _controllers[id];
    if (controller != null && !_animationStates[id]!) {
      _animationStates[id] = true;
      await controller.forward();
      _animationStates[id] = false;
    }
  }

  /// Reverse animation
  Future<void> reverseAnimation(String id) async {
    final controller = _controllers[id];
    if (controller != null && !_animationStates[id]!) {
      _animationStates[id] = true;
      await controller.reverse();
      _animationStates[id] = false;
    }
  }

  /// Reset animation
  void resetAnimation(String id) {
    final controller = _controllers[id];
    if (controller != null) {
      controller.reset();
      _animationStates[id] = false;
    }
  }

  /// Check if animation is running
  bool isAnimating(String id) {
    return _animationStates[id] ?? false;
  }

  /// Dispose all controllers
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _animationStates.clear();
  }
}

/// Pre-built animation presets
class AnimationPresets {
  /// Token movement animation preset
  static Future<void> animateTokenMove({
    required AnimationController controller,
    required Position from,
    required Position to,
    required VoidCallback onComplete,
    List<Position>? path,
  }) async {
    controller.duration = AnimationService.defaultTokenMoveDuration;
    await controller.forward();
    onComplete();
  }

  /// Dice roll animation preset
  static Future<void> animateDiceRoll({
    required AnimationController controller,
    required VoidCallback onComplete,
  }) async {
    controller.duration = AnimationService.diceRollDuration;
    await controller.forward();
    onComplete();
  }

  /// Capture animation preset
  static Future<void> animateCapture({
    required AnimationController controller,
    required VoidCallback onComplete,
  }) async {
    controller.duration = AnimationService.captureAnimationDuration;
    await controller.forward();
    onComplete();
  }

  /// UI transition animation preset
  static Future<void> animateUITransition({
    required AnimationController controller,
    required VoidCallback onComplete,
  }) async {
    controller.duration = AnimationService.uiTransitionDuration;
    await controller.forward();
    onComplete();
  }
}