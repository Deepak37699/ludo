import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../audio/audio_service.dart';
import 'performance_monitor.dart';

/// Performance optimization service for the Ludo game
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  // Cache management
  final LRUCache<String, dynamic> _cache = LRUCache<String, dynamic>(maxSize: 100);
  final Set<String> _preloadedAssets = {};
  final Map<String, Timer> _debounceTimers = {};
  
  // Resource pools
  final Queue<Paint> _paintPool = Queue<Paint>();
  final Queue<Path> _pathPool = Queue<Path>();
  
  // Performance settings
  bool _enableAdvancedOptimizations = true;
  bool _enableResourcePooling = true;
  bool _enableAssetPreloading = true;
  int _maxConcurrentOperations = 3;
  
  /// Initialize performance optimizations
  Future<void> initialize() async {
    await _initializeResourcePools();
    await _preloadCriticalAssets();
    _setupPerformanceMonitoring();
    
    debugPrint('🚀 Performance optimizer initialized');
  }

  /// Initialize resource pools
  Future<void> _initializeResourcePools() async {
    if (!_enableResourcePooling) return;
    
    // Pre-allocate Paint objects
    for (int i = 0; i < 20; i++) {
      _paintPool.add(Paint());
    }
    
    // Pre-allocate Path objects
    for (int i = 0; i < 10; i++) {
      _pathPool.add(Path());
    }
    
    debugPrint('🎨 Resource pools initialized');
  }

  /// Preload critical game assets
  Future<void> _preloadCriticalAssets() async {
    if (!_enableAssetPreloading) return;
    
    const criticalAssets = [
      'assets/images/board_background.png',
      'assets/images/dice_1.png',
      'assets/images/dice_2.png',
      'assets/images/dice_3.png',
      'assets/images/dice_4.png',
      'assets/images/dice_5.png',
      'assets/images/dice_6.png',
      'assets/images/token_red.png',
      'assets/images/token_blue.png',
      'assets/images/token_green.png',
      'assets/images/token_yellow.png',
    ];
    
    final futures = criticalAssets.map((asset) => _preloadAsset(asset));
    await Future.wait(futures);
    
    debugPrint('📦 Critical assets preloaded: ${_preloadedAssets.length}');
  }

  /// Preload a single asset
  Future<void> _preloadAsset(String assetPath) async {
    try {
      if (_preloadedAssets.contains(assetPath)) return;
      
      // Check if asset exists before trying to load
      try {
        await rootBundle.load(assetPath);
        _preloadedAssets.add(assetPath);
      } catch (e) {
        // Asset doesn't exist, skip silently
        debugPrint('Asset not found: $assetPath');
      }
    } catch (e) {
      debugPrint('Failed to preload asset $assetPath: $e');
    }
  }

  /// Setup performance monitoring
  void _setupPerformanceMonitoring() {
    PerformanceMonitor().startMonitoring();
    
    // Periodic performance checks
    Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndOptimizePerformance();
    });
  }

  /// Check and optimize performance based on metrics
  void _checkAndOptimizePerformance() {
    final monitor = PerformanceMonitor();
    final summary = monitor.getPerformanceSummary();
    
    // Adjust optimization level based on performance
    if (summary.averageFps < 45.0) {
      _enableAdvancedOptimizations = false;
      debugPrint('🐌 Disabling advanced optimizations due to low FPS');
    } else if (summary.averageFps > 55.0) {
      _enableAdvancedOptimizations = true;
    }
    
    // Memory pressure handling
    if (summary.memoryUsage > 100 * 1024 * 1024) { // 100MB
      _performMemoryCleanup();
    }
  }

  /// Perform memory cleanup
  void _performMemoryCleanup() {
    debugPrint('🧹 Performing memory cleanup');
    
    // Clear cache
    _cache.clear();
    
    // Clear unused resources
    _cleanupResourcePools();
    
    // Force garbage collection in debug mode
    if (kDebugMode) {
      // System.gc() equivalent for Dart
      // Note: Dart doesn't have explicit GC control, but we can trigger it indirectly
    }
    
    debugPrint('✅ Memory cleanup completed');
  }

  /// Cleanup resource pools
  void _cleanupResourcePools() {
    // Reset paint objects
    for (final paint in _paintPool) {
      paint.reset();
    }
    
    // Reset path objects
    for (final path in _pathPool) {
      path.reset();
    }
  }

  /// Get optimized Paint object from pool
  Paint getOptimizedPaint() {
    if (_enableResourcePooling && _paintPool.isNotEmpty) {
      final paint = _paintPool.removeFirst();
      paint.reset();
      return paint;
    }
    return Paint();
  }

  /// Return Paint object to pool
  void returnPaint(Paint paint) {
    if (_enableResourcePooling && _paintPool.length < 20) {
      paint.reset();
      _paintPool.add(paint);
    }
  }

  /// Get optimized Path object from pool
  Path getOptimizedPath() {
    if (_enableResourcePooling && _pathPool.isNotEmpty) {
      final path = _pathPool.removeFirst();
      path.reset();
      return path;
    }
    return Path();
  }

  /// Return Path object to pool
  void returnPath(Path path) {
    if (_enableResourcePooling && _pathPool.length < 10) {
      path.reset();
      _pathPool.add(path);
    }
  }

  /// Optimized cache get with performance tracking
  T? getCached<T>(String key) {
    return PerformanceMonitor().measureSync(
      'cache_get',
      () => _cache.get(key) as T?,
    );
  }

  /// Optimized cache put with performance tracking
  void putCached<T>(String key, T value) {
    PerformanceMonitor().measureSync(
      'cache_put',
      () => _cache.put(key, value),
    );
  }

  /// Debounced operation execution
  void debounce(String key, Duration delay, VoidCallback callback) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, () {
      callback();
      _debounceTimers.remove(key);
    });
  }

  /// Throttled operation execution
  void throttle(String key, Duration interval, VoidCallback callback) {
    if (_debounceTimers.containsKey(key)) return;
    
    callback();
    _debounceTimers[key] = Timer(interval, () {
      _debounceTimers.remove(key);
    });
  }

  /// Optimized image loading with caching
  Future<ImageProvider> loadOptimizedImage(String assetPath) async {
    return PerformanceMonitor().measureOperation(
      'load_image',
      () async {
        // Check cache first
        final cached = getCached<ImageProvider>(assetPath);
        if (cached != null) return cached;
        
        // Load and cache image
        final imageProvider = AssetImage(assetPath);
        putCached(assetPath, imageProvider);
        
        return imageProvider;
      },
    );
  }

  /// Batch operation executor with concurrency control
  Future<List<T>> executeBatch<T>(
    List<Future<T> Function()> operations, {
    int? maxConcurrency,
  }) async {
    final concurrency = maxConcurrency ?? _maxConcurrentOperations;
    final results = <T>[];
    
    for (int i = 0; i < operations.length; i += concurrency) {
      final batch = operations
          .skip(i)
          .take(concurrency)
          .map((op) => op())
          .toList();
      
      final batchResults = await Future.wait(batch);
      results.addAll(batchResults);
    }
    
    return results;
  }

  /// Optimized widget build with conditional rendering
  Widget buildOptimizedWidget({
    required Widget Function() builder,
    required bool condition,
    Widget? fallback,
  }) {
    if (!condition || !_enableAdvancedOptimizations) {
      return fallback ?? const SizedBox.shrink();
    }
    
    return builder();
  }

  /// Frame-aware animation controller
  AnimationController createOptimizedAnimationController({
    required Duration duration,
    required TickerProvider vsync,
  }) {
    // Adjust duration based on performance
    final adjustedDuration = _enableAdvancedOptimizations 
        ? duration 
        : Duration(milliseconds: (duration.inMilliseconds * 1.5).round());
    
    return AnimationController(
      duration: adjustedDuration,
      vsync: vsync,
    );
  }

  /// Optimize list rendering with viewport awareness
  Widget buildOptimizedList({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    double? itemExtent,
    bool shrinkWrap = false,
  }) {
    // Use different list implementations based on performance
    if (_enableAdvancedOptimizations && itemExtent != null) {
      return ListView.builder(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        itemExtent: itemExtent,
        shrinkWrap: shrinkWrap,
        cacheExtent: 200.0, // Optimized cache extent
      );
    } else {
      return ListView.builder(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        shrinkWrap: shrinkWrap,
        cacheExtent: 100.0, // Reduced cache for low performance
      );
    }
  }

  /// Lazy widget loader
  Widget buildLazyWidget({
    required Widget Function() builder,
    Widget? placeholder,
  }) {
    return FutureBuilder<Widget>(
      future: Future.microtask(builder),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!;
        }
        return placeholder ?? const CircularProgressIndicator();
      },
    );
  }

  /// Audio optimization settings
  void optimizeAudioPerformance() {
    final audioService = AudioService();
    
    if (!_enableAdvancedOptimizations) {
      // Reduce audio quality for performance
      audioService.setOptimizationMode(true);
    } else {
      audioService.setOptimizationMode(false);
    }
  }

  /// Get current optimization settings
  PerformanceSettings getPerformanceSettings() {
    return PerformanceSettings(
      enableAdvancedOptimizations: _enableAdvancedOptimizations,
      enableResourcePooling: _enableResourcePooling,
      enableAssetPreloading: _enableAssetPreloading,
      maxConcurrentOperations: _maxConcurrentOperations,
      cacheSize: _cache.maxSize,
      preloadedAssetsCount: _preloadedAssets.length,
    );
  }

  /// Update performance settings
  void updatePerformanceSettings(PerformanceSettings settings) {
    _enableAdvancedOptimizations = settings.enableAdvancedOptimizations;
    _enableResourcePooling = settings.enableResourcePooling;
    _enableAssetPreloading = settings.enableAssetPreloading;
    _maxConcurrentOperations = settings.maxConcurrentOperations;
    
    debugPrint('⚙️ Performance settings updated');
  }

  /// Dispose resources
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    
    _cache.clear();
    _preloadedAssets.clear();
    
    _cleanupResourcePools();
    
    PerformanceMonitor().stopMonitoring();
    
    debugPrint('🔄 Performance optimizer disposed');
  }
}

