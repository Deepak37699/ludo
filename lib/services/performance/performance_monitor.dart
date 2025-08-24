import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Performance monitoring service for tracking game metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // Performance metrics storage
  final Queue<FrameMetric> _frameMetrics = Queue<FrameMetric>();
  final Queue<MemoryMetric> _memoryMetrics = Queue<MemoryMetric>();
  final Map<String, List<int>> _operationTimes = {};
  
  // Configuration
  static const int _maxMetricsHistory = 100;
  static const Duration _monitoringInterval = Duration(seconds: 1);
  
  // State
  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  int _totalFrames = 0;
  int _droppedFrames = 0;

  /// Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _startFrameMetricsCollection();
    _startMemoryMonitoring();
    
    debugPrint('🚀 Performance monitoring started');
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    
    debugPrint('⏹️ Performance monitoring stopped');
  }

  /// Start collecting frame metrics
  void _startFrameMetricsCollection() {
    if (!kDebugMode) return;
    
    // In debug mode, we can monitor frame rendering
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _collectCurrentMetrics();
    });
  }

  /// Start memory monitoring
  void _startMemoryMonitoring() {
    Timer.periodic(_monitoringInterval, (_) {
      if (!_isMonitoring) return;
      _collectMemoryMetrics();
    });
  }

  /// Collect current performance metrics
  void _collectCurrentMetrics() {
    final now = DateTime.now();
    
    // Simulate frame metrics (in production, use actual frame timing)
    final frameTime = _calculateAverageFrameTime();
    final fps = frameTime > 0 ? 1000 / frameTime : 60.0;
    
    _frameMetrics.add(FrameMetric(
      timestamp: now,
      frameTime: frameTime,
      fps: fps,
      isJanky: frameTime > 16.67, // 60fps threshold
    ));
    
    // Keep only recent metrics
    while (_frameMetrics.length > _maxMetricsHistory) {
      _frameMetrics.removeFirst();
    }
  }

  /// Collect memory metrics
  void _collectMemoryMetrics() {
    // In a real implementation, use platform channels to get actual memory usage
    final memoryUsage = _estimateMemoryUsage();
    
    _memoryMetrics.add(MemoryMetric(
      timestamp: DateTime.now(),
      heapUsage: memoryUsage['heap'] ?? 0,
      stackUsage: memoryUsage['stack'] ?? 0,
      totalUsage: memoryUsage['total'] ?? 0,
    ));
    
    while (_memoryMetrics.length > _maxMetricsHistory) {
      _memoryMetrics.removeFirst();
    }
  }

  /// Measure operation performance
  Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      _recordOperationTime(operationName, stopwatch.elapsedMilliseconds);
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordOperationTime('$operationName-error', stopwatch.elapsedMilliseconds);
      rethrow;
    }
  }

  /// Measure synchronous operation performance
  T measureSync<T>(
    String operationName,
    T Function() operation,
  ) {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = operation();
      stopwatch.stop();
      
      _recordOperationTime(operationName, stopwatch.elapsedMilliseconds);
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordOperationTime('$operationName-error', stopwatch.elapsedMilliseconds);
      rethrow;
    }
  }

  /// Record operation timing
  void _recordOperationTime(String operationName, int milliseconds) {
    _operationTimes.putIfAbsent(operationName, () => []);
    _operationTimes[operationName]!.add(milliseconds);
    
    // Keep only recent measurements
    if (_operationTimes[operationName]!.length > 50) {
      _operationTimes[operationName]!.removeAt(0);
    }
  }

  /// Calculate average frame time
  double _calculateAverageFrameTime() {
    if (_frameMetrics.isEmpty) return 16.67; // 60fps baseline
    
    final recentMetrics = _frameMetrics.toList();
    if (recentMetrics.length < 5) return 16.67;
    
    final totalTime = recentMetrics
        .map((m) => m.frameTime)
        .reduce((a, b) => a + b);
    
    return totalTime / recentMetrics.length;
  }

  /// Estimate memory usage (placeholder implementation)
  Map<String, int> _estimateMemoryUsage() {
    // In production, use platform-specific memory APIs
    return {
      'heap': 50 * 1024 * 1024, // 50MB
      'stack': 2 * 1024 * 1024,  // 2MB
      'total': 52 * 1024 * 1024, // 52MB
    };
  }

  /// Get current performance summary
  PerformanceSummary getPerformanceSummary() {
    final frameMetrics = _frameMetrics.toList();
    final memoryMetrics = _memoryMetrics.toList();
    
    double avgFps = 60.0;
    double avgFrameTime = 16.67;
    int jankyFrames = 0;
    
    if (frameMetrics.isNotEmpty) {
      avgFps = frameMetrics.map((m) => m.fps).reduce((a, b) => a + b) / frameMetrics.length;
      avgFrameTime = frameMetrics.map((m) => m.frameTime).reduce((a, b) => a + b) / frameMetrics.length;
      jankyFrames = frameMetrics.where((m) => m.isJanky).length;
    }
    
    int currentMemory = 0;
    if (memoryMetrics.isNotEmpty) {
      currentMemory = memoryMetrics.last.totalUsage;
    }
    
    return PerformanceSummary(
      averageFps: avgFps,
      averageFrameTime: avgFrameTime,
      jankyFramePercentage: frameMetrics.isNotEmpty ? (jankyFrames / frameMetrics.length) * 100 : 0.0,
      memoryUsage: currentMemory,
      operationTimes: Map.from(_operationTimes),
    );
  }

  /// Check if performance is good
  bool get isPerformanceGood {
    final summary = getPerformanceSummary();
    return summary.averageFps >= 55.0 && 
           summary.jankyFramePercentage < 5.0 &&
           summary.memoryUsage < 100 * 1024 * 1024; // 100MB limit
  }

  /// Get performance warnings
  List<String> getPerformanceWarnings() {
    final warnings = <String>[];
    final summary = getPerformanceSummary();
    
    if (summary.averageFps < 50.0) {
      warnings.add('Low FPS detected: ${summary.averageFps.toStringAsFixed(1)} fps');
    }
    
    if (summary.jankyFramePercentage > 10.0) {
      warnings.add('High frame drops: ${summary.jankyFramePercentage.toStringAsFixed(1)}%');
    }
    
    if (summary.memoryUsage > 150 * 1024 * 1024) {
      warnings.add('High memory usage: ${(summary.memoryUsage / (1024 * 1024)).toStringAsFixed(1)} MB');
    }
    
    // Check slow operations
    for (final entry in summary.operationTimes.entries) {
      final avgTime = entry.value.isNotEmpty 
          ? entry.value.reduce((a, b) => a + b) / entry.value.length 
          : 0.0;
      
      if (avgTime > 100) {
        warnings.add('Slow operation "${entry.key}": ${avgTime.toStringAsFixed(1)}ms average');
      }
    }
    
    return warnings;
  }

  /// Export performance data for analysis
  Map<String, dynamic> exportPerformanceData() {
    return {
      'summary': getPerformanceSummary().toJson(),
      'frameMetrics': _frameMetrics.map((m) => m.toJson()).toList(),
      'memoryMetrics': _memoryMetrics.map((m) => m.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
      'isMonitoring': _isMonitoring,
    };
  }

  /// Clear all performance data
  void clearData() {
    _frameMetrics.clear();
    _memoryMetrics.clear();
    _operationTimes.clear();
    _totalFrames = 0;
    _droppedFrames = 0;
  }

  /// Log performance summary
  void logPerformanceSummary() {
    final summary = getPerformanceSummary();
    final warnings = getPerformanceWarnings();
    
    debugPrint('📊 Performance Summary:');
    debugPrint('   Average FPS: ${summary.averageFps.toStringAsFixed(1)}');
    debugPrint('   Average Frame Time: ${summary.averageFrameTime.toStringAsFixed(2)}ms');
    debugPrint('   Janky Frames: ${summary.jankyFramePercentage.toStringAsFixed(1)}%');
    debugPrint('   Memory Usage: ${(summary.memoryUsage / (1024 * 1024)).toStringAsFixed(1)} MB');
    
    if (warnings.isNotEmpty) {
      debugPrint('⚠️ Performance Warnings:');
      for (final warning in warnings) {
        debugPrint('   - $warning');
      }
    } else {
      debugPrint('✅ Performance is good!');
    }
  }
}

