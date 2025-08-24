import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import '../../data/models/position.dart';
import '../../data/models/token.dart';
import '../../data/models/game_state.dart';
import '../../core/enums/game_enums.dart';

/// Accessibility service providing inclusive gaming features
class AccessibilityService {
  static const Duration _announcementDelay = Duration(milliseconds: 500);
  static bool _isInitialized = false;
  static AccessibilitySettings _settings = const AccessibilitySettings();

  /// Initialize accessibility service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isInitialized = true;
    await _loadSettings();
    await _setupSystemAccessibility();
  }

  /// Load accessibility settings
  static Future<void> _loadSettings() async {
    // Load from storage - simplified for now
    _settings = const AccessibilitySettings(
      screenReaderEnabled: true,
      highContrastMode: false,
      largeTextMode: false,
      reducedMotion: false,
      colorBlindSupport: false,
      soundCuesEnabled: true,
      hapticFeedbackEnabled: true,
      alternativeInputEnabled: false,
    );
  }

  /// Setup system-level accessibility features
  static Future<void> _setupSystemAccessibility() async {
    // Enable semantic announcements
    SemanticsService.announce(
      'Ludo game loaded. Accessibility features enabled.',
      TextDirection.ltr,
    );
  }

  /// Update accessibility settings
  static Future<void> updateSettings(AccessibilitySettings newSettings) async {
    _settings = newSettings;
    // Save to storage
    await _applySettings();
  }

  /// Apply current accessibility settings
  static Future<void> _applySettings() async {
    if (_settings.reducedMotion) {
      // Disable animations globally
      // This would be handled by animation providers
    }
    
    if (_settings.hapticFeedbackEnabled) {
      // Enable haptic feedback
      await HapticFeedback.lightImpact();
    }
  }

  /// Get current accessibility settings
  static AccessibilitySettings get settings => _settings;

  /// Announce game state change
  static Future<void> announceGameState(GameState gameState) async {
    if (!_settings.screenReaderEnabled) return;

    final currentPlayer = gameState.currentPlayer;
    final announcement = 'It is ${currentPlayer.name}\'s turn. '
        '${currentPlayer.color.name} player. '
        'Game status: ${gameState.gameStatus.name}';

    await Future.delayed(_announcementDelay);
    await SemanticsService.announce(announcement, TextDirection.ltr);
  }

  /// Announce dice roll result
  static Future<void> announceDiceRoll(int value, String playerName) async {
    if (!_settings.screenReaderEnabled) return;

    final announcement = '$playerName rolled a $value';
    await SemanticsService.announce(announcement, TextDirection.ltr);
  }

  /// Announce token movement
  static Future<void> announceTokenMovement(
    Token token,
    Position from,
    Position to,
    {String? additionalInfo}
  ) async {
    if (!_settings.screenReaderEnabled) return;

    final fromDescription = _describePosition(from);
    final toDescription = _describePosition(to);
    final tokenDescription = _describeToken(token);
    
    String announcement = '$tokenDescription moved from $fromDescription to $toDescription';
    if (additionalInfo != null) {
      announcement += '. $additionalInfo';
    }

    await SemanticsService.announce(announcement, TextDirection.ltr);
  }

  /// Announce token capture
  static Future<void> announceTokenCapture(
    Token capturedToken,
    Token capturingToken,
    Position position
  ) async {
    if (!_settings.screenReaderEnabled) return;

    final capturedDesc = _describeToken(capturedToken);
    final capturingDesc = _describeToken(capturingToken);
    final positionDesc = _describePosition(position);

    final announcement = '$capturingDesc captured $capturedDesc at $positionDesc. '
        '${capturedToken.color.name} token returns to home.';

    await SemanticsService.announce(announcement, TextDirection.ltr);
  }

  /// Announce game end
  static Future<void> announceGameEnd(GameState gameState) async {
    if (!_settings.screenReaderEnabled) return;

    final winner = gameState.winner;
    String announcement;
    
    if (winner != null) {
      announcement = 'Game finished! ${winner.name} wins with ${winner.color.name} tokens. '
          'Congratulations!';
    } else {
      announcement = 'Game ended without a winner.';
    }

    await SemanticsService.announce(announcement, TextDirection.ltr);
  }

  /// Announce available moves
  static Future<void> announceAvailableMoves(
    List<Position> validMoves,
    Token selectedToken
  ) async {
    if (!_settings.screenReaderEnabled) return;

    if (validMoves.isEmpty) {
      await SemanticsService.announce(
        'No valid moves available for ${_describeToken(selectedToken)}',
        TextDirection.ltr,
      );
      return;
    }

    final tokenDesc = _describeToken(selectedToken);
    final movesDesc = validMoves.map(_describePosition).join(', ');
    final announcement = '$tokenDesc can move to: $movesDesc';

    await SemanticsService.announce(announcement, TextDirection.ltr);
  }

  /// Describe a position in human-readable format
  static String _describePosition(Position position) {
    switch (position.type) {
      case PositionType.home:
        return '${position.ownerColor?.name ?? 'unknown'} home area';
      case PositionType.start:
        return '${position.ownerColor?.name ?? 'unknown'} starting position';
      case PositionType.path:
        return 'position ${position.pathIndex ?? 'unknown'} on the main path';
      case PositionType.finish:
        return '${position.ownerColor?.name ?? 'unknown'} finish area';
      case PositionType.safe:
        return 'safe zone at position ${position.pathIndex ?? 'unknown'}';
    }
  }

  /// Describe a token in human-readable format
  static String _describeToken(Token token) {
    return '${token.color.name} token ${token.id.split('_').last}';
  }

  /// Get semantic label for game board position
  static String getPositionSemanticLabel(Position position, {Token? token}) {
    String label = _describePosition(position);
    
    if (token != null) {
      label += ' occupied by ${_describeToken(token)}';
    } else {
      label += ' empty';
    }
    
    return label;
  }

  /// Get semantic label for token
  static String getTokenSemanticLabel(Token token) {
    String label = _describeToken(token);
    
    switch (token.state) {
      case TokenState.home:
        label += ' at home';
        break;
      case TokenState.playing:
        label += ' in play at ${_describePosition(token.currentPosition)}';
        break;
      case TokenState.finished:
        label += ' finished';
        break;
    }
    
    if (token.canMove) {
      label += ', can move';
    } else {
      label += ', cannot move';
    }
    
    return label;
  }

  /// Get semantic hint for interactive elements
  static String getInteractionHint(String action, {String? context}) {
    String hint = 'Double tap to $action';
    if (context != null) {
      hint += ' $context';
    }
    return hint;
  }

  /// Provide haptic feedback
  static Future<void> provideHapticFeedback(HapticFeedbackType type) async {
    if (!_settings.hapticFeedbackEnabled) return;

    switch (type) {
      case HapticFeedbackType.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        await HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        await HapticFeedback.selectionClick();
        break;
    }
  }

  /// Check if high contrast colors should be used
  static bool shouldUseHighContrast() {
    return _settings.highContrastMode;
  }

  /// Get accessible colors for game elements
  static AccessibleColors getAccessibleColors() {
    if (_settings.highContrastMode) {
      return AccessibleColors.highContrast();
    } else if (_settings.colorBlindSupport) {
      return AccessibleColors.colorBlindFriendly();
    } else {
      return AccessibleColors.standard();
    }
  }

  /// Get text scaling factor
  static double getTextScaleFactor() {
    return _settings.largeTextMode ? 1.3 : 1.0;
  }

  /// Check if animations should be reduced
  static bool shouldReduceMotion() {
    return _settings.reducedMotion;
  }

  /// Announce error or important message
  static Future<void> announceError(String message) async {
    if (!_settings.screenReaderEnabled) return;

    await HapticFeedback.vibrate();
    await SemanticsService.announce(
      'Error: $message',
      TextDirection.ltr,
    );
  }

  /// Announce success message
  static Future<void> announceSuccess(String message) async {
    if (!_settings.screenReaderEnabled) return;

    await HapticFeedback.lightImpact();
    await SemanticsService.announce(
      'Success: $message',
      TextDirection.ltr,
    );
  }

  /// Get board navigation instructions
  static String getBoardNavigationInstructions() {
    return 'Navigate the game board using swipe gestures. '
           'Double tap to select tokens or positions. '
           'Use voice over to hear position descriptions.';
  }

  /// Get game controls instructions
  static String getGameControlsInstructions() {
    return 'Double tap the dice to roll. '
           'Select a token by double tapping it. '
           'Choose destination by double tapping valid positions. '
           'Swipe left to hear current game status.';
  }

  /// Dispose accessibility service
  static void dispose() {
    _isInitialized = false;
  }
}

