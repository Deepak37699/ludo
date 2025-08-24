import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../services/audio/audio_service.dart';
import '../../core/enums/game_enums.dart';
import 'settings_provider.dart';

/// Provider for the audio service instance
final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

/// Provider for audio manager
final audioManagerProvider = Provider<AudioManager>((ref) {
  return AudioManager();
});

/// Provider for audio state
final audioStateProvider = StateNotifierProvider<AudioStateNotifier, AudioState>((ref) {
  return AudioStateNotifier(ref);
});

/// Audio state class
class AudioState {
  final bool isInitialized;
  final bool isMusicPlaying;
  final String? currentTrack;
  final bool isLoading;
  final String? error;

  const AudioState({
    this.isInitialized = false,
    this.isMusicPlaying = false,
    this.currentTrack,
    this.isLoading = false,
    this.error,
  });

  AudioState copyWith({
    bool? isInitialized,
    bool? isMusicPlaying,
    String? currentTrack,
    bool? isLoading,
    String? error,
  }) {
    return AudioState(
      isInitialized: isInitialized ?? this.isInitialized,
      isMusicPlaying: isMusicPlaying ?? this.isMusicPlaying,
      currentTrack: currentTrack ?? this.currentTrack,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Audio state notifier
class AudioStateNotifier extends StateNotifier<AudioState> {
  final Ref _ref;
  late final AudioService _audioService;

  AudioStateNotifier(this._ref) : super(const AudioState()) {
    _audioService = _ref.read(audioServiceProvider);
    _initializeAudio();
    _listenToSettings();
  }

  /// Initialize audio service
  Future<void> _initializeAudio() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _audioService.initialize();
      await AudioPreloader.preloadEssentialAudio();
      
      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        error: null,
      );
      
      // Start menu music if enabled
      final settings = _ref.read(appSettingsProvider);
      if (settings.musicEnabled) {
        await playMenuMusic();
      }
      
      debugPrint('Audio system initialized successfully');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      debugPrint('Failed to initialize audio: $e');
    }
  }

  /// Listen to settings changes
  void _listenToSettings() {
    _ref.listen<AppSettings>(appSettingsProvider, (previous, next) {
      if (previous == null) return;
      
      // Update audio settings when app settings change
      _updateAudioSettings(next);
    });
  }

  /// Update audio settings
  Future<void> _updateAudioSettings(AppSettings settings) async {
    try {
      await AudioManager.updateSettings(
        musicEnabled: settings.musicEnabled,
        sfxEnabled: settings.soundEnabled,
        musicVolume: settings.musicVolume,
        sfxVolume: settings.soundVolume,
      );
      
      // Handle music state based on settings
      if (!settings.musicEnabled && state.isMusicPlaying) {
        await pauseMusic();
      } else if (settings.musicEnabled && !state.isMusicPlaying && state.currentTrack != null) {
        await resumeMusic();
      }
    } catch (e) {
      debugPrint('Failed to update audio settings: $e');
    }
  }

  /// Play menu background music
  Future<void> playMenuMusic() async {
    if (!state.isInitialized) return;
    
    try {
      await AudioManager.playMenuMusic();
      state = state.copyWith(
        isMusicPlaying: true,
        currentTrack: 'background_menu',
      );
    } catch (e) {
      debugPrint('Failed to play menu music: $e');
    }
  }

  /// Play game background music
  Future<void> playGameMusic() async {
    if (!state.isInitialized) return;
    
    try {
      await AudioManager.playGameMusic();
      state = state.copyWith(
        isMusicPlaying: true,
        currentTrack: 'background_game',
      );
    } catch (e) {
      debugPrint('Failed to play game music: $e');
    }
  }

  /// Stop background music
  Future<void> stopMusic() async {
    try {
      await AudioManager.stopMusic();
      state = state.copyWith(
        isMusicPlaying: false,
        currentTrack: null,
      );
    } catch (e) {
      debugPrint('Failed to stop music: $e');
    }
  }

  /// Pause background music
  Future<void> pauseMusic() async {
    try {
      await AudioManager.pauseMusic();
      state = state.copyWith(isMusicPlaying: false);
    } catch (e) {
      debugPrint('Failed to pause music: $e');
    }
  }