/// Frame performance metric
class FrameMetric {
  final DateTime timestamp;
  final double frameTime;
  final double fps;
  final bool isJanky;

  const FrameMetric({
    required this.timestamp,
    required this.frameTime,
    required this.fps,
    required this.isJanky,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'frameTime': frameTime,
    'fps': fps,
    'isJanky': isJanky,
  };
}

/// Memory performance metric
class MemoryMetric {
  final DateTime timestamp;
  final int heapUsage;
  final int stackUsage;
  final int totalUsage;

  const MemoryMetric({
    required this.timestamp,
    required this.heapUsage,
    required this.stackUsage,
    required this.totalUsage,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'heapUsage': heapUsage,
    'stackUsage': stackUsage,
    'totalUsage': totalUsage,
  };
}

/// Performance summary
class PerformanceSummary {
  final double averageFps;
  final double averageFrameTime;
  final double jankyFramePercentage;
  final int memoryUsage;
  final Map<String, List<int>> operationTimes;

  const PerformanceSummary({
    required this.averageFps,
    required this.averageFrameTime,
    required this.jankyFramePercentage,
    required this.memoryUsage,
    required this.operationTimes,
  });

  Map<String, dynamic> toJson() => {
    'averageFps': averageFps,
    'averageFrameTime': averageFrameTime,
    'jankyFramePercentage': jankyFramePercentage,
    'memoryUsage': memoryUsage,
    'operationTimes': operationTimes,
  };
}