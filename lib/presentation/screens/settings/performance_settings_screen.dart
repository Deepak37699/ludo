import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/performance/performance_optimizer.dart';
import '../../../services/performance/performance_monitor.dart';
import '../../../services/performance/battery_optimizer.dart';
import '../../providers/optimized_game_provider.dart';

/// Performance settings screen for configuring optimization options
class PerformanceSettingsScreen extends ConsumerStatefulWidget {
  const PerformanceSettingsScreen({super.key});

  @override
  ConsumerState<PerformanceSettingsScreen> createState() => _PerformanceSettingsScreenState();
}

class _PerformanceSettingsScreenState extends ConsumerState<PerformanceSettingsScreen> {
  late PerformanceSettings _settings;
  late BatteryStatus _batteryStatus;
  
  @override
  void initState() {
    super.initState();
    _settings = PerformanceOptimizer().getPerformanceSettings();
    _batteryStatus = BatteryOptimizer().getBatteryStatus();
  }

  @override
  Widget build(BuildContext context) {
    final performanceSummary = ref.watch(performanceSummaryProvider);
    final isPerformanceGood = ref.watch(isPerformanceGoodProvider);
    final warnings = ref.watch(performanceWarningsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Settings'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showPerformanceInfo,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPerformanceStatus(performanceSummary, isPerformanceGood, warnings),
          const SizedBox(height: 24),
          _buildGeneralSettings(),
          const SizedBox(height: 24),
          _buildBatterySettings(),
          const SizedBox(height: 24),
          _buildGraphicsSettings(),
          const SizedBox(height: 24),
          _buildAdvancedSettings(),
          const SizedBox(height: 24),
          _buildPerformanceActions(),
        ],
      ),
    );
  }

  /// Build performance status section
  Widget _buildPerformanceStatus(
    PerformanceSummary summary,
    bool isGood,
    List<String> warnings,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isGood ? Icons.check_circle : Icons.warning,
                  color: isGood ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Average FPS', '${summary.averageFps.toStringAsFixed(1)} fps'),
            _buildMetricRow('Frame Time', '${summary.averageFrameTime.toStringAsFixed(2)} ms'),
            _buildMetricRow('Janky Frames', '${summary.jankyFramePercentage.toStringAsFixed(1)}%'),
            _buildMetricRow('Memory Usage', '${(summary.memoryUsage / (1024 * 1024)).toStringAsFixed(1)} MB'),
            
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Performance Warnings:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              ...warnings.map((warning) => Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(warning, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  /// Build metric row
  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Build general settings section
  Widget _buildGeneralSettings() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Advanced Optimizations'),
              subtitle: const Text('Use advanced performance optimizations'),
              value: _settings.enableAdvancedOptimizations,
              onChanged: (value) {
                setState(() {
                  _settings = PerformanceSettings(
                    enableAdvancedOptimizations: value,
                    enableResourcePooling: _settings.enableResourcePooling,
                    enableAssetPreloading: _settings.enableAssetPreloading,
                    maxConcurrentOperations: _settings.maxConcurrentOperations,
                    cacheSize: _settings.cacheSize,
                    preloadedAssetsCount: _settings.preloadedAssetsCount,
                  );
                });
                _updateSettings();
              },
            ),
            SwitchListTile(
              title: const Text('Enable Resource Pooling'),
              subtitle: const Text('Reuse objects to reduce garbage collection'),
              value: _settings.enableResourcePooling,
              onChanged: (value) {
                setState(() {
                  _settings = PerformanceSettings(
                    enableAdvancedOptimizations: _settings.enableAdvancedOptimizations,
                    enableResourcePooling: value,
                    enableAssetPreloading: _settings.enableAssetPreloading,
                    maxConcurrentOperations: _settings.maxConcurrentOperations,
                    cacheSize: _settings.cacheSize,
                    preloadedAssetsCount: _settings.preloadedAssetsCount,
                  );
                });
                _updateSettings();
              },
            ),
            SwitchListTile(
              title: const Text('Enable Asset Preloading'),
              subtitle: const Text('Load game assets in advance'),
              value: _settings.enableAssetPreloading,
              onChanged: (value) {
                setState(() {
                  _settings = PerformanceSettings(
                    enableAdvancedOptimizations: _settings.enableAdvancedOptimizations,
                    enableResourcePooling: _settings.enableResourcePooling,
                    enableAssetPreloading: value,
                    maxConcurrentOperations: _settings.maxConcurrentOperations,
                    cacheSize: _settings.cacheSize,
                    preloadedAssetsCount: _settings.preloadedAssetsCount,
                  );
                });
                _updateSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build battery settings section
  Widget _buildBatterySettings() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Battery Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Battery status
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: _getBatteryLevelColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getBatteryLevelColor()),
              ),
              child: Row(
                children: [
                  Icon(
                    _getBatteryIcon(),
                    color: _getBatteryLevelColor(),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Battery Level: ${_batteryStatus.level.name.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _batteryStatus.isCharging ? 'Charging' : 'Not charging',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Low Power Mode'),
              subtitle: Text(_batteryStatus.isLowPowerMode 
                  ? 'Performance reduced to save battery'
                  : 'Normal performance mode'),
              value: _batteryStatus.isLowPowerMode,
              onChanged: (value) {
                if (value) {
                  BatteryOptimizer().enableLowPowerMode();
                } else {
                  BatteryOptimizer().disableLowPowerMode();
                }
                setState(() {
                  _batteryStatus = BatteryOptimizer().getBatteryStatus();
                });
              },
            ),
            
            ListTile(
              title: const Text('Frame Rate Limit'),
              subtitle: Text('Current: ${_batteryStatus.frameRateLimit} fps'),
              trailing: const Icon(Icons.speed),
            ),
            
            if (_batteryStatus.brightnessReduction > 0) ...[
              ListTile(
                title: const Text('Brightness Reduction'),
                subtitle: Text('${(_batteryStatus.brightnessReduction * 100).toStringAsFixed(0)}% reduced'),
                trailing: const Icon(Icons.brightness_6),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build graphics settings section
  Widget _buildGraphicsSettings() {
    final config = BatteryOptimizer().getOptimizedGameConfig();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Graphics Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            _buildToggleListTile(
              title: 'Enable Shadows',
              subtitle: 'Add depth with shadow effects',
              value: config.enableShadows,
              icon: Icons.brightness_7,
            ),
            
            _buildToggleListTile(
              title: 'Enable Particles',
              subtitle: 'Show particle effects and animations',
              value: config.enableParticles,
              icon: Icons.auto_awesome,
            ),
            
            _buildToggleListTile(
              title: 'Complex Animations',
              subtitle: 'Use advanced animation effects',
              value: config.enableComplexAnimations,
              icon: Icons.animation,
            ),
            
            _buildToggleListTile(
              title: 'Haptic Feedback',
              subtitle: 'Vibration feedback for interactions',
              value: config.enableHapticFeedback,
              icon: Icons.vibration,
            ),
            
            ListTile(
              leading: const Icon(Icons.audiotrack),
              title: const Text('Audio Quality'),
              subtitle: Text(config.audioQuality.name.toUpperCase()),
              trailing: _getAudioQualityIcon(config.audioQuality),
            ),
          ],
        ),
      ),
    );
  }

  /// Build advanced settings section
  Widget _buildAdvancedSettings() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.memory),
              title: const Text('Cache Size'),
              subtitle: Text('${_settings.cacheSize} items'),
              trailing: const Icon(Icons.storage),
            ),
            
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Preloaded Assets'),
              subtitle: Text('${_settings.preloadedAssetsCount} assets'),
              trailing: const Icon(Icons.check_circle_outline),
            ),
            
            ListTile(
              leading: const Icon(Icons.settings_input_composite),
              title: const Text('Max Concurrent Operations'),
              subtitle: Text('${_settings.maxConcurrentOperations} operations'),
              trailing: Slider(
                value: _settings.maxConcurrentOperations.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) {
                  setState(() {
                    _settings = PerformanceSettings(
                      enableAdvancedOptimizations: _settings.enableAdvancedOptimizations,
                      enableResourcePooling: _settings.enableResourcePooling,
                      enableAssetPreloading: _settings.enableAssetPreloading,
                      maxConcurrentOperations: value.round(),
                      cacheSize: _settings.cacheSize,
                      preloadedAssetsCount: _settings.preloadedAssetsCount,
                    );
                  });
                  _updateSettings();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build performance actions section
  Widget _buildPerformanceActions() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearCache,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Cache'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _optimizeNow,
                    icon: const Icon(Icons.speed),
                    label: const Text('Optimize Now'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportPerformanceData,
                    icon: const Icon(Icons.file_download),
                    label: const Text('Export Data'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetToDefaults,
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset Defaults'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build toggle list tile
  Widget _buildToggleListTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          // In a real implementation, update the specific setting
          setState(() {});
        },
      ),
    );
  }

  /// Get battery level color
  Color _getBatteryLevelColor() {
    switch (_batteryStatus.level) {
      case BatteryLevel.critical:
        return Colors.red;
      case BatteryLevel.low:
        return Colors.orange;
      case BatteryLevel.medium:
        return Colors.yellow;
      case BatteryLevel.normal:
        return Colors.green;
    }
  }

  /// Get battery icon
  IconData _getBatteryIcon() {
    if (_batteryStatus.isCharging) {
      return Icons.battery_charging_full;
    }
    
    switch (_batteryStatus.level) {
      case BatteryLevel.critical:
        return Icons.battery_alert;
      case BatteryLevel.low:
        return Icons.battery_2_bar;
      case BatteryLevel.medium:
        return Icons.battery_5_bar;
      case BatteryLevel.normal:
        return Icons.battery_full;
    }
  }

  /// Get audio quality icon
  Widget _getAudioQualityIcon(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.low:
        return const Icon(Icons.volume_down, color: Colors.red);
      case AudioQuality.medium:
        return const Icon(Icons.volume_mute, color: Colors.orange);
      case AudioQuality.high:
        return const Icon(Icons.volume_up, color: Colors.green);
    }
  }

  /// Update performance settings
  void _updateSettings() {
    PerformanceOptimizer().updatePerformanceSettings(_settings);
    ref.read(performanceSettingsProvider.notifier).state = _settings;
  }

  /// Clear cache
  void _clearCache() {
    ref.read(optimizedGameProvider.notifier).clearCache();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared successfully')),
    );
  }

  /// Optimize performance now
  void _optimizeNow() {
    // Trigger immediate optimization
    setState(() {
      _batteryStatus = BatteryOptimizer().getBatteryStatus();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Performance optimized')),
    );
  }

  /// Export performance data
  void _exportPerformanceData() {
    final data = PerformanceMonitor().exportPerformanceData();
    // In a real implementation, save to file or share
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Performance data exported')),
    );
  }

  /// Reset to default settings
  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('This will reset all performance settings to their default values. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _settings = const PerformanceSettings(
                  enableAdvancedOptimizations: true,
                  enableResourcePooling: true,
                  enableAssetPreloading: true,
                  maxConcurrentOperations: 3,
                  cacheSize: 100,
                  preloadedAssetsCount: 0,
                );
              });
              _updateSettings();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  /// Show performance information dialog
  void _showPerformanceInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Information'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Frame Rate (FPS)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Higher is better. 60 FPS is ideal for smooth gameplay.'),
              SizedBox(height: 12),
              
              Text(
                'Frame Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Lower is better. Under 16.67ms maintains 60 FPS.'),
              SizedBox(height: 12),
              
              Text(
                'Janky Frames',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Percentage of frames that took too long to render. Lower is better.'),
              SizedBox(height: 12),
              
              Text(
                'Memory Usage',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Amount of RAM used by the game. Lower usage leaves more memory for the system.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}