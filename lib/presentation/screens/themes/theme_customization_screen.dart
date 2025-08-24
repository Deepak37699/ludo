import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../providers/audio_provider.dart';
import '../../../services/themes/theme_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/animated_transitions.dart';

/// Screen for theme customization and selection
class ThemeCustomizationScreen extends ConsumerStatefulWidget {
  const ThemeCustomizationScreen({super.key});

  @override
  ConsumerState<ThemeCustomizationScreen> createState() => _ThemeCustomizationScreenState();
}

class _ThemeCustomizationScreenState extends ConsumerState<ThemeCustomizationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _previewGameTheme;
  String? _previewBoardTheme;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeCustomizationProvider);
    final themeStats = ref.watch(themeStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Themes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Game Themes', icon: Icon(Icons.palette)),
            Tab(text: 'Board Themes', icon: Icon(Icons.grid_on)),
            Tab(text: 'Combinations', icon: Icon(Icons.auto_fix_high)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showThemeStats(context, themeStats),
            icon: const Icon(Icons.analytics),
            tooltip: 'Theme Statistics',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress overview
          _buildProgressOverview(themeStats, theme),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGameThemesTab(themeState),
                _buildBoardThemesTab(themeState),
                _buildCombinationsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(themeState),
    );
  }

  Widget _buildProgressOverview(ThemeStats stats, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Unlocked',
                  '${stats.unlockedThemes}/${stats.totalThemes}',
                  Icons.lock_open,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Premium',
                  stats.premiumThemes.toString(),
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Progress',
                  '${(stats.completionPercentage * 100).toStringAsFixed(0)}%',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedProgressBar(
            progress: stats.completionPercentage,
            height: 8,
            backgroundColor: Colors.grey.shade300,
            valueColor: theme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameThemesTab(ThemeCustomizationState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Unlocked'),
              Tab(text: 'Locked'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildThemeGrid(state.getUnlockedGameThemes(), true),
                _buildThemeGrid(state.getLockedGameThemes(), false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardThemesTab(ThemeCustomizationState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Unlocked'),
              Tab(text: 'Locked'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildBoardThemeGrid(state.getUnlockedBoardThemes(), true),
                _buildBoardThemeGrid(state.getLockedBoardThemes(), false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeGrid(List<GameThemeData> themes, bool isUnlocked) {
    if (themes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnlocked ? Icons.palette : Icons.lock,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isUnlocked ? 'No themes unlocked' : 'No locked themes',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final currentTheme = ref.watch(themeCustomizationProvider).customization;
        final isSelected = theme.id == currentTheme.gameThemeId;
        
        return GameThemeCard(
          theme: theme,
          isSelected: isSelected,
          isUnlocked: isUnlocked,
          onTap: () => _selectGameTheme(theme.id, isUnlocked),
          onPreview: () => _previewGameTheme(theme.id),
        );
      },
    );
  }

  Widget _buildBoardThemeGrid(List<BoardThemeData> themes, bool isUnlocked) {
    if (themes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnlocked ? Icons.grid_on : Icons.lock,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isUnlocked ? 'No board themes unlocked' : 'No locked board themes',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final currentTheme = ref.watch(themeCustomizationProvider).customization;
        final isSelected = theme.id == currentTheme.boardThemeId;
        
        return BoardThemeCard(
          theme: theme,
          isSelected: isSelected,
          isUnlocked: isUnlocked,
          onTap: () => _selectBoardTheme(theme.id, isUnlocked),
          onPreview: () => _previewBoardTheme(theme.id),
        );
      },
    );
  }

  Widget _buildCombinationsTab() {
    final combinations = ref.read(themeActionsProvider).getRecommendedCombinations();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: combinations.length,
      itemBuilder: (context, index) {
        final combination = combinations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ThemeCombinationCard(
            combination: combination,
            onApply: () => _applyCombination(combination),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(ThemeCustomizationState state) {
    if (state.error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade50,
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
            IconButton(
              onPressed: () => ref.read(themeCustomizationProvider.notifier).clearError(),
              icon: Icon(Icons.close, color: Colors.red.shade700),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Current: ${state.currentGameTheme?.name ?? 'Unknown'} + ${state.currentBoardTheme?.name ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          CustomButton(
            onPressed: _resetToDefault,
            text: 'Reset',
            variant: ButtonVariant.secondary,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  Future<void> _selectGameTheme(String themeId, bool isUnlocked) async {
    await ref.read(audioActionsProvider).buttonClick();
    
    if (isUnlocked) {
      await ref.read(themeCustomizationProvider.notifier).changeGameTheme(themeId);
    } else {
      _showUnlockDialog(themeId);
    }
  }

  Future<void> _selectBoardTheme(String themeId, bool isUnlocked) async {
    await ref.read(audioActionsProvider).buttonClick();
    
    if (isUnlocked) {
      await ref.read(themeCustomizationProvider.notifier).changeBoardTheme(themeId);
    } else {
      _showUnlockDialog(themeId);
    }
  }

  void _previewGameTheme(String themeId) {
    setState(() {
      _previewGameTheme = themeId;
    });
    
    // Auto-clear preview after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _previewGameTheme = null;
        });
      }
    });
  }

  void _previewBoardTheme(String themeId) {
    setState(() {
      _previewBoardTheme = themeId;
    });
    
    // Auto-clear preview after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _previewBoardTheme = null;
        });
      }
    });
  }

  Future<void> _applyCombination(ThemeCombination combination) async {
    await ref.read(audioActionsProvider).buttonClick();
    await ref.read(themeActionsProvider).applyThemeCombination(
      combination.gameThemeId,
      combination.boardThemeId,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied ${combination.name}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _resetToDefault() async {
    await ref.read(audioActionsProvider).buttonClick();
    await ref.read(themeCustomizationProvider.notifier).resetToDefault();
  }

  void _showUnlockDialog(String themeId) {
    final requirements = ref.read(themeActionsProvider).getThemeUnlockRequirements(themeId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This theme is locked. To unlock it:'),
            const SizedBox(height: 12),
            ...requirements.map((req) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(req.description)),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (requirements.any((r) => r.type == 'purchase'))
            ElevatedButton(
              onPressed: () => _purchaseTheme(themeId),
              child: const Text('Purchase'),
            ),
        ],
      ),
    );
  }

  Future<void> _purchaseTheme(String themeId) async {
    Navigator.pop(context);
    
    // Simulate purchase process
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Processing purchase...'),
          ],
        ),
      ),
    );

    // Simulate delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.pop(context);
      
      final success = await ref.read(themeCustomizationProvider.notifier).purchaseTheme(themeId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Theme unlocked!' : 'Purchase failed'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showThemeStats(BuildContext context, ThemeStats stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total Themes', stats.totalThemes.toString()),
            _buildStatRow('Unlocked Themes', stats.unlockedThemes.toString()),
            _buildStatRow('Premium Themes', stats.premiumThemes.toString()),
            _buildStatRow('Completion', '${(stats.completionPercentage * 100).toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Game theme card widget
class GameThemeCard extends ConsumerWidget {
  final GameThemeData theme;
  final bool isSelected;
  final bool isUnlocked;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  const GameThemeCard({
    super.key,
    required this.theme,
    required this.isSelected,
    required this.isUnlocked,
    required this.onTap,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedCard(
      onTap: onTap,
      child: Stack(
        children: [
          // Theme preview
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: theme.gradients['primary'],
              border: isSelected
                  ? Border.all(color: theme.primaryColor, width: 3)
                  : null,
            ),
            child: Column(
              children: [
                // Color preview
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      gradient: theme.gradients['background'],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: theme.playerColors.values.map((color) =>
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ).toList(),
                      ),
                    ),
                  ),
                ),
                
                // Theme info
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          theme.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (theme.isPremium)
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lock overlay
          if (!isUnlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(0.6),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          
          // Selected indicator
          if (isSelected)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}

/// Board theme card widget
class BoardThemeCard extends ConsumerWidget {
  final BoardThemeData theme;
  final bool isSelected;
  final bool isUnlocked;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  const BoardThemeCard({
    super.key,
    required this.theme,
    required this.isSelected,
    required this.isUnlocked,
    required this.onTap,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedCard(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: theme.boardBorderColor, width: 3)
                  : Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                // Board preview
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.boardBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.boardBorderColor),
                    ),
                    child: CustomPaint(
                      painter: MiniboardPainter(theme),
                      size: const Size.square(100),
                    ),
                  ),
                ),
                
                // Theme info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          theme.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (theme.isPremium)
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lock overlay
          if (!isUnlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(0.6),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          
          // Selected indicator
          if (isSelected)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}

/// Theme combination card widget
class ThemeCombinationCard extends ConsumerWidget {
  final ThemeCombination combination;
  final VoidCallback onApply;

  const ThemeCombinationCard({
    super.key,
    required this.combination,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameTheme = ThemeService.getGameTheme(combination.gameThemeId);
    final boardTheme = ThemeService.getBoardTheme(combination.boardThemeId);

    return AnimatedCard(
      onTap: onApply,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Preview
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: gameTheme?.gradients['primary'],
              ),
              child: Center(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: boardTheme?.boardBackgroundColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: boardTheme?.boardBorderColor ?? Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    combination.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    combination.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${gameTheme?.name} + ${boardTheme?.name}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Apply button
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Mini board painter for theme preview
class MiniboardPainter extends CustomPainter {
  final BoardThemeData theme;

  MiniboardPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Draw simplified board layout
    paint.color = theme.pathColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw corner areas
    final cornerSize = size.width / 3;
    
    // Top-left (Red)
    paint.color = theme.homeAreaColors[PlayerColor.red] ?? Colors.red.shade100;
    canvas.drawRect(Rect.fromLTWH(0, 0, cornerSize, cornerSize), paint);
    
    // Top-right (Blue)
    paint.color = theme.homeAreaColors[PlayerColor.blue] ?? Colors.blue.shade100;
    canvas.drawRect(Rect.fromLTWH(size.width - cornerSize, 0, cornerSize, cornerSize), paint);
    
    // Bottom-left (Green)
    paint.color = theme.homeAreaColors[PlayerColor.green] ?? Colors.green.shade100;
    canvas.drawRect(Rect.fromLTWH(0, size.height - cornerSize, cornerSize, cornerSize), paint);
    
    // Bottom-right (Yellow)
    paint.color = theme.homeAreaColors[PlayerColor.yellow] ?? Colors.yellow.shade100;
    canvas.drawRect(Rect.fromLTWH(size.width - cornerSize, size.height - cornerSize, cornerSize, cornerSize), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}