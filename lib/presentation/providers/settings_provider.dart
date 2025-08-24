import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/enums/game_enums.dart';

/// Settings state class
class AppSettings {
  final bool soundEnabled;
  final bool musicEnabled;
  final double soundVolume;
  final double musicVolume;
  final ThemeMode themeMode;
  final GameTheme gameTheme;
  final bool notificationsEnabled;
  final bool vibrationEnabled;
  final String language;
  final int turnTimeLimit;
  final AIDifficulty defaultAIDifficulty;
  final bool showAnimations;
  final bool autoSaveGame;

  const AppSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.soundVolume = 0.8,
    this.musicVolume = 0.6,
    this.themeMode = ThemeMode.system,
    this.gameTheme = GameTheme.classic,
    this.notificationsEnabled = true,
    this.vibrationEnabled = true,
    this.language = 'en',
    this.turnTimeLimit = 30,
    this.defaultAIDifficulty = AIDifficulty.medium,
    this.showAnimations = true,
    this.autoSaveGame = true,
  });

  AppSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    double? soundVolume,
    double? musicVolume,
    ThemeMode? themeMode,
    GameTheme? gameTheme,
    bool? notificationsEnabled,
    bool? vibrationEnabled,
    String? language,
    int? turnTimeLimit,
    AIDifficulty? defaultAIDifficulty,
    bool? showAnimations,
    bool? autoSaveGame,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      themeMode: themeMode ?? this.themeMode,
      gameTheme: gameTheme ?? this.gameTheme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      language: language ?? this.language,
      turnTimeLimit: turnTimeLimit ?? this.turnTimeLimit,
      defaultAIDifficulty: defaultAIDifficulty ?? this.defaultAIDifficulty,
      showAnimations: showAnimations ?? this.showAnimations,
      autoSaveGame: autoSaveGame ?? this.autoSaveGame,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'musicEnabled': musicEnabled,
      'soundVolume': soundVolume,
      'musicVolume': musicVolume,
      'themeMode': themeMode.index,
      'gameTheme': gameTheme.index,
      'notificationsEnabled': notificationsEnabled,
      'vibrationEnabled': vibrationEnabled,
      'language': language,
      'turnTimeLimit': turnTimeLimit,
      'defaultAIDifficulty': defaultAIDifficulty.index,
      'showAnimations': showAnimations,
      'autoSaveGame': autoSaveGame,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      soundEnabled: json['soundEnabled'] ?? true,
      musicEnabled: json['musicEnabled'] ?? true,
      soundVolume: json['soundVolume']?.toDouble() ?? 0.8,
      musicVolume: json['musicVolume']?.toDouble() ?? 0.6,
      themeMode: ThemeMode.values[json['themeMode'] ?? 0],
      gameTheme: GameTheme.values[json['gameTheme'] ?? 0],
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      language: json['language'] ?? 'en',
      turnTimeLimit: json['turnTimeLimit'] ?? 30,
      defaultAIDifficulty: AIDifficulty.values[json['defaultAIDifficulty'] ?? 1],
      showAnimations: json['showAnimations'] ?? true,
      autoSaveGame: json['autoSaveGame'] ?? true,
    );
  }
}

/// Provider for app settings
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});

/// Provider for theme mode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.themeMode;
});

/// Provider for game theme
final gameThemeProvider = Provider<GameTheme>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.gameTheme;
});

/// Provider for sound settings
final soundEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.soundEnabled;
});

/// Provider for music settings
final musicEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.musicEnabled;
});

