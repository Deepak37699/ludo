import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/themes/theme_service.dart';
import '../../core/enums/game_enums.dart';

/// Provider for theme service
final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService();
});

/// Provider for current theme customization
final themeCustomizationProvider = StateNotifierProvider<ThemeCustomizationNotifier, ThemeCustomizationState>((ref) {
  return ThemeCustomizationNotifier();
});

/// Theme customization state
class ThemeCustomizationState {
  final ThemeCustomization customization;
  final List<GameThemeData> availableGameThemes;
  final List<BoardThemeData> availableBoardThemes;
  final Set<String> unlockedThemes;
  final bool isLoading;
  final String? error;

  const ThemeCustomizationState({
    required this.customization,
    this.availableGameThemes = const [],
    this.availableBoardThemes = const [],
    this.unlockedThemes = const {},
    this.isLoading = false,
    this.error,
  });

  ThemeCustomizationState copyWith({
    ThemeCustomization? customization,
    List<GameThemeData>? availableGameThemes,
    List<BoardThemeData>? availableBoardThemes,
    Set<String>? unlockedThemes,
    bool? isLoading,
    String? error,
  }) {
    return ThemeCustomizationState(
      customization: customization ?? this.customization,
      availableGameThemes: availableGameThemes ?? this.availableGameThemes,
      availableBoardThemes: availableBoardThemes ?? this.availableBoardThemes,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get current game theme
  GameThemeData? get currentGameTheme {
    return ThemeService.getGameTheme(customization.gameThemeId);
  }

  /// Get current board theme
  BoardThemeData? get currentBoardTheme {
    return ThemeService.getBoardTheme(customization.boardThemeId);
  }

  /// Check if theme is unlocked
  bool isThemeUnlocked(String themeId) {
    return unlockedThemes.contains(themeId) || 
           _isThemeFree(themeId);
  }

  /// Check if theme is free
  bool _isThemeFree(String themeId) {
    final gameTheme = ThemeService.getGameTheme(themeId);
    if (gameTheme != null) return !gameTheme.isPremium;
    
    final boardTheme = ThemeService.getBoardTheme(themeId);
    if (boardTheme != null) return !boardTheme.isPremium;
    
    return false;
  }
}

/// Theme customization notifier
class ThemeCustomizationNotifier extends StateNotifier<ThemeCustomizationState> {
  static const String _gameThemeKey = 'selected_game_theme';
  static const String _boardThemeKey = 'selected_board_theme';
  static const String _unlockedThemesKey = 'unlocked_themes';

  ThemeCustomizationNotifier() : super(ThemeCustomizationState(
    customization: const ThemeCustomization(
      gameThemeId: 'classic',
      boardThemeId: 'classic',
    ),
  )) {
    _initialize();
  }

  /// Initialize theme system
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      ThemeService.initialize();
      
      // Load all available themes
      final gameThemes = ThemeService.getAllGameThemes();
      final boardThemes = ThemeService.getAllBoardThemes();
      
      // Load saved preferences
      final prefs = await SharedPreferences.getInstance();
      final savedGameTheme = prefs.getString(_gameThemeKey) ?? 'classic';
      final savedBoardTheme = prefs.getString(_boardThemeKey) ?? 'classic';
      final unlockedThemesList = prefs.getStringList(_unlockedThemesKey) ?? [];
      
      // Create default unlocked themes (free themes)
      final defaultUnlocked = <String>{};
      for (final theme in gameThemes) {
        if (!theme.isPremium) defaultUnlocked.add(theme.id);
      }
      for (final theme in boardThemes) {
        if (!theme.isPremium) defaultUnlocked.add(theme.id);
      }
      
      final unlockedThemes = {...defaultUnlocked, ...unlockedThemesList};

      state = state.copyWith(
        customization: ThemeCustomization(
          gameThemeId: savedGameTheme,
          boardThemeId: savedBoardTheme,
        ),
        availableGameThemes: gameThemes,
        availableBoardThemes: boardThemes,
        unlockedThemes: unlockedThemes,
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

  /// Change game theme
  Future<void> changeGameTheme(String themeId) async {
    if (!state.isThemeUnlocked(themeId)) {
      state = state.copyWith(error: 'Theme is not unlocked');
      return;
    }

    final newCustomization = state.customization.copyWith(gameThemeId: themeId);
    state = state.copyWith(customization: newCustomization, error: null);

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gameThemeKey, themeId);
  }

  /// Change board theme
  Future<void> changeBoardTheme(String themeId) async {
    if (!state.isThemeUnlocked(themeId)) {
      state = state.copyWith(error: 'Theme is not unlocked');
      return;
    }

    final newCustomization = state.customization.copyWith(boardThemeId: themeId);
    state = state.copyWith(customization: newCustomization, error: null);

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_boardThemeKey, themeId);
  }

  /// Unlock theme
  Future<void> unlockTheme(String themeId) async {
    final updatedUnlocked = Set<String>.from(state.unlockedThemes);
    updatedUnlocked.add(themeId);
    
    state = state.copyWith(unlockedThemes: updatedUnlocked);

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedThemesKey, updatedUnlocked.toList());
  }