  /// Resume background music
  Future<void> resumeMusic() async {
    try {
      await AudioManager.resumeMusic();
      state = state.copyWith(isMusicPlaying: true);
    } catch (e) {
      debugPrint('Failed to resume music: $e');
    }
  }

  /// Play sound effect
  Future<void> playSoundEffect(SoundEffect effect) async {
    if (!state.isInitialized) return;
    
    try {
      await AudioFeedback.gameEvent(effect);
    } catch (e) {
      debugPrint('Failed to play sound effect: $e');
    }
  }

  /// Play dice roll sound
  Future<void> playDiceRoll() async {
    await playSoundEffect(SoundEffect.diceRoll);
  }

  /// Play token move sound
  Future<void> playTokenMove() async {
    await playSoundEffect(SoundEffect.tokenMove);
  }

  /// Play token capture sound
  Future<void> playTokenCapture() async {
    await playSoundEffect(SoundEffect.tokenCapture);
  }

  /// Play button click sound
  Future<void> playButtonClick() async {
    await AudioFeedback.buttonPress();
  }

  /// Play game win sound
  Future<void> playGameWin() async {
    await playSoundEffect(SoundEffect.gameWin);
  }

  /// Play notification sound
  Future<void> playNotification() async {
    await playSoundEffect(SoundEffect.notification);
  }

  /// Handle game state changes
  Future<void> handleGameStateChange(GameStatus newStatus) async {
    switch (newStatus) {
      case GameStatus.playing:
        await playGameMusic();
        break;
      case GameStatus.finished:
        await playGameWin();
        // Could transition to victory music here
        break;
      case GameStatus.paused:
        await pauseMusic();
        break;
      default:
        await playMenuMusic();
    }
  }

  @override
  void dispose() {
    // Clean up audio resources
    AudioManager.dispose();
    super.dispose();
  }
}

/// Provider for quick access to audio actions
final audioActionsProvider = Provider<AudioActions>((ref) {
  return AudioActions(ref);
});

/// Audio actions helper class
class AudioActions {
  final Ref _ref;

  AudioActions(this._ref);

  /// Play dice roll with feedback
  Future<void> diceRoll() async {
    await _ref.read(audioStateProvider.notifier).playDiceRoll();
  }

  /// Play token move with feedback
  Future<void> tokenMove() async {
    await _ref.read(audioStateProvider.notifier).playTokenMove();
  }

  /// Play token capture with feedback
  Future<void> tokenCapture() async {
    await _ref.read(audioStateProvider.notifier).playTokenCapture();
  }

  /// Play button click with feedback
  Future<void> buttonClick() async {
    await _ref.read(audioStateProvider.notifier).playButtonClick();
  }

  /// Play game win with feedback
  Future<void> gameWin() async {
    await _ref.read(audioStateProvider.notifier).playGameWin();
  }

  /// Toggle music on/off
  Future<void> toggleMusic() async {
    final audioState = _ref.read(audioStateProvider);
    if (audioState.isMusicPlaying) {
      await _ref.read(audioStateProvider.notifier).pauseMusic();
    } else {
      await _ref.read(audioStateProvider.notifier).resumeMusic();
    }
  }

  /// Change background music based on context
  Future<void> setContextMusic(String context) async {
    switch (context) {
      case 'menu':
        await _ref.read(audioStateProvider.notifier).playMenuMusic();
        break;
      case 'game':
        await _ref.read(audioStateProvider.notifier).playGameMusic();
        break;
      default:
        await _ref.read(audioStateProvider.notifier).playMenuMusic();
    }
  }
}

/// Provider for checking if audio is enabled
final isAudioEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.soundEnabled || settings.musicEnabled;
});

/// Provider for checking if music is enabled
final isMusicEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.musicEnabled;
});

/// Provider for checking if sound effects are enabled
final isSfxEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.soundEnabled;
});

/// Provider for current audio volumes
final audioVolumesProvider = Provider<({double music, double sfx})>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return (music: settings.musicVolume, sfx: settings.soundVolume);
});