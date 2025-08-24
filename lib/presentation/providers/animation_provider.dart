import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/token.dart';
import '../../data/models/position.dart';
import '../../core/enums/game_enums.dart';
import '../../services/animation/animation_service.dart';

/// Provider for animation settings
final animationSettingsProvider = StateNotifierProvider<AnimationSettingsNotifier, AnimationSettings>((ref) {
  return AnimationSettingsNotifier();
});

/// Animation settings state
class AnimationSettings {
  final bool animationsEnabled;
  final double animationSpeed;
  final bool reducedMotion;
  final bool tokenMovementAnimations;
  final bool diceRollAnimations;
  final bool uiTransitions;
  final bool captureEffects;

  const AnimationSettings({
    this.animationsEnabled = true,
    this.animationSpeed = 1.0,
    this.reducedMotion = false,
    this.tokenMovementAnimations = true,
    this.diceRollAnimations = true,
    this.uiTransitions = true,
    this.captureEffects = true,
  });

  AnimationSettings copyWith({
    bool? animationsEnabled,
    double? animationSpeed,
    bool? reducedMotion,
    bool? tokenMovementAnimations,
    bool? diceRollAnimations,
    bool? uiTransitions,
    bool? captureEffects,
  }) {
    return AnimationSettings(
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      tokenMovementAnimations: tokenMovementAnimations ?? this.tokenMovementAnimations,
      diceRollAnimations: diceRollAnimations ?? this.diceRollAnimations,
      uiTransitions: uiTransitions ?? this.uiTransitions,
      captureEffects: captureEffects ?? this.captureEffects,
    );
  }

  /// Get adjusted duration based on speed setting
  Duration adjustDuration(Duration baseDuration) {
    if (!animationsEnabled || reducedMotion) {
      return const Duration(milliseconds: 50); // Very fast for accessibility
    }
    return Duration(
      milliseconds: (baseDuration.inMilliseconds / animationSpeed).round(),
    );
  }
}

/// Animation settings notifier
class AnimationSettingsNotifier extends StateNotifier<AnimationSettings> {
  AnimationSettingsNotifier() : super(const AnimationSettings());

  void updateAnimationsEnabled(bool enabled) {
    state = state.copyWith(animationsEnabled: enabled);
  }

  void updateAnimationSpeed(double speed) {
    state = state.copyWith(animationSpeed: speed.clamp(0.5, 2.0));
  }

  void updateReducedMotion(bool reduced) {
    state = state.copyWith(reducedMotion: reduced);
  }

  void updateTokenMovementAnimations(bool enabled) {
    state = state.copyWith(tokenMovementAnimations: enabled);
  }

  void updateDiceRollAnimations(bool enabled) {
    state = state.copyWith(diceRollAnimations: enabled);
  }

  void updateUiTransitions(bool enabled) {
    state = state.copyWith(uiTransitions: enabled);
  }

  void updateCaptureEffects(bool enabled) {
    state = state.copyWith(captureEffects: enabled);
  }
}

/// Provider for token animation state
final tokenAnimationProvider = StateNotifierProvider<TokenAnimationNotifier, TokenAnimationState>((ref) {
  return TokenAnimationNotifier();
});

/// Token animation state
class TokenAnimationState {
  final Map<String, TokenAnimationInfo> animatingTokens;
  final List<CaptureEffect> captureEffects;
  final List<TrailEffect> trailEffects;

  const TokenAnimationState({
    this.animatingTokens = const {},
    this.captureEffects = const [],
    this.trailEffects = const [],
  });

  TokenAnimationState copyWith({
    Map<String, TokenAnimationInfo>? animatingTokens,
    List<CaptureEffect>? captureEffects,
    List<TrailEffect>? trailEffects,
  }) {
    return TokenAnimationState(
      animatingTokens: animatingTokens ?? this.animatingTokens,
      captureEffects: captureEffects ?? this.captureEffects,
      trailEffects: trailEffects ?? this.trailEffects,
    );
  }
}

/// Token animation information
class TokenAnimationInfo {
  final String tokenId;
  final Position startPosition;
  final Position endPosition;
  final List<Position> path;
  final Duration duration;
  final DateTime startTime;
  final bool isMoving;

  const TokenAnimationInfo({
    required this.tokenId,
    required this.startPosition,
    required this.endPosition,
    this.path = const [],
    required this.duration,
    required this.startTime,
    this.isMoving = false,
  });

  TokenAnimationInfo copyWith({
    String? tokenId,
    Position? startPosition,
    Position? endPosition,
    List<Position>? path,
    Duration? duration,
    DateTime? startTime,
    bool? isMoving,
  }) {
    return TokenAnimationInfo(
      tokenId: tokenId ?? this.tokenId,
      startPosition: startPosition ?? this.startPosition,
      endPosition: endPosition ?? this.endPosition,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      isMoving: isMoving ?? this.isMoving,
    );
  }
}

/// Capture effect information
class CaptureEffect {
  final String id;
  final Position position;
  final PlayerColor color;
  final DateTime startTime;
  final Duration duration;