  /// Purchase premium theme
  Future<bool> purchaseTheme(String themeId) async {
    // This would integrate with in-app purchases
    // For now, just unlock the theme
    await unlockTheme(themeId);
    return true;
  }

  /// Reset to default theme
  Future<void> resetToDefault() async {
    await changeGameTheme('classic');
    await changeBoardTheme('classic');
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Get available themes for game
  List<GameThemeData> getAvailableGameThemes() {
    return state.availableGameThemes;
  }

  /// Get available themes for board
  List<BoardThemeData> getAvailableBoardThemes() {
    return state.availableBoardThemes;
  }

  /// Get unlocked game themes
  List<GameThemeData> getUnlockedGameThemes() {
    return state.availableGameThemes
        .where((theme) => state.isThemeUnlocked(theme.id))
        .toList();
  }

  /// Get unlocked board themes
  List<BoardThemeData> getUnlockedBoardThemes() {
    return state.availableBoardThemes
        .where((theme) => state.isThemeUnlocked(theme.id))
        .toList();
  }

  /// Get locked game themes
  List<GameThemeData> getLockedGameThemes() {
    return state.availableGameThemes
        .where((theme) => !state.isThemeUnlocked(theme.id))
        .toList();
  }

  /// Get locked board themes
  List<BoardThemeData> getLockedBoardThemes() {
    return state.availableBoardThemes
        .where((theme) => !state.isThemeUnlocked(theme.id))
        .toList();
  }
}

/// Provider for current Flutter theme
final currentFlutterThemeProvider = Provider<ThemeData>((ref) {
  final themeState = ref.watch(themeCustomizationProvider);
  final gameTheme = themeState.currentGameTheme;
  
  if (gameTheme != null) {
    return ThemeService.createFlutterTheme(gameTheme);
  }
  
  // Fallback to default theme
  return ThemeData.light();
});

/// Provider for current game theme
final currentGameThemeProvider = Provider<GameThemeData?>((ref) {
  final themeState = ref.watch(themeCustomizationProvider);
  return themeState.currentGameTheme;
});

/// Provider for current board theme
final currentBoardThemeProvider = Provider<BoardThemeData?>((ref) {
  final themeState = ref.watch(themeCustomizationProvider);
  return themeState.currentBoardTheme;
});

/// Provider for player token colors based on current theme
final playerTokenColorsProvider = Provider<Map<PlayerColor, Color>>((ref) {
  final gameTheme = ref.watch(currentGameThemeProvider);
  
  if (gameTheme != null) {
    return gameTheme.playerColors;
  }
  
  // Fallback colors
  return {
    PlayerColor.red: Colors.red.shade600,
    PlayerColor.blue: Colors.blue.shade600,
    PlayerColor.green: Colors.green.shade600,
    PlayerColor.yellow: Colors.yellow.shade700,
  };
});

/// Provider for theme actions
final themeActionsProvider = Provider<ThemeActions>((ref) {
  return ThemeActions(ref);
});

/// Theme actions helper class
class ThemeActions {
  final Ref _ref;

