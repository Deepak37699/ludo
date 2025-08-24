import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../widgets/widgets.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/enums/game_enums.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userDisplayName = ref.watch(userDisplayNameProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: theme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Ludo Game',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 60,
                      right: 20,
                      child: Icon(
                        Icons.sports_esports,
                        size: 100,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () => AppRouter.goToProfile(context),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => AppRouter.goToSettings(context),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message
                  _buildWelcomeMessage(userDisplayName, theme),
                  
                  const SizedBox(height: 24),
                  
                  // Quick actions
                  _buildQuickActions(context),
                  
                  const SizedBox(height: 24),
                  
                  // Game modes
                  _buildGameModes(context, theme),
                  
                  const SizedBox(height: 24),
                  
                  // Recent games or stats
                  _buildRecentGames(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Leaderboard preview
                  _buildLeaderboardPreview(context, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage(String displayName, ThemeData theme) {
    return LudoCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.waving_hand,
            color: Colors.amber,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Play',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: LudoButton(
                text: 'Quick Game',
                icon: Icons.flash_on,
                size: ButtonSize.large,
                onPressed: () => _startQuickGame(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LudoButton(
                text: 'Join Game',
                type: ButtonType.secondary,
                icon: Icons.group_add,
                size: ButtonSize.large,
                onPressed: () => _showJoinGameDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameModes(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Game Modes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGameModeCard(
                context,
                'Single Player',
                'Play against AI',
                Icons.person,
                Colors.blue,
                () => AppRouter.goToGameLobby(context, gameMode: 'single'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGameModeCard(
                context,
                'Multiplayer',
                'Play with friends',
                Icons.group,
                Colors.green,
                () => AppRouter.goToGameLobby(context, gameMode: 'multiplayer'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGameModeCard(
                context,
                'Local Play',
                'Pass and play',
                Icons.people,
                Colors.orange,
                () => AppRouter.goToGameLobby(context, gameMode: 'local'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGameModeCard(
                context,
                'Tournament',
                'Coming soon',
                Icons.emoji_events,
                Colors.purple,
                null, // Disabled
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameModeCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return LudoCard(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGames(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Stats',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => AppRouter.goToProfile(context),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GameStatsCard(
                title: 'Games Played',
                value: '12',
                icon: Icons.sports_esports,
              ),
            ),
            Expanded(
              child: GameStatsCard(
                title: 'Wins',
                value: '8',
                icon: Icons.emoji_events,
                iconColor: Colors.amber,
              ),
            ),
            Expanded(
              child: GameStatsCard(
                title: 'Win Rate',
                value: '67%',
                icon: Icons.trending_up,
                iconColor: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeaderboardPreview(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Leaderboard',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => AppRouter.goToLeaderboard(context),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LudoCard(
          child: Column(
            children: [
              _buildLeaderboardItem('🥇', 'Player1', '150 pts', Colors.amber),
              const Divider(),
              _buildLeaderboardItem('🥈', 'Player2', '145 pts', Colors.grey),
              const Divider(),
              _buildLeaderboardItem('🥉', 'Player3', '140 pts', Colors.brown),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(String rank, String name, String score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            rank,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            score,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _startQuickGame() {
    final gameNotifier = ref.read(gameStateProvider.notifier);
    gameNotifier.createQuickGame();
    
    // Navigate to game screen
    final gameState = ref.read(gameStateProvider);
    if (gameState != null) {
      AppRouter.goToGame(context, gameState.gameId);
    }
  }

  void _showJoinGameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Game'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Game ID',
                hintText: 'Enter game ID to join',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LudoButton(
                    text: 'Cancel',
                    type: ButtonType.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LudoButton(
                    text: 'Join',
                    onPressed: () {
                      Navigator.of(context).pop();
                      // TODO: Implement join game logic
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}