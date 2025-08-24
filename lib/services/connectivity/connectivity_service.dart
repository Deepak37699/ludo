import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Connectivity service for managing network state and online/offline transitions
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  static final StreamController<ConnectivityStatus> _statusController = 
      StreamController<ConnectivityStatus>.broadcast();

  static ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;

  /// Current connectivity status
  static ConnectivityStatus get currentStatus => _currentStatus;

  /// Stream of connectivity status changes
  static Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Check if device is currently online
  static bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Check if device is currently offline
  static bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  /// Initialize connectivity monitoring
  static Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        debugPrint('Connectivity monitoring error: $error');
      },
    );

    debugPrint('Connectivity service initialized - Status: $_currentStatus');
  }

  /// Check current connectivity status
  static Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      await _onConnectivityChanged(result);
    } catch (e) {
      debugPrint('Failed to check connectivity: $e');
      _updateStatus(ConnectivityStatus.unknown);
    }
  }

  /// Handle connectivity changes
  static Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    ConnectivityStatus newStatus;

    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        // Double-check with actual network request
        final hasInternet = await _testInternetConnection();
        newStatus = hasInternet 
          ? ConnectivityStatus.online 
          : ConnectivityStatus.offline;
        break;
      case ConnectivityResult.none:
        newStatus = ConnectivityStatus.offline;
        break;
      default:
        newStatus = ConnectivityStatus.unknown;
    }

    _updateStatus(newStatus);
  }

  /// Test actual internet connectivity
  static Future<bool> _testInternetConnection() async {
    try {
      // Simple connectivity test - can be enhanced with actual API call
      return true; // Simplified for now
    } catch (e) {
      return false;
    }
  }

  /// Update connectivity status
  static void _updateStatus(ConnectivityStatus newStatus) {
    if (_currentStatus != newStatus) {
      final previousStatus = _currentStatus;
      _currentStatus = newStatus;
      
      debugPrint('Connectivity changed: $previousStatus -> $newStatus');
      _statusController.add(newStatus);
      
      // Handle status transitions
      _handleStatusTransition(previousStatus, newStatus);
    }
  }

  /// Handle connectivity status transitions
  static void _handleStatusTransition(
    ConnectivityStatus from, 
    ConnectivityStatus to
  ) {
    if (from == ConnectivityStatus.online && to == ConnectivityStatus.offline) {
      _onGoingOffline();
    } else if (from == ConnectivityStatus.offline && to == ConnectivityStatus.online) {
      _onGoingOnline();
    }
  }

  /// Handle going offline
  static void _onGoingOffline() {
    debugPrint('Device went offline - switching to offline mode');
    // Notify other services about offline transition
    OfflineTransitionNotifier.notifyGoingOffline();
  }

  /// Handle going online
  static void _onGoingOnline() {
    debugPrint('Device came online - attempting to sync');
    // Notify other services about online transition
    OfflineTransitionNotifier.notifyGoingOnline();
  }

  /// Force connectivity check
  static Future<ConnectivityStatus> forceCheck() async {
    await _checkConnectivity();
    return _currentStatus;
  }

  /// Wait for online connectivity
  static Future<void> waitForOnline({Duration? timeout}) async {
    if (isOnline) return;

    final completer = Completer<void>();
    late StreamSubscription subscription;

    subscription = statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    // Handle timeout
    if (timeout != null) {
      Timer(timeout, () {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException(
            'Timeout waiting for online connectivity',
            timeout,
          ));
        }
      });
    }

    return completer.future;
  }

  /// Check if connectivity is stable
  static Future<bool> isConnectivityStable({
    Duration testDuration = const Duration(seconds: 5),
  }) async {
    if (!isOnline) return false;

    final startTime = DateTime.now();
    var wasOnline = true;

    final subscription = statusStream.listen((status) {
      if (status != ConnectivityStatus.online) {
        wasOnline = false;
      }
    });

    await Future.delayed(testDuration);
    subscription.cancel();

    return wasOnline && DateTime.now().difference(startTime) >= testDuration;
  }

  /// Get detailed connectivity information
  static Future<ConnectivityInfo> getConnectivityInfo() async {
    final result = await _connectivity.checkConnectivity();
    final hasInternet = await _testInternetConnection();

    return ConnectivityInfo(
      type: result,
      hasInternet: hasInternet,
      status: _currentStatus,
      lastChecked: DateTime.now(),
    );
  }

  /// Dispose connectivity service
  static Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _statusController.close();
  }
}

