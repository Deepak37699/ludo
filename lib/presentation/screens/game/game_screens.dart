import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';
import '../../widgets/widgets.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/enums/game_enums.dart';

class GameModeSelectionScreen extends ConsumerWidget {
  const GameModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Game Mode'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            Text(
              'Choose Your Game Mode',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Select how you want to play Ludo',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildGameModeCard(
                    context,
                    'Single Player',
                    'Play against AI opponents',
                    Icons.person,
                    Colors.blue,
                    () => AppRouter.goToGameLobby(context, gameMode: 'single'),
                  ),
                  _buildGameModeCard(
                    context,
                    'Online Multiplayer',
                    'Play with friends online',
                    Icons.wifi,
                    Colors.green,
                    () => AppRouter.goToGameLobby(context, gameMode: 'online'),
                  ),
                  _buildGameModeCard(
                    context,
                    'Local Multiplayer',
                    'Pass and play on same device',
                    Icons.people,
                    Colors.orange,
                    () => AppRouter.goToGameLobby(context, gameMode: 'local'),
                  ),
                  _buildGameModeCard(
                    context,
                    'Quick Play',
                    'Start a game immediately',
                    Icons.flash_on,
                    Colors.purple,
                    () => _startQuickGame(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModeCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return LudoCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _startQuickGame(BuildContext context, WidgetRef ref) {
    final gameNotifier = ref.read(gameStateProvider.notifier);
    gameNotifier.createQuickGame();
    gameNotifier.startGame();
    
    final gameState = ref.read(gameStateProvider);
    if (gameState != null) {
      AppRouter.goToGame(context, gameState.gameId);
    }
  }
}

class GameLobbyScreen extends ConsumerStatefulWidget {
  final String gameMode;
  
  const GameLobbyScreen({super.key, required this.gameMode});

  @override
  ConsumerState<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends ConsumerState<GameLobbyScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gameMode.toUpperCase()} Lobby'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LudoCard(
              child: Column(
                children: [
                  Text(
                    'Game Settings',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Player count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Number of Players:'),
                      DropdownButton<int>(
                        value: 2,
                        items: const [
                          DropdownMenuItem(value: 2, child: Text('2 Players')),
                          DropdownMenuItem(value: 3, child: Text('3 Players')),
                          DropdownMenuItem(value: 4, child: Text('4 Players')),
                        ],
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Turn time limit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Turn Time Limit:'),
                      DropdownButton<int>(
                        value: 30,
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15 seconds')),
                          DropdownMenuItem(value: 30, child: Text('30 seconds')),
                          DropdownMenuItem(value: 60, child: Text('1 minute')),
                          DropdownMenuItem(value: 120, child: Text('2 minutes')),
                        ],
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Expanded(
              child: LudoCard(
                child: Column(
                  children: [
                    Text(
                      'Players',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Player list
                    Expanded(
                      child: ListView.builder(
                        itemCount: 2,
                        itemBuilder: (context, index) {
                          return PlayerCard(
                            playerName: index == 0 ? 'You' : 'AI Player ${index}',
                            playerColor: _getPlayerColor(index),
                            score: 0,
                            tokensFinished: 0,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            LudoButton(
              text: 'Start Game',
              size: ButtonSize.large,
              onPressed: () => _startGame(context),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlayerColor(int index) {
    switch (index) {
      case 0: return const Color(0xFFE53E3E);
      case 1: return const Color(0xFF3182CE);
      case 2: return const Color(0xFF38A169);
      case 3: return const Color(0xFFD69E2E);
      default: return const Color(0xFF6B7280);
    }
  }

  void _startGame(BuildContext context) {
    final gameNotifier = ref.read(gameStateProvider.notifier);
    gameNotifier.createQuickGame();
    gameNotifier.startGame();
    
    final gameState = ref.read(gameStateProvider);
    if (gameState != null) {
      AppRouter.goToGame(context, gameState.gameId);
    }
  }
}

// Export the actual GameScreen from the separate file
export 'game_screen.dart';