/// App Settings Notifier
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  static const String _prefsKey = 'app_settings';

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_prefsKey);
      
      if (settingsJson != null) {
        final Map<String, dynamic> json = {};
        // Parse the JSON string here if you store it as JSON
        // For now, we'll load individual preferences
        
        state = AppSettings(
          soundEnabled: prefs.getBool('soundEnabled') ?? true,
          musicEnabled: prefs.getBool('musicEnabled') ?? true,
          soundVolume: prefs.getDouble('soundVolume') ?? 0.8,
          musicVolume: prefs.getDouble('musicVolume') ?? 0.6,
          themeMode: ThemeMode.values[prefs.getInt('themeMode') ?? 0],
          gameTheme: GameTheme.values[prefs.getInt('gameTheme') ?? 0],
          notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
          vibrationEnabled: prefs.getBool('vibrationEnabled') ?? true,
          language: prefs.getString('language') ?? 'en',
          turnTimeLimit: prefs.getInt('turnTimeLimit') ?? 30,
          defaultAIDifficulty: AIDifficulty.values[prefs.getInt('defaultAIDifficulty') ?? 1],
          showAnimations: prefs.getBool('showAnimations') ?? true,
          autoSaveGame: prefs.getBool('autoSaveGame') ?? true,
        );
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await Future.wait([
        prefs.setBool('soundEnabled', state.soundEnabled),
        prefs.setBool('musicEnabled', state.musicEnabled),
        prefs.setDouble('soundVolume', state.soundVolume),
        prefs.setDouble('musicVolume', state.musicVolume),
        prefs.setInt('themeMode', state.themeMode.index),
        prefs.setInt('gameTheme', state.gameTheme.index),
        prefs.setBool('notificationsEnabled', state.notificationsEnabled),
        prefs.setBool('vibrationEnabled', state.vibrationEnabled),
        prefs.setString('language', state.language),
        prefs.setInt('turnTimeLimit', state.turnTimeLimit),
        prefs.setInt('defaultAIDifficulty', state.defaultAIDifficulty.index),
        prefs.setBool('showAnimations', state.showAnimations),
        prefs.setBool('autoSaveGame', state.autoSaveGame),
      ]);
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  /// Update sound enabled setting
  void setSoundEnabled(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
    _saveSettings();
  }

  /// Update music enabled setting
  void setMusicEnabled(bool enabled) {
    state = state.copyWith(musicEnabled: enabled);
    _saveSettings();
  }

  /// Update sound volume
  void setSoundVolume(double volume) {
    state = state.copyWith(soundVolume: volume.clamp(0.0, 1.0));
    _saveSettings();
  }

  /// Update music volume
  void setMusicVolume(double volume) {
    state = state.copyWith(musicVolume: volume.clamp(0.0, 1.0));
    _saveSettings();
  }

  /// Update theme mode
  void setThemeMode(ThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
    _saveSettings();
  }

  /// Update game theme
  void setGameTheme(GameTheme gameTheme) {
    state = state.copyWith(gameTheme: gameTheme);
    _saveSettings();
  }

  /// Update notifications setting
  void setNotificationsEnabled(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
    _saveSettings();
  }

  /// Update vibration setting
  void setVibrationEnabled(bool enabled) {
    state = state.copyWith(vibrationEnabled: enabled);
    _saveSettings();
  }

  /// Update language
  void setLanguage(String language) {
    state = state.copyWith(language: language);
    _saveSettings();
  }

  /// Update turn time limit
  void setTurnTimeLimit(int seconds) {
    state = state.copyWith(turnTimeLimit: seconds.clamp(10, 120));
    _saveSettings();
  }

  /// Update default AI difficulty
  void setDefaultAIDifficulty(AIDifficulty difficulty) {
    state = state.copyWith(defaultAIDifficulty: difficulty);
    _saveSettings();
  }

  /// Update animations setting
  void setShowAnimations(bool enabled) {
    state = state.copyWith(showAnimations: enabled);
    _saveSettings();
  }

  /// Update auto save setting
  void setAutoSaveGame(bool enabled) {
    state = state.copyWith(autoSaveGame: enabled);
    _saveSettings();
  }

  /// Reset all settings to default
  void resetToDefaults() {
    state = const AppSettings();
    _saveSettings();
  }

  /// Toggle sound on/off
  void toggleSound() {
    setSoundEnabled(!state.soundEnabled);
  }

  /// Toggle music on/off
  void toggleMusic() {
    setMusicEnabled(!state.musicEnabled);
  }

  /// Toggle notifications on/off
  void toggleNotifications() {
    setNotificationsEnabled(!state.notificationsEnabled);
  }

  /// Toggle vibration on/off
  void toggleVibration() {
    setVibrationEnabled(!state.vibrationEnabled);
  }

  /// Toggle animations on/off
  void toggleAnimations() {
    setShowAnimations(!state.showAnimations);
  }

  /// Toggle auto save on/off
  void toggleAutoSave() {
    setAutoSaveGame(!state.autoSaveGame);
  }
}

/// Loading state provider
final isLoadingProvider = StateProvider<bool>((ref) => false);

/// Error state provider
final errorProvider = StateProvider<String?>((ref) => null);

/// Network connectivity provider
final isOnlineProvider = StateProvider<bool>((ref) => true);

/// App lifecycle provider
final appLifecycleProvider = StateProvider<AppLifecycleState>((ref) => AppLifecycleState.resumed);