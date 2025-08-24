import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/enums/game_enums.dart';

/// Service for managing audio in the Ludo game
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Audio players
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // State
  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;
  double _musicVolume = 0.6;
  double _sfxVolume = 0.8;
  bool _isInitialized = false;

  // Current playing states
  bool _isMusicPlaying = false;
  String? _currentTrack;

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set audio session for background playback
      await _musicPlayer.setLoopMode(LoopMode.all);
      await _sfxPlayer.setLoopMode(LoopMode.off);

      // Set initial volumes
      await _musicPlayer.setVolume(_musicVolume);
      await _sfxPlayer.setVolume(_sfxVolume);

      _isInitialized = true;
      debugPrint('AudioService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AudioService: $e');
    }
  }

  /// Dispose audio resources
  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _sfxPlayer.dispose();
    _isInitialized = false;
  }

  /// Play background music
  Future<void> playBackgroundMusic({
    String track = 'background_menu',
    bool loop = true,
  }) async {
    if (!_isMusicEnabled || !_isInitialized) return;

    try {
      if (_currentTrack != track || !_isMusicPlaying) {
        await _musicPlayer.stop();
        
        // For demo purposes, we'll use a placeholder URL
        // In a real app, you would have actual music files
        await _musicPlayer.setUrl('asset:///assets/audio/$track.mp3');
        
        if (loop) {
          await _musicPlayer.setLoopMode(LoopMode.all);
        } else {
          await _musicPlayer.setLoopMode(LoopMode.off);
        }

        await _musicPlayer.play();
        _currentTrack = track;
        _isMusicPlaying = true;
        
        debugPrint('Playing background music: $track');
      }
    } catch (e) {
      debugPrint('Failed to play background music: $e');
      // Silently fail for demo - in production you might want to handle this differently
    }
  }

  /// Stop background music
  Future<void> stopBackgroundMusic() async {
    try {
      await _musicPlayer.stop();
      _isMusicPlaying = false;
      _currentTrack = null;
      debugPrint('Background music stopped');
    } catch (e) {
      debugPrint('Failed to stop background music: $e');
    }
  }

  /// Pause background music
  Future<void> pauseBackgroundMusic() async {
    try {
      await _musicPlayer.pause();
      _isMusicPlaying = false;
      debugPrint('Background music paused');
    } catch (e) {
      debugPrint('Failed to pause background music: $e');
    }
  }

  /// Resume background music
  Future<void> resumeBackgroundMusic() async {
    if (!_isMusicEnabled || !_isInitialized) return;

    try {
      await _musicPlayer.play();
      _isMusicPlaying = true;
      debugPrint('Background music resumed');
    } catch (e) {
      debugPrint('Failed to resume background music: $e');
    }
  }

  /// Play a sound effect
  Future<void> playSoundEffect(SoundEffect effect) async {
    if (!_isSfxEnabled || !_isInitialized) return;

    try {
      // Stop current sound effect if playing
      await _sfxPlayer.stop();
      
      // For demo purposes, we'll use placeholder URLs
      // In a real app, you would have actual sound files
      await _sfxPlayer.setUrl('asset:///assets/audio/${effect.fileName}.mp3');
      await _sfxPlayer.play();
      
      debugPrint('Playing sound effect: ${effect.fileName}');
    } catch (e) {
      debugPrint('Failed to play sound effect ${effect.fileName}: $e');
      // Silently fail for demo
    }
  }

  /// Set music enabled/disabled
  Future<void> setMusicEnabled(bool enabled) async {
    _isMusicEnabled = enabled;
    
    if (!enabled && _isMusicPlaying) {
      await pauseBackgroundMusic();
    } else if (enabled && !_isMusicPlaying && _currentTrack != null) {
      await resumeBackgroundMusic();
    }
  }

  /// Set sound effects enabled/disabled
  void setSfxEnabled(bool enabled) {
    _isSfxEnabled = enabled;
  }

  /// Set music volume (0.0 to 1.0)
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_musicVolume);
  }

  /// Set sound effects volume (0.0 to 1.0)
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _sfxPlayer.setVolume(_sfxVolume);
  }

  /// Play game-specific background music based on game state
  Future<void> playGameMusic(GameStatus gameStatus) async {
    switch (gameStatus) {
      case GameStatus.waiting:
        await playBackgroundMusic(track: 'background_lobby');
        break;
      case GameStatus.playing:
        await playBackgroundMusic(track: 'background_game');
        break;
      case GameStatus.finished:
        await playBackgroundMusic(track: 'background_victory', loop: false);
        break;
      default:
        await playBackgroundMusic(track: 'background_menu');
    }
  }

  /// Play dice roll sound with random variation
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

  /// Play token safe sound
  Future<void> playTokenSafe() async {
    await playSoundEffect(SoundEffect.tokenSafe);
  }

  /// Play token finish sound
  Future<void> playTokenFinish() async {
    await playSoundEffect(SoundEffect.tokenFinish);
  }

  /// Play game win sound
  Future<void> playGameWin() async {
    await playSoundEffect(SoundEffect.gameWin);
  }

  /// Play game lose sound
  Future<void> playGameLose() async {
    await playSoundEffect(SoundEffect.gameLose);
  }

  /// Play button click sound
  Future<void> playButtonClick() async {
    await playSoundEffect(SoundEffect.buttonClick);
  }

  /// Play notification sound
  Future<void> playNotification() async {
    await playSoundEffect(SoundEffect.notification);
  }

  /// Play sound sequence for special events
  Future<void> playVictorySequence() async {
    await playGameWin();
    // Could add more elaborate victory sounds here
  }

  /// Play sound for turn change
  Future<void> playTurnChange() async {
    await playNotification();
  }

  /// Getters for current state
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSfxEnabled => _isSfxEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  bool get isMusicPlaying => _isMusicPlaying;
  String? get currentTrack => _currentTrack;
  bool get isInitialized => _isInitialized;

  /// Get audio player states for debugging
  PlayerState get musicPlayerState => _musicPlayer.playerState;
  PlayerState get sfxPlayerState => _sfxPlayer.playerState;
}

