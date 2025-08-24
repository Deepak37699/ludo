import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/audio_provider.dart';
import '../../../services/achievements/achievement_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/animated_transitions.dart';

/// Screen displaying user achievements and progress
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AchievementType? _selectedCategory;

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
    final achievementsState = ref.watch(userAchievementsProvider);
    final categories = ref.watch(achievementCategoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.view_list)),
            Tab(text: 'Unlocked', icon: Icon(Icons.star)),
            Tab(text: 'Categories', icon: Icon(Icons.category)),
          ],
        ),
        actions: [
          if (achievementsState.recentUnlocks.isNotEmpty)
            IconButton(
              onPressed: () => _showRecentUnlocks(context),
              icon: Badge(
                label: Text(achievementsState.recentUnlocks.length.toString()),
                child: const Icon(Icons.notifications),
              ),
              tooltip: 'Recent Unlocks',
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress Overview
          _buildProgressOverview(achievementsState, theme),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllAchievements(achievementsState),
                _buildUnlockedAchievements(achievementsState),
                _buildCategoriesView(categories),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(UserAchievementsState state, ThemeData theme) {
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
                  'Total Points',
                  state.totalPoints.toString(),
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  '${state.achievements.where((a) => a.isUnlocked).length}/${state.allDefinitions.length}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Progress',
                  '${(state.completionPercentage * 100).toStringAsFixed(0)}%',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedProgressBar(
            progress: state.completionPercentage,
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllAchievements(UserAchievementsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Error loading achievements'),
            const SizedBox(height: 8),
            Text(state.error!, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    final sortedDefinitions = List<AchievementDefinition>.from(state.allDefinitions);
    sortedDefinitions.sort((a, b) {
      // Unlocked achievements first
      final aUnlocked = state.achievements.any((ach) => ach.id == a.id && ach.isUnlocked);
      final bUnlocked = state.achievements.any((ach) => ach.id == b.id && ach.isUnlocked);
      
      if (aUnlocked && !bUnlocked) return -1;
      if (!aUnlocked && bUnlocked) return 1;
      
      // Then by rarity (legendary first)
      return b.rarity.index.compareTo(a.rarity.index);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDefinitions.length,
      itemBuilder: (context, index) {
        final definition = sortedDefinitions[index];
        final achievement = state.achievements
            .where((a) => a.id == definition.id)
            .firstOrNull;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AchievementCard(
            definition: definition,
            achievement: achievement,
            onTap: () => _showAchievementDetails(definition, achievement),
          ),
        );
      },
    );
  }

  Widget _buildUnlockedAchievements(UserAchievementsState state) {
    final unlockedAchievements = state.achievements.where((a) => a.isUnlocked).toList();
    
    if (unlockedAchievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No achievements unlocked yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Play some games to start earning achievements!',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // Sort by unlock date (most recent first)
    unlockedAchievements.sort((a, b) => 
        (b.unlockedAt ?? DateTime(0)).compareTo(a.unlockedAt ?? DateTime(0))
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: unlockedAchievements.length,
      itemBuilder: (context, index) {
        final achievement = unlockedAchievements[index];
        final definition = AchievementService.getAchievementDefinition(achievement.id);
        
        if (definition == null) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AchievementCard(
            definition: definition,
            achievement: achievement,
            onTap: () => _showAchievementDetails(definition, achievement),
            showUnlockDate: true,
          ),
        );
      },
    );
  }

  Widget _buildCategoriesView(List<AchievementCategory> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryAchievements = ref.watch(
          achievementsByCategoryProvider(category.type)
        );
        
        final unlockedCount = categoryAchievements.where((a) => a.isUnlocked).length;
        final totalCount = ref.watch(userAchievementsProvider)
            .allDefinitions
            .where((d) => d.type == category.type)
            .length;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AnimatedCard(
            onTap: () => _showCategoryDetails(category),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  category.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              title: Text(category.name),
              subtitle: Text(category.description),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$unlockedCount/$totalCount',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${totalCount > 0 ? (unlockedCount / totalCount * 100).toStringAsFixed(0) : 0}%',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAchievementDetails(AchievementDefinition definition, Achievement? achievement) {
    showDialog(
      context: context,
      builder: (context) => AchievementDetailsDialog(
        definition: definition,
        achievement: achievement,
      ),
    );
  }

  void _showCategoryDetails(AchievementCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryAchievementsScreen(category: category),
      ),
    );
  }

  void _showRecentUnlocks(BuildContext context) {
    final recentUnlocks = ref.read(userAchievementsProvider).recentUnlocks;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recent Achievements'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: recentUnlocks.length,
            itemBuilder: (context, index) {
              final unlock = recentUnlocks[index];
              return ListTile(
                leading: Text(
                  unlock.definition.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(unlock.definition.title),
                subtitle: Text(unlock.definition.description),
                trailing: Text(
                  '+${unlock.definition.points}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(userAchievementsProvider.notifier).clearRecentUnlocks();
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Achievement card widget
class AchievementCard extends ConsumerWidget {
  final AchievementDefinition definition;
  final Achievement? achievement;
  final VoidCallback? onTap;
  final bool showUnlockDate;

  const AchievementCard({
    super.key,
    required this.definition,
    this.achievement,
    this.onTap,
    this.showUnlockDate = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isUnlocked = achievement?.isUnlocked ?? false;
    final progress = achievement?.progress ?? 0;
    final progressPercent = definition.target > 0 ? progress / definition.target : 0.0;

    return AnimatedCard(
      onTap: () async {
        await ref.read(audioActionsProvider).buttonClick();
        onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked 
                    ? _getRarityColor(definition.rarity).withOpacity(0.2)
                    : Colors.grey.shade200,
                border: Border.all(
                  color: isUnlocked 
                      ? _getRarityColor(definition.rarity)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  definition.icon,
                  style: TextStyle(
                    fontSize: 24,
                    color: isUnlocked ? null : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          definition.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? null : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (isUnlocked) ...[
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '+${definition.points}',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    definition.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUnlocked ? null : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Progress bar (if not unlocked)
                  if (!isUnlocked) ...[
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progressPercent.clamp(0.0, 1.0),
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation(
                              _getRarityColor(definition.rarity),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$progress/${definition.target}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                  
                  // Unlock date (if unlocked and requested)
                  if (isUnlocked && showUnlockDate && achievement?.unlockedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Unlocked ${_formatDate(achievement!.unlockedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Achievement details dialog
class AchievementDetailsDialog extends StatelessWidget {
  final AchievementDefinition definition;
  final Achievement? achievement;

  const AchievementDetailsDialog({
    super.key,
    required this.definition,
    this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlocked = achievement?.isUnlocked ?? false;

    return AlertDialog(
      title: Row(
        children: [
          Text(
            definition.icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(definition.title),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(definition.description),
          const SizedBox(height: 16),
          
          if (!isUnlocked && achievement != null) ...[
            Text(
              'Progress: ${achievement!.progress}/${definition.target}',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (achievement!.progress / definition.target).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 16),
          ],
          
          Row(
            children: [
              Text('Rarity: ${definition.rarity.name}'),
              const Spacer(),
              Text('Points: +${definition.points}'),
            ],
          ),
          
          if (isUnlocked && achievement?.unlockedAt != null) ...[
            const SizedBox(height: 8),
            Text('Unlocked: ${achievement!.unlockedAt}'),
          ],
        ],
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

/// Category achievements screen
class CategoryAchievementsScreen extends ConsumerWidget {
  final AchievementCategory category;

  const CategoryAchievementsScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsByCategoryProvider(category.type));
    final allDefinitions = ref.watch(userAchievementsProvider).allDefinitions
        .where((d) => d.type == category.type)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${category.icon} ${category.name}'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allDefinitions.length,
        itemBuilder: (context, index) {
          final definition = allDefinitions[index];
          final achievement = achievements
              .where((a) => a.id == definition.id)
              .firstOrNull;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AchievementCard(
              definition: definition,
              achievement: achievement,
            ),
          );
        },
      ),
    );
  }
}