import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/audio_provider.dart';
import '../../../services/achievements/leaderboard_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/animated_transitions.dart';

/// Screen displaying player leaderboard and rankings
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<LeaderboardEntry> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
    } else {
      setState(() {
        _isSearching = true;
        _searchResults = ref.read(leaderboardProvider.notifier).searchPlayers(query);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardState = ref.watch(leaderboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search players...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              
              // Tabs
              if (!_isSearching)
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Global', icon: Icon(Icons.public)),
                    Tab(text: 'Friends', icon: Icon(Icons.people)),
                    Tab(text: 'You', icon: Icon(Icons.person)),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showLeaderboardStats(context),
            icon: const Icon(Icons.analytics),
            tooltip: 'Statistics',
          ),
          PopupMenuButton<LeaderboardFilter>(
            onSelected: _changeFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: LeaderboardFilter.allTime,
                child: Text('All Time'),
              ),
              const PopupMenuItem(
                value: LeaderboardFilter.thisWeek,
                child: Text('This Week'),
              ),
              const PopupMenuItem(
                value: LeaderboardFilter.thisMonth,
                child: Text('This Month'),
              ),
              const PopupMenuItem(
                value: LeaderboardFilter.topPlayers,
                child: Text('Top Players'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list),
                  Text(_getFilterDisplayName(leaderboardState.currentFilter)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isSearching ? _buildSearchResults() : _buildLeaderboardTabs(),
      floatingActionButton: leaderboardState.userEntry != null
          ? FloatingActionButton.extended(
              onPressed: _scrollToUserPosition,
              icon: const Icon(Icons.my_location),
              label: Text('Rank #${leaderboardState.userRank}'),
            )
          : null,
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No players found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: LeaderboardEntryCard(
            entry: _searchResults[index],
            onTap: () => _showPlayerDetails(_searchResults[index]),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTabs() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildGlobalLeaderboard(),
        _buildFriendsLeaderboard(),
        _buildUserLeaderboard(),
      ],
    );
  }

  Widget _buildGlobalLeaderboard() {
    final leaderboardState = ref.watch(leaderboardProvider);

    if (leaderboardState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (leaderboardState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Error loading leaderboard'),
            const SizedBox(height: 8),
            Text(leaderboardState.error!),
            const SizedBox(height: 16),
            CustomButton(
              onPressed: () => ref.read(leaderboardProvider.notifier).refresh(),
              text: 'Retry',
              icon: Icons.refresh,
            ),
          ],
        ),
      );
    }

    if (leaderboardState.entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No players on leaderboard yet'),
            SizedBox(height: 8),
            Text('Be the first to play and climb the ranks!'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(leaderboardProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaderboardState.entries.length,
        itemBuilder: (context, index) {
          final entry = leaderboardState.entries[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LeaderboardEntryCard(
              entry: entry,
              onTap: () => _showPlayerDetails(entry),
              showRankIcon: index < 3, // Show special icons for top 3
            ),
          );
        },
      ),
    );
  }

  Widget _buildFriendsLeaderboard() {
    // Placeholder for friends leaderboard
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Friends Leaderboard'),
          SizedBox(height: 8),
          Text('Coming soon! Add friends to compete with them.'),
        ],
      ),
    );
  }

  Widget _buildUserLeaderboard() {
    final leaderboardState = ref.watch(leaderboardProvider);
    final userEntry = leaderboardState.userEntry;

    if (userEntry == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('You\'re not on the leaderboard yet'),
            const SizedBox(height: 8),
            const Text('Play some games to get ranked!'),
            const SizedBox(height: 16),
            CustomButton(
              onPressed: () => Navigator.pushNamed(context, '/offline-game'),
              text: 'Play Now',
              icon: Icons.play_arrow,
            ),
          ],
        ),
      );
    }

    final nearbyPlayers = ref.read(leaderboardProvider.notifier).getPlayersAroundUser();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User's position card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Position',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LeaderboardEntryCard(
                    entry: userEntry,
                    isCurrentUser: true,
                    showFullStats: true,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Nearby players
          if (nearbyPlayers.isNotEmpty) ...[
            Text(
              'Players Near You',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...nearbyPlayers.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LeaderboardEntryCard(
                entry: entry,
                onTap: () => _showPlayerDetails(entry),
                isCurrentUser: entry.playerId == userEntry.playerId,
              ),
            )),
          ],
        ],
      ),
    );
  }

  Future<void> _changeFilter(LeaderboardFilter filter) async {
    await ref.read(audioActionsProvider).buttonClick();
    await ref.read(leaderboardProvider.notifier).changeFilter(filter);
  }

  String _getFilterDisplayName(LeaderboardFilter filter) {
    switch (filter) {
      case LeaderboardFilter.allTime:
        return 'All Time';
      case LeaderboardFilter.thisWeek:
        return 'This Week';
      case LeaderboardFilter.thisMonth:
        return 'This Month';
      case LeaderboardFilter.topPlayers:
        return 'Top Players';
    }
  }

  void _scrollToUserPosition() {
    // Implementation would scroll to user's position in the list
    ref.read(audioActionsProvider).buttonClick();
    _tabController.animateTo(2); // Switch to "You" tab
  }

  void _showPlayerDetails(LeaderboardEntry entry) {
    showDialog(
      context: context,
      builder: (context) => PlayerDetailsDialog(entry: entry),
    );
  }

  void _showLeaderboardStats(BuildContext context) {
    final stats = ref.read(leaderboardProvider).stats;
    if (stats == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leaderboard Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Players', stats.totalPlayers.toString()),
            _buildStatRow('Average Score', stats.averageScore.toString()),
            _buildStatRow('Top Score', stats.topScore.toString()),
            _buildStatRow('Average Win Rate', '${(stats.averageWinRate * 100).toStringAsFixed(1)}%'),
            _buildStatRow('Total Games', stats.totalGamesPlayed.toString()),
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

/// Leaderboard entry card widget
class LeaderboardEntryCard extends ConsumerWidget {
  final LeaderboardEntry entry;
  final VoidCallback? onTap;
  final bool isCurrentUser;
  final bool showRankIcon;
  final bool showFullStats;

  const LeaderboardEntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.isCurrentUser = false,
    this.showRankIcon = false,
    this.showFullStats = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AnimatedCard(
      onTap: () async {
        await ref.read(audioActionsProvider).buttonClick();
        onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getRankColor(entry.rank),
                border: Border.all(
                  color: isCurrentUser ? theme.primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: showRankIcon && entry.rank <= 3
                    ? Text(_getRankIcon(entry.rank), style: const TextStyle(fontSize: 20))
                    : Text(
                        entry.rank.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundImage: entry.profileImageUrl != null
                  ? NetworkImage(entry.profileImageUrl!)
                  : null,
              child: entry.profileImageUrl == null
                  ? Text(
                      entry.playerName.isNotEmpty 
                          ? entry.playerName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.playerName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCurrentUser ? theme.primaryColor : null,
                          ),
                        ),
                      ),
                      Text(
                        entry.rankTier.icon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.rankTier.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (showFullStats) ...[
                    _buildStatRow('Score', entry.score.toString()),
                    _buildStatRow('Games', '${entry.gamesWon}/${entry.gamesPlayed}'),
                    _buildStatRow('Win Rate', '${(entry.winRate * 100).toStringAsFixed(1)}%'),
                    _buildStatRow('Win Streak', entry.winStreak.toString()),
                    _buildStatRow('Achievement Points', entry.achievementPoints.toString()),
                  ] else ...[
                    Row(
                      children: [
                        Text(
                          'Score: ${entry.score}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Win Rate: ${(entry.winRate * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Games: ${entry.gamesWon}/${entry.gamesPlayed} • Streak: ${entry.winStreak}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber.shade600; // Gold
    if (rank == 2) return Colors.grey.shade400;   // Silver
    if (rank == 3) return Colors.brown.shade400;  // Bronze
    return Colors.blue.shade600;                  // Default
  }

  String _getRankIcon(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return rank.toString();
    }
  }
}

/// Player details dialog
class PlayerDetailsDialog extends StatelessWidget {
  final LeaderboardEntry entry;

  const PlayerDetailsDialog({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: entry.profileImageUrl != null
                ? NetworkImage(entry.profileImageUrl!)
                : null,
            child: entry.profileImageUrl == null
                ? Text(entry.playerName[0].toUpperCase())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.playerName),
                Text(
                  'Rank #${entry.rank} • ${entry.rankTier.displayName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDetailRow('Score', entry.score.toString()),
          _buildDetailRow('Games Played', entry.gamesPlayed.toString()),
          _buildDetailRow('Games Won', entry.gamesWon.toString()),
          _buildDetailRow('Win Rate', '${(entry.winRate * 100).toStringAsFixed(1)}%'),
          _buildDetailRow('Current Streak', entry.winStreak.toString()),
          _buildDetailRow('Best Streak', entry.maxWinStreak.toString()),
          _buildDetailRow('Achievement Points', entry.achievementPoints.toString()),
          _buildDetailRow('Last Active', _formatLastActive(entry.lastActive)),
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

  Widget _buildDetailRow(String label, String value) {
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

  String _formatLastActive(DateTime lastActive) {
    final difference = DateTime.now().difference(lastActive);
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Recently';
    }
  }
}