/// Audio manager for easier integration with widgets
class AudioManager {
  static final AudioService _audioService = AudioService();

  /// Initialize audio system
  static Future<void> initialize() async {
    await _audioService.initialize();
  }

  /// Update audio settings from app settings
  static Future<void> updateSettings({
    required bool musicEnabled,
    required bool sfxEnabled,
    required double musicVolume,
    required double sfxVolume,
  }) async {
    await _audioService.setMusicEnabled(musicEnabled);
    _audioService.setSfxEnabled(sfxEnabled);
    await _audioService.setMusicVolume(musicVolume);
    await _audioService.setSfxVolume(sfxVolume);
  }

  /// Quick access to common sounds
  static Future<void> playDiceRoll() => _audioService.playDiceRoll();
  static Future<void> playTokenMove() => _audioService.playTokenMove();
  static Future<void> playTokenCapture() => _audioService.playTokenCapture();
  static Future<void> playGameWin() => _audioService.playGameWin();
  static Future<void> playButtonClick() => _audioService.playButtonClick();

  /// Background music control
  static Future<void> playMenuMusic() => 
      _audioService.playBackgroundMusic(track: 'background_menu');
  static Future<void> playGameMusic() => 
      _audioService.playBackgroundMusic(track: 'background_game');
  static Future<void> stopMusic() => _audioService.stopBackgroundMusic();
  static Future<void> pauseMusic() => _audioService.pauseBackgroundMusic();
  static Future<void> resumeMusic() => _audioService.resumeBackgroundMusic();

  /// Cleanup
  static Future<void> dispose() => _audioService.dispose();

  /// Getters
  static AudioService get instance => _audioService;
}

/// Audio feedback helper for UI interactions
class AudioFeedback {
  /// Play sound for button interactions
  static Future<void> buttonPress() async {
    await AudioManager.playButtonClick();
  }

  /// Play sound for successful actions
  static Future<void> success() async {
    await AudioManager.instance.playNotification();
  }

  /// Play sound for errors
  static Future<void> error() async {
    // Could implement error-specific sound
    await AudioManager.instance.playNotification();
  }

  /// Play sound for game events
  static Future<void> gameEvent(SoundEffect effect) async {
    await AudioManager.instance.playSoundEffect(effect);
  }
}

/// Audio preloader for better performance
class AudioPreloader {
  static final List<String> _preloadedTracks = [];
  static final List<SoundEffect> _preloadedSfx = [];

  /// Preload essential audio files
  static Future<void> preloadEssentialAudio() async {
    try {
      // Preload background tracks
      await _preloadTrack('background_menu');
      await _preloadTrack('background_game');

      // Preload essential sound effects
      await _preloadSfx(SoundEffect.diceRoll);
      await _preloadSfx(SoundEffect.tokenMove);
      await _preloadSfx(SoundEffect.buttonClick);

      debugPrint('Essential audio preloaded successfully');
    } catch (e) {
      debugPrint('Failed to preload audio: $e');
    }
  }

  static Future<void> _preloadTrack(String track) async {
    if (!_preloadedTracks.contains(track)) {
      // In a real implementation, you would preload the audio file here
      _preloadedTracks.add(track);
    }
  }

  static Future<void> _preloadSfx(SoundEffect effect) async {
    if (!_preloadedSfx.contains(effect)) {
      // In a real implementation, you would preload the sound effect here
      _preloadedSfx.add(effect);
    }
  }

  /// Check if audio is preloaded
  static bool isTrackPreloaded(String track) => _preloadedTracks.contains(track);
  static bool isSfxPreloaded(SoundEffect effect) => _preloadedSfx.contains(effect);
}