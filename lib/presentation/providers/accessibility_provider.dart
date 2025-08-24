import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/accessibility/accessibility_service.dart';
import '../../data/models/game_state.dart';
import '../../data/models/token.dart';
import '../../data/models/position.dart';

/// Provider for accessibility service
final accessibilityServiceProvider = Provider<AccessibilityService>((ref) {
  return AccessibilityService();
});

/// Provider for accessibility settings
final accessibilitySettingsProvider = StateNotifierProvider<AccessibilitySettingsNotifier, AccessibilitySettingsState>((ref) {
  return AccessibilitySettingsNotifier();
});

/// Accessibility settings state
class AccessibilitySettingsState {
  final AccessibilitySettings settings;
  final bool isLoading;
  final String? error;

  const AccessibilitySettingsState({
    required this.settings,
    this.isLoading = false,
    this.error,
  });

  AccessibilitySettingsState copyWith({
    AccessibilitySettings? settings,
    bool? isLoading,
    String? error,
  }) {
    return AccessibilitySettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Accessibility settings notifier
class AccessibilitySettingsNotifier extends StateNotifier<AccessibilitySettingsState> {
  static const String _prefsKey = 'accessibility_settings';

  AccessibilitySettingsNotifier() : super(AccessibilitySettingsState(
    settings: const AccessibilitySettings(),
  )) {
    _initialize();
  }

  /// Initialize accessibility settings
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      await AccessibilityService.initialize();
      await _loadSettings();
      
      state = state.copyWith(
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final settings = AccessibilitySettings(
      screenReaderEnabled: prefs.getBool('${_prefsKey}_screen_reader') ?? false,
      highContrastMode: prefs.getBool('${_prefsKey}_high_contrast') ?? false,
      largeTextMode: prefs.getBool('${_prefsKey}_large_text') ?? false,
      reducedMotion: prefs.getBool('${_prefsKey}_reduced_motion') ?? false,
      colorBlindSupport: prefs.getBool('${_prefsKey}_color_blind') ?? false,
      soundCuesEnabled: prefs.getBool('${_prefsKey}_sound_cues') ?? true,
      hapticFeedbackEnabled: prefs.getBool('${_prefsKey}_haptic') ?? true,
      alternativeInputEnabled: prefs.getBool('${_prefsKey}_alt_input') ?? false,
    );

    state = state.copyWith(settings: settings);
    await AccessibilityService.updateSettings(settings);
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = state.settings;
    
    await prefs.setBool('${_prefsKey}_screen_reader', settings.screenReaderEnabled);
    await prefs.setBool('${_prefsKey}_high_contrast', settings.highContrastMode);
    await prefs.setBool('${_prefsKey}_large_text', settings.largeTextMode);
    await prefs.setBool('${_prefsKey}_reduced_motion', settings.reducedMotion);
    await prefs.setBool('${_prefsKey}_color_blind', settings.colorBlindSupport);
    await prefs.setBool('${_prefsKey}_sound_cues', settings.soundCuesEnabled);
    await prefs.setBool('${_prefsKey}_haptic', settings.hapticFeedbackEnabled);
    await prefs.setBool('${_prefsKey}_alt_input', settings.alternativeInputEnabled);
  }

  /// Update specific setting
  Future<void> updateSetting(String key, bool value) async {
    AccessibilitySettings newSettings;
    
    switch (key) {
      case 'screenReader':
        newSettings = state.settings.copyWith(screenReaderEnabled: value);
        break;
      case 'highContrast':
        newSettings = state.settings.copyWith(highContrastMode: value);
        break;
      case 'largeText':
        newSettings = state.settings.copyWith(largeTextMode: value);
        break;
      case 'reducedMotion':
        newSettings = state.settings.copyWith(reducedMotion: value);
        break;
      case 'colorBlind':
        newSettings = state.settings.copyWith(colorBlindSupport: value);
        break;
      case 'soundCues':
        newSettings = state.settings.copyWith(soundCuesEnabled: value);
        break;
      case 'hapticFeedback':
        newSettings = state.settings.copyWith(hapticFeedbackEnabled: value);
        break;
      case 'alternativeInput':
        newSettings = state.settings.copyWith(alternativeInputEnabled: value);
        break;
      default:
        return;
    }

    state = state.copyWith(settings: newSettings);
    await AccessibilityService.updateSettings(newSettings);
    await _saveSettings();
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    const defaultSettings = AccessibilitySettings();
    state = state.copyWith(settings: defaultSettings);
    await AccessibilityService.updateSettings(defaultSettings);
    await _saveSettings();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for accessible colors
final accessibleColorsProvider = Provider<AccessibleColors>((ref) {
  final settings = ref.watch(accessibilitySettingsProvider).settings;
  return AccessibilityService.getAccessibleColors();
});

/// Provider for text scale factor
final textScaleFactorProvider = Provider<double>((ref) {
  final settings = ref.watch(accessibilitySettingsProvider).settings;
  return settings.largeTextMode ? 1.3 : 1.0;
});

/// Provider for reduced motion setting
final reducedMotionProvider = Provider<bool>((ref) {
  final settings = ref.watch(accessibilitySettingsProvider).settings;
  return settings.reducedMotion;
});

/// Provider for haptic feedback setting
final hapticFeedbackEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(accessibilitySettingsProvider).settings;
  return settings.hapticFeedbackEnabled;
});

/// Provider for accessibility actions
final accessibilityActionsProvider = Provider<AccessibilityActions>((ref) {
  return AccessibilityActions(ref);
});

/// Accessibility actions helper class
class AccessibilityActions {
  final Ref _ref;

  AccessibilityActions(this._ref);

  /// Announce game state change
  Future<void> announceGameState(GameState gameState) async {
    final settings = _ref.read(accessibilitySettingsProvider).settings;
    if (settings.screenReaderEnabled) {
      await AccessibilityService.announceGameState(gameState);
    }
  }

  /// Announce dice roll
  Future<void> announceDiceRoll(int value, String playerName) async {
    final settings = _ref.read(accessibilitySettingsProvider).settings;
    if (settings.screenReaderEnabled) {
      await AccessibilityService.announceDiceRoll(value, playerName);
    }
  }

  /// Announce token movement
  Future<void> announceTokenMovement(
    Token token,
    Position from,
    Position to,
    {String? additionalInfo}
  ) async {
    final settings = _ref.read(accessibilitySettingsProvider).settings;
    if (settings.screenReaderEnabled) {
      await AccessibilityService.announceTokenMovement(
        token, from, to,
        additionalInfo: additionalInfo,
      );
    }
  }

  /// Announce token capture
  Future<void> announceTokenCapture(
    Token capturedToken,
    Token capturingToken,
    Position position
  ) async {
    final settings = _ref.read(accessibilitySettingsProvider).settings;
    if (settings.screenReaderEnabled) {
      await AccessibilityService.announceTokenCapture(
        capturedToken, capturingToken, position,
      );
    }
  }

  /// Announce game end
  Future<void> announceGameEnd(GameState gameState) async {
    final settings = _ref.read(accessibilitySettingsProvider).settings;
    if (settings.screenReaderEnabled) {
      await AccessibilityService.announceGameEnd(gameState);
    }
  }

  /// Announce available moves
  Future<void> announceAvailableMoves(
    List<Position> validMoves,
    Token selectedToken
  ) async {
    final settings = _ref.read(accessibilitySettingsProvider).settings;
    if (settings.screenReaderEnabled) {
      await AccessibilityService.announceAvailableMoves(validMoves, selectedToken);
    }
  }

  /// Provide haptic feedback
  Future<void> hapticFeedback(HapticFeedbackType type) async {
    final settings = _ref.read(accessibilitySettingsProvider).settings;
    if (settings.hapticFeedbackEnabled) {
      await AccessibilityService.provideHapticFeedback(type);
    }
  }

  /// Announce error
  Future<void> announceError(String message) async {
    final settings = _ref.read(accessibilitySettingsProvider).settings;
    if (settings.screenReaderEnabled) {
      await AccessibilityService.announceError(message);
    }
  }

  /// Announce success
  Future<void> announceSuccess(String message) async {
    final settings = _ref.read(accessibilitySettingsProvider).settings;
    if (settings.screenReaderEnabled) {
      await AccessibilityService.announceSuccess(message);
    }
  }

  /// Get semantic label for position
  String getPositionSemanticLabel(Position position, {Token? token}) {
    return AccessibilityService.getPositionSemanticLabel(position, token: token);
  }

  /// Get semantic label for token
  String getTokenSemanticLabel(Token token) {
    return AccessibilityService.getTokenSemanticLabel(token);
  }

  /// Get interaction hint
  String getInteractionHint(String action, {String? context}) {
    return AccessibilityService.getInteractionHint(action, context: context);
  }
}

/// Provider for game accessibility helper
final gameAccessibilityProvider = Provider<GameAccessibilityHelper>((ref) {
  return GameAccessibilityHelper(ref);
});

/// Game accessibility helper for specific game interactions
class GameAccessibilityHelper {
  final Ref _ref;

  GameAccessibilityHelper(this._ref);

  /// Handle dice roll accessibility
  Future<void> handleDiceRollAccessibility(int diceValue, String playerName) async {
    final actions = _ref.read(accessibilityActionsProvider);
    
    // Haptic feedback for dice roll
    await actions.hapticFeedback(HapticFeedbackType.medium);
    
    // Announce result
    await actions.announceDiceRoll(diceValue, playerName);
  }

  /// Handle token selection accessibility
  Future<void> handleTokenSelectionAccessibility(Token token, List<Position> validMoves) async {
    final actions = _ref.read(accessibilityActionsProvider);
    
    // Haptic feedback for selection
    await actions.hapticFeedback(HapticFeedbackType.light);
    
    // Announce token selection and available moves
    await actions.announceAvailableMoves(validMoves, token);
  }

  /// Handle token movement accessibility
  Future<void> handleTokenMovementAccessibility(
    Token token,
    Position from,
    Position to,
    {bool isCapture = false, Token? capturedToken}
  ) async {
    final actions = _ref.read(accessibilityActionsProvider);
    
    // Stronger haptic for captures
    await actions.hapticFeedback(
      isCapture ? HapticFeedbackType.heavy : HapticFeedbackType.medium
    );
    
    if (isCapture && capturedToken != null) {
      await actions.announceTokenCapture(capturedToken, token, to);
    } else {
      await actions.announceTokenMovement(token, from, to);
    }
  }

  /// Handle turn change accessibility
  Future<void> handleTurnChangeAccessibility(GameState gameState) async {
    final actions = _ref.read(accessibilityActionsProvider);
    
    // Light haptic for turn change
    await actions.hapticFeedback(HapticFeedbackType.light);
    
    // Announce new turn
    await actions.announceGameState(gameState);
  }

  /// Handle game end accessibility
  Future<void> handleGameEndAccessibility(GameState gameState) async {
    final actions = _ref.read(accessibilityActionsProvider);
    
    // Strong haptic for game end
    await actions.hapticFeedback(HapticFeedbackType.heavy);
    
    // Announce game end
    await actions.announceGameEnd(gameState);
  }

  /// Handle error accessibility
  Future<void> handleErrorAccessibility(String errorMessage) async {
    final actions = _ref.read(accessibilityActionsProvider);
    
    // Double haptic for errors
    await actions.hapticFeedback(HapticFeedbackType.heavy);
    await Future.delayed(const Duration(milliseconds: 100));
    await actions.hapticFeedback(HapticFeedbackType.heavy);
    
    // Announce error
    await actions.announceError(errorMessage);
  }

  /// Get board navigation help
  String getBoardNavigationHelp() {
    return AccessibilityService.getBoardNavigationInstructions();
  }

  /// Get game controls help
  String getGameControlsHelp() {
    return AccessibilityService.getGameControlsInstructions();
  }
}

/// Provider for accessibility status
final accessibilityStatusProvider = Provider<AccessibilityStatus>((ref) {
  final settings = ref.watch(accessibilitySettingsProvider).settings;
  
  return AccessibilityStatus(
    isScreenReaderActive: settings.screenReaderEnabled,
    isHighContrastActive: settings.highContrastMode,
    isLargeTextActive: settings.largeTextMode,
    isReducedMotionActive: settings.reducedMotion,
    isColorBlindSupportActive: settings.colorBlindSupport,
    isSoundCuesActive: settings.soundCuesEnabled,
    isHapticFeedbackActive: settings.hapticFeedbackEnabled,
    isAlternativeInputActive: settings.alternativeInputEnabled,
  );
});

/// Accessibility status information
class AccessibilityStatus {
  final bool isScreenReaderActive;
  final bool isHighContrastActive;
  final bool isLargeTextActive;
  final bool isReducedMotionActive;
  final bool isColorBlindSupportActive;
  final bool isSoundCuesActive;
  final bool isHapticFeedbackActive;
  final bool isAlternativeInputActive;

  const AccessibilityStatus({
    required this.isScreenReaderActive,
    required this.isHighContrastActive,
    required this.isLargeTextActive,
    required this.isReducedMotionActive,
    required this.isColorBlindSupportActive,
    required this.isSoundCuesActive,
    required this.isHapticFeedbackActive,
    required this.isAlternativeInputActive,
  });

  /// Check if any accessibility features are active
  bool get hasActiveFeatures {
    return isScreenReaderActive ||
           isHighContrastActive ||
           isLargeTextActive ||
           isReducedMotionActive ||
           isColorBlindSupportActive ||
           !isSoundCuesActive ||
           !isHapticFeedbackActive ||
           isAlternativeInputActive;
  }

  /// Get count of active features
  int get activeFeatureCount {
    int count = 0;
    if (isScreenReaderActive) count++;
    if (isHighContrastActive) count++;
    if (isLargeTextActive) count++;
    if (isReducedMotionActive) count++;
    if (isColorBlindSupportActive) count++;
    if (!isSoundCuesActive) count++;
    if (!isHapticFeedbackActive) count++;
    if (isAlternativeInputActive) count++;
    return count;
  }
}