/// LRU Cache implementation
class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  LRUCache({required this.maxSize});

  V? get(K key) {
    if (_cache.containsKey(key)) {
      // Move to end (most recently used)
      final value = _cache.remove(key)!;
      _cache[key] = value;
      return value;
    }
    return null;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      // Remove least recently used
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  void clear() {
    _cache.clear();
  }

  int get length => _cache.length;
}

/// Performance settings configuration
class PerformanceSettings {
  final bool enableAdvancedOptimizations;
  final bool enableResourcePooling;
  final bool enableAssetPreloading;
  final int maxConcurrentOperations;
  final int cacheSize;
  final int preloadedAssetsCount;

  const PerformanceSettings({
    required this.enableAdvancedOptimizations,
    required this.enableResourcePooling,
    required this.enableAssetPreloading,
    required this.maxConcurrentOperations,
    required this.cacheSize,
    required this.preloadedAssetsCount,
  });

  Map<String, dynamic> toJson() => {
    'enableAdvancedOptimizations': enableAdvancedOptimizations,
    'enableResourcePooling': enableResourcePooling,
    'enableAssetPreloading': enableAssetPreloading,
    'maxConcurrentOperations': maxConcurrentOperations,
    'cacheSize': cacheSize,
    'preloadedAssetsCount': preloadedAssetsCount,
  };
}