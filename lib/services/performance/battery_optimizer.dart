import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../audio/audio_service.dart';
import 'performance_monitor.dart';

/// Battery optimization service to improve device battery life
class BatteryOptimizer {
  static final BatteryOptimizer _instance = BatteryOptimizer._internal();
  factory BatteryOptimizer() => _instance;
  BatteryOptimizer._internal();

  // Battery monitoring
  Timer? _batteryMonitor;
  BatteryLevel _currentBatteryLevel = BatteryLevel.normal;
  bool _isLowPowerMode = false;
  bool _isCharging = false;
  
  // Optimization settings
  bool _enableBatteryOptimizations = true;
  bool _enableAdaptiveBrightness = true;
  bool _enableCPUThrottling = false;
  bool _enableReducedAnimations = false;
  
  // Performance throttling
  int _frameRateLimit = 60;
  double _brightnessReduction = 0.0;
  Duration _backgroundTaskInterval = const Duration(seconds: 30);
  
  /// Initialize battery optimization
  Future<void> initialize() async {
    await _checkBatteryStatus();
    _startBatteryMonitoring();
    _applyInitialOptimizations();
    
    debugPrint('🔋 Battery optimizer initialized');
  }

  /// Start monitoring battery status
  void _startBatteryMonitoring() {
    _batteryMonitor = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateBatteryStatus();
    });
  }

  /// Check current battery status
  Future<void> _checkBatteryStatus() async {
    try {
      // In production, use battery_plus or similar plugin
      // For now, simulate battery status
      final batteryLevel = await _getBatteryLevel();
      final isCharging = await _getChargingStatus();
      
      _updateBatteryLevel(batteryLevel);
      _isCharging = isCharging;
      
    } catch (e) {
      debugPrint('Failed to check battery status: $e');
    }
  }

  /// Update battery status
  Future<void> _updateBatteryStatus() async {
    await _checkBatteryStatus();
    _adjustOptimizationsBasedOnBattery();
  }

  /// Get battery level (simulated)
  Future<int> _getBatteryLevel() async {
    // In production, use platform channel to get actual battery level
    // For simulation, return a value between 0-100
    return 75; // Mock 75% battery
  }

  /// Get charging status (simulated)
  Future<bool> _getChargingStatus() async {
    // In production, use platform channel to check charging status
    return false; // Mock not charging
  }

  /// Update battery level and apply optimizations
  void _updateBatteryLevel(int batteryPercent) {
    final previousLevel = _currentBatteryLevel;
    
    if (batteryPercent <= 10) {
      _currentBatteryLevel = BatteryLevel.critical;
    } else if (batteryPercent <= 20) {
      _currentBatteryLevel = BatteryLevel.low;
    } else if (batteryPercent <= 50) {
      _currentBatteryLevel = BatteryLevel.medium;
    } else {
      _currentBatteryLevel = BatteryLevel.normal;
    }
    
    // Apply optimizations if battery level changed
    if (previousLevel != _currentBatteryLevel) {
      _applyBatteryLevelOptimizations();
    }
  }

  /// Apply initial optimizations
  void _applyInitialOptimizations() {
    if (!_enableBatteryOptimizations) return;
    
    // Apply platform-specific optimizations
    if (Platform.isAndroid) {
      _applyAndroidOptimizations();
    } else if (Platform.isIOS) {
      _applyIOSOptimizations();
    }
  }

  /// Apply Android-specific optimizations
  void _applyAndroidOptimizations() {
    // Enable CPU throttling for older Android devices
    _enableCPUThrottling = true;
    
    // Reduce background task frequency
    _backgroundTaskInterval = const Duration(minutes: 1);
    
    debugPrint('📱 Android battery optimizations applied');
  }

  /// Apply iOS-specific optimizations
  void _applyIOSOptimizations() {
    // Enable adaptive brightness
    _enableAdaptiveBrightness = true;
    
    // Reduce animation complexity
    _enableReducedAnimations = true;
    
    debugPrint('🍎 iOS battery optimizations applied');
  }

  /// Adjust optimizations based on battery level
  void _adjustOptimizationsBasedOnBattery() {
    switch (_currentBatteryLevel) {
      case BatteryLevel.critical:
        _applyCriticalBatteryOptimizations();
        break;
      case BatteryLevel.low:
        _applyLowBatteryOptimizations();
        break;
      case BatteryLevel.medium:
        _applyMediumBatteryOptimizations();
        break;
      case BatteryLevel.normal:
        _applyNormalBatteryOptimizations();
        break;
    }
  }

  /// Apply critical battery optimizations (≤10%)
  void _applyCriticalBatteryOptimizations() {
    _frameRateLimit = 30;
    _brightnessReduction = 0.3;
    _enableReducedAnimations = true;
    _enableCPUThrottling = true;
    
    // Reduce audio quality
    AudioService().setBatteryOptimizationMode(BatteryOptimizationMode.aggressive);
    
    debugPrint('⚠️ Critical battery optimizations applied');
  }

  /// Apply low battery optimizations (≤20%)
  void _applyLowBatteryOptimizations() {
    _frameRateLimit = 45;
    _brightnessReduction = 0.2;
    _enableReducedAnimations = true;
    
    // Reduce audio quality slightly
    AudioService().setBatteryOptimizationMode(BatteryOptimizationMode.moderate);
    
    debugPrint('🔋 Low battery optimizations applied');
  }

  /// Apply medium battery optimizations (≤50%)
  void _applyMediumBatteryOptimizations() {
    _frameRateLimit = 55;
    _brightnessReduction = 0.1;
    _enableReducedAnimations = false;
    
    // Normal audio quality
    AudioService().setBatteryOptimizationMode(BatteryOptimizationMode.light);
    
    debugPrint('🔋 Medium battery optimizations applied');
  }

  /// Apply normal battery optimizations (>50%)
  void _applyNormalBatteryOptimizations() {
    _frameRateLimit = 60;
    _brightnessReduction = 0.0;
    _enableReducedAnimations = false;
    _enableCPUThrottling = false;
    
    // Full audio quality
    AudioService().setBatteryOptimizationMode(BatteryOptimizationMode.none);
    
    debugPrint('✅ Normal battery mode');
  }

  /// Apply battery level optimizations
  void _applyBatteryLevelOptimizations() {
    debugPrint('🔋 Battery level changed to: ${_currentBatteryLevel.name}');
    _adjustOptimizationsBasedOnBattery();
  }

  /// Enable low power mode
  void enableLowPowerMode() {
    _isLowPowerMode = true;
    
    // Apply aggressive optimizations
    _frameRateLimit = 30;
    _brightnessReduction = 0.4;
    _enableReducedAnimations = true;
    _enableCPUThrottling = true;
    
    // Disable haptic feedback
    HapticFeedback.vibrate();
    
    // Reduce network requests
    _backgroundTaskInterval = const Duration(minutes: 5);
    
    debugPrint('🐌 Low power mode enabled');
  }

  /// Disable low power mode
  void disableLowPowerMode() {
    _isLowPowerMode = false;
    
    // Restore normal optimizations based on battery level
    _adjustOptimizationsBasedOnBattery();
    
    debugPrint('⚡ Low power mode disabled');
  }

  /// Optimize game performance for battery saving
  GamePerformanceConfig getOptimizedGameConfig() {
    return GamePerformanceConfig(
      frameRateLimit: _frameRateLimit,
      enableShadows: !_enableReducedAnimations && _currentBatteryLevel == BatteryLevel.normal,
      enableParticles: _currentBatteryLevel == BatteryLevel.normal,
      enableComplexAnimations: !_enableReducedAnimations,
      enableHapticFeedback: !_isLowPowerMode,
      audioQuality: _getAudioQuality(),
      backgroundTaskInterval: _backgroundTaskInterval,
      enableNetworkOptimizations: _currentBatteryLevel != BatteryLevel.normal,
    );
  }

  /// Get audio quality based on battery level
  AudioQuality _getAudioQuality() {
    if (_isLowPowerMode || _currentBatteryLevel == BatteryLevel.critical) {
      return AudioQuality.low;
    } else if (_currentBatteryLevel == BatteryLevel.low) {
      return AudioQuality.medium;
    } else {
      return AudioQuality.high;
    }
  }

  /// Optimize widget rendering for battery
  Widget optimizeWidgetForBattery({
    required Widget child,
    bool enableOptimizations = true,
  }) {
    if (!enableOptimizations || !_enableBatteryOptimizations) {
      return child;
    }
    
    // Apply optimizations based on battery level
    Widget optimizedChild = child;
    
    if (_enableReducedAnimations) {
      // Wrap with reduced animation widget
      optimizedChild = _ReducedAnimationWrapper(child: optimizedChild);
    }
    
    if (_brightnessReduction > 0) {
      // Apply brightness reduction
      optimizedChild = _BrightnessReducer(
        reduction: _brightnessReduction,
        child: optimizedChild,
      );
    }
    
    return optimizedChild;
  }

  /// Schedule battery-friendly background task
  void scheduleBackgroundTask(VoidCallback task) {
    Timer(_backgroundTaskInterval, () {
      if (!_isLowPowerMode) {
        task();
      }
    });
  }

  /// Get current battery status
  BatteryStatus getBatteryStatus() {
    return BatteryStatus(
      level: _currentBatteryLevel,
      isCharging: _isCharging,
      isLowPowerMode: _isLowPowerMode,
      frameRateLimit: _frameRateLimit,
      brightnessReduction: _brightnessReduction,
      optimizationsEnabled: _enableBatteryOptimizations,
    );
  }

  /// Update battery optimization settings
  void updateSettings({
    bool? enableBatteryOptimizations,
    bool? enableAdaptiveBrightness,
    bool? enableCPUThrottling,
  }) {
    _enableBatteryOptimizations = enableBatteryOptimizations ?? _enableBatteryOptimizations;
    _enableAdaptiveBrightness = enableAdaptiveBrightness ?? _enableAdaptiveBrightness;
    _enableCPUThrottling = enableCPUThrottling ?? _enableCPUThrottling;
    
    // Reapply optimizations
    _adjustOptimizationsBasedOnBattery();
    
    debugPrint('⚙️ Battery optimization settings updated');
  }

  /// Get battery optimization recommendations
  List<BatteryOptimizationTip> getOptimizationTips() {
    final tips = <BatteryOptimizationTip>[];
    
    if (_currentBatteryLevel == BatteryLevel.low || _currentBatteryLevel == BatteryLevel.critical) {
      tips.add(BatteryOptimizationTip(
        title: 'Enable Low Power Mode',
        description: 'Reduce performance to extend battery life',
        action: enableLowPowerMode,
      ));
    }
    
    if (!_enableBatteryOptimizations) {
      tips.add(BatteryOptimizationTip(
        title: 'Enable Battery Optimizations',
        description: 'Allow automatic battery saving features',
        action: () => updateSettings(enableBatteryOptimizations: true),
      ));
    }
    
    if (_brightnessReduction == 0.0 && _currentBatteryLevel != BatteryLevel.normal) {
      tips.add(BatteryOptimizationTip(
        title: 'Reduce Screen Brightness',
        description: 'Lower brightness to save battery',
        action: () => _brightnessReduction = 0.2,
      ));
    }
    
    return tips;
  }

  /// Dispose battery optimizer
  void dispose() {
    _batteryMonitor?.cancel();
    _batteryMonitor = null;
    
    debugPrint('🔋 Battery optimizer disposed');
  }
}