/// Connectivity status enum
enum ConnectivityStatus {
  online,
  offline,
  unknown,
}

/// Detailed connectivity information
class ConnectivityInfo {
  final ConnectivityResult type;
  final bool hasInternet;
  final ConnectivityStatus status;
  final DateTime lastChecked;

  const ConnectivityInfo({
    required this.type,
    required this.hasInternet,
    required this.status,
    required this.lastChecked,
  });

  String get displayName {
    switch (type) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.none:
        return 'No Connection';
      default:
        return 'Unknown';
    }
  }

  bool get isConnected => hasInternet && status == ConnectivityStatus.online;
}

/// Offline transition notifier for coordinating service responses
class OfflineTransitionNotifier {
  static final List<OfflineTransitionListener> _listeners = [];

  /// Register a listener for offline transitions
  static void addListener(OfflineTransitionListener listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  static void removeListener(OfflineTransitionListener listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners about going offline
  static void notifyGoingOffline() {
    for (final listener in _listeners) {
      try {
        listener.onGoingOffline();
      } catch (e) {
        debugPrint('Error notifying listener about going offline: $e');
      }
    }
  }

  /// Notify all listeners about going online
  static void notifyGoingOnline() {
    for (final listener in _listeners) {
      try {
        listener.onGoingOnline();
      } catch (e) {
        debugPrint('Error notifying listener about going online: $e');
      }
    }
  }

  /// Clear all listeners
  static void clearListeners() {
    _listeners.clear();
  }
}

/// Interface for offline transition listeners
abstract class OfflineTransitionListener {
  void onGoingOffline();
  void onGoingOnline();
}

/// Network-aware operation wrapper
class NetworkAwareOperation {
  /// Execute operation with network awareness
  static Future<T> execute<T>({
    required Future<T> Function() onlineOperation,
    required Future<T> Function() offlineOperation,
    Duration? timeout,
  }) async {
    if (ConnectivityService.isOnline) {
      try {
        if (timeout != null) {
          return await onlineOperation().timeout(timeout);
        } else {
          return await onlineOperation();
        }
      } catch (e) {
        // If online operation fails, fall back to offline
        debugPrint('Online operation failed, falling back to offline: $e');
        return await offlineOperation();
      }
    } else {
      return await offlineOperation();
    }
  }

  /// Execute operation with retry on connectivity
  static Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        if (ConnectivityService.isOnline) {
          return await operation();
        } else {
          // Wait for connectivity if offline
          await ConnectivityService.waitForOnline(
            timeout: retryDelay * (attempts + 1)
          );
          return await operation();
        }
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(retryDelay * attempts);
      }
    }
    
    throw Exception('Operation failed after $maxRetries attempts');
  }
}

/// Connectivity-aware cache with automatic sync
class ConnectivityAwareCache<T> {
  final Map<String, T> _cache = {};
  final Set<String> _pendingSync = {};

  /// Get item from cache
  T? get(String key) => _cache[key];

  /// Put item in cache and sync if online
  Future<void> put(String key, T value, {
    Future<void> Function(String key, T value)? syncOperation,
  }) async {
    _cache[key] = value;

    if (syncOperation != null) {
      if (ConnectivityService.isOnline) {
        try {
          await syncOperation(key, value);
        } catch (e) {
          // Mark for sync when online
          _pendingSync.add(key);
        }
      } else {
        _pendingSync.add(key);
      }
    }
  }

  /// Sync pending items when connectivity is restored
  Future<void> syncPending(
    Future<void> Function(String key, T value) syncOperation
  ) async {
    if (!ConnectivityService.isOnline) return;

    final keysToSync = Set<String>.from(_pendingSync);
    _pendingSync.clear();

    for (final key in keysToSync) {
      final value = _cache[key];
      if (value != null) {
        try {
          await syncOperation(key, value);
        } catch (e) {
          // Re-add to pending if sync fails
          _pendingSync.add(key);
        }
      }
    }
  }

  /// Check if item is pending sync
  bool isPendingSync(String key) => _pendingSync.contains(key);

  /// Get all pending sync keys
  Set<String> get pendingSyncKeys => Set.from(_pendingSync);

  /// Clear cache
  void clear() {
    _cache.clear();
    _pendingSync.clear();
  }
}