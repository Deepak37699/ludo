import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/offline_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/audio_provider.dart';
import '../../../core/enums/game_enums.dart';
import '../../../data/models/player.dart';
import '../../../services/storage/offline_storage_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/game/difficulty_selector.dart';

/// Screen for offline game management and quick play
class OfflineGameScreen extends ConsumerStatefulWidget {
  const OfflineGameScreen({super.key});

  @override
  ConsumerState<OfflineGameScreen> createState() => _OfflineGameScreenState();
}

class _OfflineGameScreenState extends ConsumerState<OfflineGameScreen> {
  AIDifficulty selectedDifficulty = AIDifficulty.medium;
  final TextEditingController _playerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _playerNameController.text = 'Player';
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offlineGameState = ref.watch(offlineGameNotifierProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Game'),
        actions: [
          IconButton(
            onPressed: () => _showStorageInfo(context),
            icon: const Icon(Icons.storage),
            tooltip: 'Storage Info',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: offlineGameState.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connectivity Status
              _buildConnectivityStatus(isOnline, theme),
              const SizedBox(height: 24),

              // Continue Game Section
              if (offlineGameState.hasGameToContinue) ...[
                _buildContinueGameSection(theme),
                const SizedBox(height: 24),
              ],

              // Quick Game Section
              _buildQuickGameSection(theme),
              const SizedBox(height: 24),

              // Game Statistics
              _buildStatisticsSection(theme),
              const SizedBox(height: 24),

              // Storage Management
              _buildStorageSection(theme),

              // Error Display
              if (offlineGameState.error != null) ...[
                const SizedBox(height: 16),
                _buildErrorSection(offlineGameState.error!, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectivityStatus(bool isOnline, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            color: isOnline ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Text(
            isOnline ? 'Online Mode' : 'Offline Mode',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isOnline ? Colors.green.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (!isOnline)
            Text(
              'All progress saved locally',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContinueGameSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Continue Game',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You have a saved game in progress. Continue where you left off!',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            CustomButton(
              onPressed: _continueGame,
              text: 'Continue Game',
              icon: Icons.play_arrow,
              variant: ButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickGameSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Quick Game',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Player Name Input
            TextField(
              controller: _playerNameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // AI Difficulty Selector
            Text(
              'AI Difficulty',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DifficultySelector(
              selectedDifficulty: selectedDifficulty,
              onDifficultyChanged: (difficulty) {
                setState(() {
                  selectedDifficulty = difficulty;
                });
              },
            ),
            const SizedBox(height: 20),

            // Start Game Button
            CustomButton(
              onPressed: _startQuickGame,
              text: 'Start Quick Game',
              icon: Icons.play_arrow,
              variant: ButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(ThemeData theme) {
    final userStats = ref.watch(userStatsProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Your Statistics',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (userStats != null) ...[
              _buildStatItem('Games Played', userStats.gamesPlayed.toString()),
              _buildStatItem('Games Won', userStats.gamesWon.toString()),
              _buildStatItem('Win Rate', '${(userStats.winRate * 100).toStringAsFixed(1)}%'),
              _buildStatItem('Win Streak', userStats.winStreak.toString()),
              _buildStatItem('Best Streak', userStats.maxWinStreak.toString()),
              _buildStatItem('Tokens Finished', userStats.tokensFinished.toString()),
            ] else ...[
              Text(
                'No statistics available yet. Play your first game!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  Widget _buildStorageSection(ThemeData theme) {
    final storageInfo = ref.watch(offlineGameNotifierProvider).storageInfo;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Storage Management',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (storageInfo != null) ...[
              _buildStatItem('Storage Used', storageInfo.formattedSize),
              _buildStatItem('Saved Games', storageInfo.savedGamesCount.toString()),
              _buildStatItem('Game History', storageInfo.gameHistoryCount.toString()),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      onPressed: _refreshStorage,
                      text: 'Refresh',
                      icon: Icons.refresh,
                      variant: ButtonVariant.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      onPressed: () => _showClearDataDialog(context),
                      text: 'Clear Data',
                      icon: Icons.delete,
                      variant: ButtonVariant.danger,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection(String error, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
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
            onPressed: () => ref.read(offlineGameNotifierProvider.notifier).clearError(),
            icon: Icon(Icons.close, color: Colors.red.shade700),
          ),
        ],
      ),
    );
  }

  Future<void> _continueGame() async {
    await ref.read(audioActionsProvider).buttonClick();
    await ref.read(offlineGameNotifierProvider.notifier).continueLastGame();
    
    if (mounted) {
      Navigator.pushNamed(context, '/game');
    }
  }

  Future<void> _startQuickGame() async {
    await ref.read(audioActionsProvider).buttonClick();
    
    final playerName = _playerNameController.text.trim().isEmpty 
        ? 'Player' 
        : _playerNameController.text.trim();
    
    await ref.read(offlineGameNotifierProvider.notifier).startQuickGame(
      difficulty: selectedDifficulty,
      playerName: playerName,
    );
    
    if (mounted) {
      Navigator.pushNamed(context, '/game');
    }
  }

  Future<void> _refreshStorage() async {
    await ref.read(audioActionsProvider).buttonClick();
    await ref.read(offlineGameNotifierProvider.notifier).refreshStorageInfo();
  }

  void _showStorageInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const StorageInfoDialog(),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all saved games, statistics, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      await OfflineStorageService.clearAllData();
      await ref.read(offlineGameNotifierProvider.notifier).refreshStorageInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Storage information dialog
class StorageInfoDialog extends ConsumerWidget {
  const StorageInfoDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageInfoAsync = ref.watch(storageInfoProvider);
    final gameHistory = ref.watch(gameHistoryProvider);
    final savedGames = ref.watch(savedGamesProvider);

    return AlertDialog(
      title: const Text('Storage Information'),
      content: storageInfoAsync.when(
        data: (storageInfo) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Storage: ${storageInfo.formattedSize}'),
            const SizedBox(height: 8),
            Text('Saved Games: ${storageInfo.savedGamesCount}'),
            Text('Game History: ${storageInfo.gameHistoryCount}'),
            const SizedBox(height: 16),
            if (gameHistory.isNotEmpty) ...[
              const Text('Recent Games:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...gameHistory.take(3).map((game) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  '${game.mode.name} - ${game.winnerName ?? "No winner"}',
                  style: const TextStyle(fontSize: 12),
                ),
              )),
            ],
          ],
        ),
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Text('Error: $error'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}