  ThemeActions(this._ref);

  /// Preview theme temporarily
  Future<void> previewTheme(String gameThemeId, String boardThemeId) async {
    // This would show a preview without saving
    // Implementation depends on UI requirements
  }

  /// Apply theme combination
  Future<void> applyThemeCombination(String gameThemeId, String boardThemeId) async {
    final notifier = _ref.read(themeCustomizationProvider.notifier);
    await notifier.changeGameTheme(gameThemeId);
    await notifier.changeBoardTheme(boardThemeId);
  }

  /// Get recommended theme combinations
  List<ThemeCombination> getRecommendedCombinations() {
    return [
      ThemeCombination(
        name: 'Classic Experience',
        gameThemeId: 'classic',
        boardThemeId: 'classic',
        description: 'Traditional Ludo look and feel',
      ),
      ThemeCombination(
        name: 'Dark Mode',
        gameThemeId: 'dark',
        boardThemeId: 'classic',
        description: 'Easy on the eyes for night gaming',
      ),
      ThemeCombination(
        name: 'Ocean Adventure',
        gameThemeId: 'ocean',
        boardThemeId: 'space',
        description: 'Deep sea exploration theme',
      ),
      ThemeCombination(
        name: 'Royal Palace',
        gameThemeId: 'sunset',
        boardThemeId: 'royal',
        description: 'Elegant and luxurious gaming',
      ),
      ThemeCombination(
        name: 'Neon Nights',
        gameThemeId: 'neon',
        boardThemeId: 'space',
        description: 'Futuristic cyberpunk experience',
      ),
    ];
  }

  /// Check if theme is available for purchase
  bool canPurchaseTheme(String themeId) {
    final state = _ref.read(themeCustomizationProvider);
    return !state.isThemeUnlocked(themeId);
  }

  /// Get theme unlock requirements
  List<ThemeUnlockRequirement> getThemeUnlockRequirements(String themeId) {
    // This would return actual unlock requirements
    // For now, return purchase requirement for premium themes
    final gameTheme = ThemeService.getGameTheme(themeId);
    final boardTheme = ThemeService.getBoardTheme(themeId);
    
    if ((gameTheme?.isPremium ?? false) || (boardTheme?.isPremium ?? false)) {
      return [
        const ThemeUnlockRequirement(
          type: 'purchase',
          requirement: 'premium_theme_pack',
          description: 'Purchase Premium Theme Pack',
        ),
      ];
    }
    
    return [];
  }
}

/// Theme combination class
class ThemeCombination {
  final String name;
  final String gameThemeId;
  final String boardThemeId;
  final String description;

  const ThemeCombination({
    required this.name,
    required this.gameThemeId,
    required this.boardThemeId,
    required this.description,
  });
}

/// Provider for theme statistics
final themeStatsProvider = Provider<ThemeStats>((ref) {
  final state = ref.watch(themeCustomizationProvider);
  
  final totalThemes = state.availableGameThemes.length + state.availableBoardThemes.length;
  final unlockedThemes = state.unlockedThemes.length;
  final premiumThemes = state.availableGameThemes.where((t) => t.isPremium).length +
                       state.availableBoardThemes.where((t) => t.isPremium).length;
  
  return ThemeStats(
    totalThemes: totalThemes,
    unlockedThemes: unlockedThemes,
    premiumThemes: premiumThemes,
    completionPercentage: totalThemes > 0 ? unlockedThemes / totalThemes : 0.0,
  );
});

/// Theme statistics class
class ThemeStats {
  final int totalThemes;
  final int unlockedThemes;
  final int premiumThemes;
  final double completionPercentage;

  const ThemeStats({
    required this.totalThemes,
    required this.unlockedThemes,
    required this.premiumThemes,
    required this.completionPercentage,
  });
}