/// Accessibility settings configuration
class AccessibilitySettings {
  final bool screenReaderEnabled;
  final bool highContrastMode;
  final bool largeTextMode;
  final bool reducedMotion;
  final bool colorBlindSupport;
  final bool soundCuesEnabled;
  final bool hapticFeedbackEnabled;
  final bool alternativeInputEnabled;

  const AccessibilitySettings({
    this.screenReaderEnabled = false,
    this.highContrastMode = false,
    this.largeTextMode = false,
    this.reducedMotion = false,
    this.colorBlindSupport = false,
    this.soundCuesEnabled = true,
    this.hapticFeedbackEnabled = true,
    this.alternativeInputEnabled = false,
  });

  AccessibilitySettings copyWith({
    bool? screenReaderEnabled,
    bool? highContrastMode,
    bool? largeTextMode,
    bool? reducedMotion,
    bool? colorBlindSupport,
    bool? soundCuesEnabled,
    bool? hapticFeedbackEnabled,
    bool? alternativeInputEnabled,
  }) {
    return AccessibilitySettings(
      screenReaderEnabled: screenReaderEnabled ?? this.screenReaderEnabled,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      largeTextMode: largeTextMode ?? this.largeTextMode,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      colorBlindSupport: colorBlindSupport ?? this.colorBlindSupport,
      soundCuesEnabled: soundCuesEnabled ?? this.soundCuesEnabled,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      alternativeInputEnabled: alternativeInputEnabled ?? this.alternativeInputEnabled,
    );
  }
}

