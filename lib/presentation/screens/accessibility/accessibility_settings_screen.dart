import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/accessibility_provider.dart';
import '../../providers/audio_provider.dart';
import '../../../services/accessibility/accessibility_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/animated_transitions.dart';

/// Screen for configuring accessibility features
class AccessibilitySettingsScreen extends ConsumerStatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  ConsumerState<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends ConsumerState<AccessibilitySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final accessibilityState = ref.watch(accessibilitySettingsProvider);
    final accessibilityStatus = ref.watch(accessibilityStatusProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility'),
        actions: [
          IconButton(
            onPressed: () => _showAccessibilityInfo(context),
            icon: const Icon(Icons.info_outline),
            tooltip: 'Accessibility Information',
          ),
        ],
      ),
      body: accessibilityState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Overview
                  _buildStatusOverview(accessibilityStatus, theme),
                  const SizedBox(height: 24),

                  // Visual Accessibility
                  _buildSectionCard(
                    'Visual Accessibility',
                    Icons.visibility,
                    [
                      _buildSwitchTile(
                        'High Contrast Mode',
                        'Increase contrast for better visibility',
                        accessibilityState.settings.highContrastMode,
                        (value) => _updateSetting('highContrast', value),
                        Icons.contrast,
                      ),
                      _buildSwitchTile(
                        'Large Text',
                        'Increase text size throughout the app',
                        accessibilityState.settings.largeTextMode,
                        (value) => _updateSetting('largeText', value),
                        Icons.text_fields,
                      ),
                      _buildSwitchTile(
                        'Color Blind Support',
                        'Use color blind friendly color schemes',
                        accessibilityState.settings.colorBlindSupport,
                        (value) => _updateSetting('colorBlind', value),
                        Icons.palette,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Motion & Animation
                  _buildSectionCard(
                    'Motion & Animation',
                    Icons.animation,
                    [
                      _buildSwitchTile(
                        'Reduce Motion',
                        'Minimize animations and transitions',
                        accessibilityState.settings.reducedMotion,
                        (value) => _updateSetting('reducedMotion', value),
                        Icons.motion_photos_off,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Audio & Feedback
                  _buildSectionCard(
                    'Audio & Feedback',
                    Icons.volume_up,
                    [
                      _buildSwitchTile(
                        'Screen Reader Support',
                        'Enable voice announcements for game events',
                        accessibilityState.settings.screenReaderEnabled,
                        (value) => _updateSetting('screenReader', value),
                        Icons.record_voice_over,
                      ),
                      _buildSwitchTile(
                        'Sound Cues',
                        'Play audio cues for game actions',
                        accessibilityState.settings.soundCuesEnabled,
                        (value) => _updateSetting('soundCues', value),
                        Icons.volume_up,
                      ),
                      _buildSwitchTile(
                        'Haptic Feedback',
                        'Vibration feedback for interactions',
                        accessibilityState.settings.hapticFeedbackEnabled,
                        (value) => _updateSetting('hapticFeedback', value),
                        Icons.vibration,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Input Methods
                  _buildSectionCard(
                    'Input Methods',
                    Icons.touch_app,
                    [
                      _buildSwitchTile(
                        'Alternative Input',
                        'Enable voice commands and switch control',
                        accessibilityState.settings.alternativeInputEnabled,
                        (value) => _updateSetting('alternativeInput', value),
                        Icons.keyboard_voice,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),
                  
                  // Error Display
                  if (accessibilityState.error != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorCard(accessibilityState.error!),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusOverview(AccessibilityStatus status, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.hasActiveFeatures ? Icons.accessibility : Icons.accessibility_new,
                  color: status.hasActiveFeatures ? Colors.green : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accessibility Status',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        status.hasActiveFeatures
                            ? '${status.activeFeatureCount} feature(s) active'
                            : 'No accessibility features enabled',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status.hasActiveFeatures) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildActiveFeatureChips(status),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActiveFeatureChips(AccessibilityStatus status) {
    final features = <Widget>[];
    
    if (status.isScreenReaderActive) {
      features.add(_buildFeatureChip('Screen Reader', Icons.record_voice_over));
    }
    if (status.isHighContrastActive) {
      features.add(_buildFeatureChip('High Contrast', Icons.contrast));
    }
    if (status.isLargeTextActive) {
      features.add(_buildFeatureChip('Large Text', Icons.text_fields));
    }
    if (status.isReducedMotionActive) {
      features.add(_buildFeatureChip('Reduced Motion', Icons.motion_photos_off));
    }
    if (status.isColorBlindSupportActive) {
      features.add(_buildFeatureChip('Color Blind Support', Icons.palette));
    }
    if (!status.isSoundCuesActive) {
      features.add(_buildFeatureChip('Sound Cues Off', Icons.volume_off));
    }
    if (!status.isHapticFeedbackActive) {
      features.add(_buildFeatureChip('Haptic Off', Icons.vibration));
    }
    if (status.isAlternativeInputActive) {
      features.add(_buildFeatureChip('Alternative Input', Icons.keyboard_voice));
    }
    
    return features;
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.green.shade100,
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            onPressed: _testAccessibilityFeatures,
            text: 'Test Features',
            icon: Icons.play_arrow,
            variant: ButtonVariant.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomButton(
            onPressed: _resetToDefaults,
            text: 'Reset to Defaults',
            icon: Icons.restore,
            variant: ButtonVariant.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
            IconButton(
              onPressed: () => ref.read(accessibilitySettingsProvider.notifier).clearError(),
              icon: Icon(Icons.close, color: Colors.red.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSetting(String key, bool value) async {
    await ref.read(audioActionsProvider).buttonClick();
    await ref.read(accessibilitySettingsProvider.notifier).updateSetting(key, value);
    
    // Provide immediate feedback
    if (key == 'hapticFeedback' && value) {
      await ref.read(accessibilityActionsProvider).hapticFeedback(HapticFeedbackType.light);
    }
    
    if (key == 'screenReader' && value) {
      await ref.read(accessibilityActionsProvider).announceSuccess('Screen reader enabled');
    }
  }

  Future<void> _testAccessibilityFeatures() async {
    await ref.read(audioActionsProvider).buttonClick();
    
    final actions = ref.read(accessibilityActionsProvider);
    
    // Test haptic feedback
    await actions.hapticFeedback(HapticFeedbackType.light);
    await Future.delayed(const Duration(milliseconds: 200));
    await actions.hapticFeedback(HapticFeedbackType.medium);
    await Future.delayed(const Duration(milliseconds: 200));
    await actions.hapticFeedback(HapticFeedbackType.heavy);
    
    // Test screen reader
    await actions.announceSuccess('Accessibility features test completed');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accessibility features tested successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    await ref.read(audioActionsProvider).buttonClick();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Accessibility Settings'),
        content: const Text(
          'This will reset all accessibility settings to their default values. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(accessibilitySettingsProvider.notifier).resetToDefaults();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accessibility settings reset to defaults'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showAccessibilityInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AccessibilityInfoDialog(),
    );
  }
}

/// Accessibility information dialog
class AccessibilityInfoDialog extends ConsumerWidget {
  const AccessibilityInfoDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameHelper = ref.watch(gameAccessibilityProvider);
    
    return AlertDialog(
      title: const Text('Accessibility Features'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection(
              'Screen Reader Support',
              'Enables voice announcements for:\n'
              '• Game state changes\n'
              '• Dice roll results\n'
              '• Token movements\n'
              '• Available moves\n'
              '• Game end notifications',
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              'Board Navigation',
              gameHelper.getBoardNavigationHelp(),
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              'Game Controls',
              gameHelper.getGameControlsHelp(),
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              'Visual Accessibility',
              'High contrast mode and large text options help users with visual impairments. '
              'Color blind support uses carefully selected colors for better distinction.',
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              'Haptic Feedback',
              'Provides vibration feedback for:\n'
              '• Button presses\n'
              '• Dice rolls\n'
              '• Token movements\n'
              '• Game events',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

/// Accessibility quick actions widget
class AccessibilityQuickActions extends ConsumerWidget {
  const AccessibilityQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(accessibilityStatusProvider);
    
    if (!status.hasActiveFeatures) {
      return const SizedBox.shrink();
    }
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.accessibility,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Accessibility features active',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/accessibility'),
              child: const Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}