  const CaptureEffect({
    required this.id,
    required this.position,
    required this.color,
    required this.startTime,
    required this.duration,
  });
}

/// Trail effect information
class TrailEffect {
  final String id;
  final List<Position> path;
  final PlayerColor color;
  final DateTime startTime;
  final Duration duration;

  const TrailEffect({
    required this.id,
    required this.path,
    required this.color,
    required this.startTime,
    required this.duration,
  });
}

/// Token animation notifier
class TokenAnimationNotifier extends StateNotifier<TokenAnimationState> {
  TokenAnimationNotifier() : super(const TokenAnimationState());

  /// Start token movement animation
  Future<void> animateTokenMovement({
    required String tokenId,
    required Position from,
    required Position to,
    List<Position> path = const [],
    Duration? duration,
  }) async {
    final animationDuration = duration ?? AnimationService.defaultTokenMoveDuration;
    
    final animationInfo = TokenAnimationInfo(
      tokenId: tokenId,
      startPosition: from,
      endPosition: to,
      path: path,
      duration: animationDuration,
      startTime: DateTime.now(),
      isMoving: true,
    );

    // Update state with new animation
    final updatedAnimations = Map<String, TokenAnimationInfo>.from(state.animatingTokens);
    updatedAnimations[tokenId] = animationInfo;
    
    state = state.copyWith(animatingTokens: updatedAnimations);

    // Remove animation after completion
    Future.delayed(animationDuration, () {
      _removeTokenAnimation(tokenId);
    });
  }

  /// Stop token animation
  void stopTokenAnimation(String tokenId) {
    _removeTokenAnimation(tokenId);
  }

  void _removeTokenAnimation(String tokenId) {
    final updatedAnimations = Map<String, TokenAnimationInfo>.from(state.animatingTokens);
    updatedAnimations.remove(tokenId);
    state = state.copyWith(animatingTokens: updatedAnimations);
  }

  /// Add capture effect
  void addCaptureEffect({
    required Position position,
    required PlayerColor color,
    Duration? duration,
  }) {
    final effect = CaptureEffect(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: position,
      color: color,
      startTime: DateTime.now(),
      duration: duration ?? AnimationService.captureAnimationDuration,
    );

    final updatedEffects = List<CaptureEffect>.from(state.captureEffects);
    updatedEffects.add(effect);
    state = state.copyWith(captureEffects: updatedEffects);

    // Remove effect after completion
    Future.delayed(effect.duration, () {
      _removeCaptureEffect(effect.id);
    });
  }

  void _removeCaptureEffect(String effectId) {
    final updatedEffects = state.captureEffects
        .where((effect) => effect.id != effectId)
        .toList();
    state = state.copyWith(captureEffects: updatedEffects);
  }

  /// Add trail effect
  void addTrailEffect({
    required List<Position> path,
    required PlayerColor color,
    Duration? duration,
  }) {
    final effect = TrailEffect(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: path,
      color: color,
      startTime: DateTime.now(),
      duration: duration ?? const Duration(milliseconds: 1000),
    );

    final updatedEffects = List<TrailEffect>.from(state.trailEffects);
    updatedEffects.add(effect);
    state = state.copyWith(trailEffects: updatedEffects);

    // Remove effect after completion
    Future.delayed(effect.duration, () {
      _removeTrailEffect(effect.id);
    });
  }

  void _removeTrailEffect(String effectId) {
    final updatedEffects = state.trailEffects
        .where((effect) => effect.id != effectId)
        .toList();
    state = state.copyWith(trailEffects: updatedEffects);
  }

  /// Clear all animations and effects
  void clearAll() {
    state = const TokenAnimationState();
  }

  /// Check if token is currently animating
  bool isTokenAnimating(String tokenId) {
    return state.animatingTokens.containsKey(tokenId);
  }

  /// Get token animation info
  TokenAnimationInfo? getTokenAnimationInfo(String tokenId) {
    return state.animatingTokens[tokenId];
  }
}

/// Provider for dice animation state
final diceAnimationProvider = StateNotifierProvider<DiceAnimationNotifier, DiceAnimationState>((ref) {
  return DiceAnimationNotifier();
});

/// Dice animation state
class DiceAnimationState {
  final bool isRolling;
  final int currentValue;
  final List<int> rollHistory;
  final DateTime? lastRollTime;

  const DiceAnimationState({
    this.isRolling = false,
    this.currentValue = 1,
    this.rollHistory = const [],
    this.lastRollTime,
  });

  DiceAnimationState copyWith({
    bool? isRolling,
    int? currentValue,
    List<int>? rollHistory,
    DateTime? lastRollTime,
  }) {
    return DiceAnimationState(
      isRolling: isRolling ?? this.isRolling,
      currentValue: currentValue ?? this.currentValue,
      rollHistory: rollHistory ?? this.rollHistory,
      lastRollTime: lastRollTime ?? this.lastRollTime,
    );
  }
}

/// Dice animation notifier
class DiceAnimationNotifier extends StateNotifier<DiceAnimationState> {
  DiceAnimationNotifier() : super(const DiceAnimationState());