/// Haptic feedback types
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
}

/// Accessible color schemes
class AccessibleColors {
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color errorColor;
  final Color successColor;
  final Map<PlayerColor, Color> playerColors;

  const AccessibleColors({
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.errorColor,
    required this.successColor,
    required this.playerColors,
  });

  /// Standard color scheme
  factory AccessibleColors.standard() {
    return AccessibleColors(
      primaryColor: Colors.blue.shade600,
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      errorColor: Colors.red.shade600,
      successColor: Colors.green.shade600,
      playerColors: {
        PlayerColor.red: Colors.red.shade600,
        PlayerColor.blue: Colors.blue.shade600,
        PlayerColor.green: Colors.green.shade600,
        PlayerColor.yellow: Colors.yellow.shade700,
      },
    );
  }

  /// High contrast color scheme
  factory AccessibleColors.highContrast() {
    return AccessibleColors(
      primaryColor: Colors.black,
      backgroundColor: Colors.white,
      textColor: Colors.black,
      errorColor: Colors.red.shade900,
      successColor: Colors.green.shade900,
      playerColors: {
        PlayerColor.red: Colors.red.shade900,
        PlayerColor.blue: Colors.blue.shade900,
        PlayerColor.green: Colors.green.shade900,
        PlayerColor.yellow: Colors.orange.shade900,
      },
    );
  }

  /// Color blind friendly scheme
  factory AccessibleColors.colorBlindFriendly() {
    return AccessibleColors(
      primaryColor: Colors.blue.shade700,
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      errorColor: Colors.red.shade700,
      successColor: Colors.green.shade700,
      playerColors: {
        PlayerColor.red: const Color(0xFFE31A1C),    // Pure red
        PlayerColor.blue: const Color(0xFF1F78B4),   // Pure blue
        PlayerColor.green: const Color(0xFF33A02C),  // Pure green
        PlayerColor.yellow: const Color(0xFFFF7F00), // Orange instead of yellow
      },
    );
  }
}

/// Screen reader announcement priorities
enum AnnouncementPriority {
  low,      // General information
  medium,   // Game state changes
  high,     // Important actions
  critical, // Errors or urgent information
}