/// Battery optimization levels
enum BatteryLevel {
  critical,
  low,
  medium,
  normal,
}

/// Audio quality levels for battery optimization
enum AudioQuality {
  low,
  medium,
  high,
}

/// Battery optimization modes for audio
enum BatteryOptimizationMode {
  none,
  light,
  moderate,
  aggressive,
}

/// Game performance configuration
class GamePerformanceConfig {
  final int frameRateLimit;
  final bool enableShadows;
  final bool enableParticles;
  final bool enableComplexAnimations;
  final bool enableHapticFeedback;
  final AudioQuality audioQuality;
  final Duration backgroundTaskInterval;
  final bool enableNetworkOptimizations;

  const GamePerformanceConfig({
    required this.frameRateLimit,
    required this.enableShadows,
    required this.enableParticles,
    required this.enableComplexAnimations,
    required this.enableHapticFeedback,
    required this.audioQuality,
    required this.backgroundTaskInterval,
    required this.enableNetworkOptimizations,
  });
}

/// Battery status information
class BatteryStatus {
  final BatteryLevel level;
  final bool isCharging;
  final bool isLowPowerMode;
  final int frameRateLimit;
  final double brightnessReduction;
  final bool optimizationsEnabled;

  const BatteryStatus({
    required this.level,
    required this.isCharging,
    required this.isLowPowerMode,
    required this.frameRateLimit,
    required this.brightnessReduction,
    required this.optimizationsEnabled,
  });

  Map<String, dynamic> toJson() => {
    'level': level.name,
    'isCharging': isCharging,
    'isLowPowerMode': isLowPowerMode,
    'frameRateLimit': frameRateLimit,
    'brightnessReduction': brightnessReduction,
    'optimizationsEnabled': optimizationsEnabled,
  };
}

/// Battery optimization tip
class BatteryOptimizationTip {
  final String title;
  final String description;
  final VoidCallback action;

  const BatteryOptimizationTip({
    required this.title,
    required this.description,
    required this.action,
  });
}

/// Widget wrapper for reduced animations
class _ReducedAnimationWrapper extends StatelessWidget {
  final Widget child;

  const _ReducedAnimationWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150), // Reduced from default
      child: child,
    );
  }
}

/// Widget wrapper for brightness reduction
class _BrightnessReducer extends StatelessWidget {
  final double reduction;
  final Widget child;

  const _BrightnessReducer({
    required this.reduction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix([
        1 - reduction, 0, 0, 0, 0,
        0, 1 - reduction, 0, 0, 0,
        0, 0, 1 - reduction, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: child,
    );
  }
}