  /// Start dice roll animation
  Future<void> rollDice(int finalValue) async {
    // Start rolling
    state = state.copyWith(
      isRolling: true,
      lastRollTime: DateTime.now(),
    );

    // Wait for animation duration
    await Future.delayed(AnimationService.diceRollDuration);

    // Update with final value and add to history
    final updatedHistory = List<int>.from(state.rollHistory);
    updatedHistory.add(finalValue);
    
    // Keep only last 5 rolls
    if (updatedHistory.length > 5) {
      updatedHistory.removeAt(0);
    }

    state = state.copyWith(
      isRolling: false,
      currentValue: finalValue,
      rollHistory: updatedHistory,
    );
  }

  /// Reset dice state
  void reset() {
    state = const DiceAnimationState();
  }
}

/// Provider for UI animation state
final uiAnimationProvider = StateNotifierProvider<UIAnimationNotifier, UIAnimationState>((ref) {
  return UIAnimationNotifier();
});

/// UI animation state
class UIAnimationState {
  final bool isTransitioning;
  final String? currentScreen;
  final Map<String, bool> elementAnimations;

  const UIAnimationState({
    this.isTransitioning = false,
    this.currentScreen,
    this.elementAnimations = const {},
  });

  UIAnimationState copyWith({
    bool? isTransitioning,
    String? currentScreen,
    Map<String, bool>? elementAnimations,
  }) {
    return UIAnimationState(
      isTransitioning: isTransitioning ?? this.isTransitioning,
      currentScreen: currentScreen ?? this.currentScreen,
      elementAnimations: elementAnimations ?? this.elementAnimations,
    );
  }
}

/// UI animation notifier
class UIAnimationNotifier extends StateNotifier<UIAnimationState> {
  UIAnimationNotifier() : super(const UIAnimationState());

  /// Start screen transition
  void startScreenTransition(String screenName) {
    state = state.copyWith(
      isTransitioning: true,
      currentScreen: screenName,
    );
  }

  /// End screen transition
  void endScreenTransition() {
    state = state.copyWith(isTransitioning: false);
  }

  /// Start element animation
  void startElementAnimation(String elementId) {
    final updatedAnimations = Map<String, bool>.from(state.elementAnimations);
    updatedAnimations[elementId] = true;
    state = state.copyWith(elementAnimations: updatedAnimations);
  }

  /// End element animation
  void endElementAnimation(String elementId) {
    final updatedAnimations = Map<String, bool>.from(state.elementAnimations);
    updatedAnimations[elementId] = false;
    state = state.copyWith(elementAnimations: updatedAnimations);
  }

  /// Check if element is animating
  bool isElementAnimating(String elementId) {
    return state.elementAnimations[elementId] ?? false;
  }
}

/// Provider for animation actions
final animationActionsProvider = Provider<AnimationActions>((ref) {
  return AnimationActions(ref);
});

/// Animation actions helper class
class AnimationActions {
  final Ref _ref;

  AnimationActions(this._ref);

  /// Animate token movement with settings consideration
  Future<void> animateTokenMove({
    required String tokenId,
    required Position from,
    required Position to,
    List<Position> path = const [],
  }) async {
    final settings = _ref.read(animationSettingsProvider);
    
    if (!settings.animationsEnabled || !settings.tokenMovementAnimations) {
      return;
    }

    final duration = settings.adjustDuration(AnimationService.defaultTokenMoveDuration);
    
    await _ref.read(tokenAnimationProvider.notifier).animateTokenMovement(
      tokenId: tokenId,
      from: from,
      to: to,
      path: path,
      duration: duration,
    );
  }

  /// Animate dice roll with settings consideration
  Future<void> animateDiceRoll(int finalValue) async {
    final settings = _ref.read(animationSettingsProvider);
    
    if (!settings.animationsEnabled || !settings.diceRollAnimations) {
      return;
    }

    await _ref.read(diceAnimationProvider.notifier).rollDice(finalValue);
  }

  /// Add capture effect with settings consideration
  void addCaptureEffect({
    required Position position,
    required PlayerColor color,
  }) {
    final settings = _ref.read(animationSettingsProvider);
    
    if (!settings.animationsEnabled || !settings.captureEffects) {
      return;
    }

    _ref.read(tokenAnimationProvider.notifier).addCaptureEffect(
      position: position,
      color: color,
    );
  }

  /// Add trail effect with settings consideration
  void addTrailEffect({
    required List<Position> path,
    required PlayerColor color,
  }) {
    final settings = _ref.read(animationSettingsProvider);
    
    if (!settings.animationsEnabled) {
      return;
    }

    _ref.read(tokenAnimationProvider.notifier).addTrailEffect(
      path: path,
      color: color,
    );
  }

  /// Check if any animations are currently running
  bool get hasActiveAnimations {
    final tokenState = _ref.read(tokenAnimationProvider);
    final diceState = _ref.read(diceAnimationProvider);
    final uiState = _ref.read(uiAnimationProvider);

    return tokenState.animatingTokens.isNotEmpty ||
           tokenState.captureEffects.isNotEmpty ||
           tokenState.trailEffects.isNotEmpty ||
           diceState.isRolling ||
           uiState.isTransitioning;
  }
}