import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/game/ludo_game_board.dart';
import '../../widgets/game/game_controls_widget.dart';
import '../../widgets/widgets.dart';
import '../../../services/game/game_engine.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/enums/game_enums.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    // For now, create a demo game if none exists
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) {
      final gameNotifier = ref.read(gameStateProvider.notifier);
      gameNotifier.createQuickGame();
      gameNotifier.startGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final theme = Theme.of(context);

    if (gameState == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading Game...'),
        ),
        body: const Center(
          child: LudoLoadingWidget(
            message: 'Setting up your game...',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, gameState),
      body: _buildGameBody(context, gameState),
      bottomSheet: _buildBottomSheet(context, gameState),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, gameState) {
    return AppBar(
      title: Text('Game ${widget.gameId.substring(0, 8)}'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showGameInfo(context, gameState),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, gameState),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'pause',
              child: ListTile(
                leading: Icon(Icons.pause),
                title: Text('Pause Game'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'end',
              child: ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('End Game'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameBody(BuildContext context, gameState) {
    return SafeArea(
      child: Column(
        children: [
          // Players info row
          _buildPlayersRow(gameState),
          
          // Game board (main content)
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LudoGameBoard(
                    gameState: gameState,
                    onTokenMove: _handleTokenMove,
                    onTokenSelect: _handleTokenSelect,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersRow(gameState) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: gameState.players.length,
        itemBuilder: (context, index) {
          final player = gameState.players[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: PlayerCard(
              playerName: player.name,
              playerColor: _getPlayerColor(player.color),
              score: player.score,
              isCurrentTurn: player.isCurrentTurn,
              isWinner: player.hasWon,
              tokensFinished: player.tokensFinishedCount,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, gameState) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Game controls
          Expanded(
            child: GameControlsWidget(
              gameState: gameState,
              onDiceRoll: _handleDiceRoll,
              onPauseGame: () => _handleMenuAction('pause', gameState),
              onEndGame: () => _handleMenuAction('end', gameState),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTokenMove(String tokenId, position) async {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    setState(() => _isLoading = true);

    try {
      final result = GameEngine.executeMove(
        gameState: gameState,
        tokenId: tokenId,
        targetPosition: position,
        diceValue: gameState.lastDiceRoll,
      );

      // Update game state
      ref.read(gameStateProvider.notifier).state = result.gameState;

      // Show feedback
      if (result.capturedToken != null) {
        _showMessage('Great! You captured an opponent token!');
      } else if (result.tokenFinished) {
        _showMessage('Excellent! Token reached home!');
      }

      // Check for game end
      if (result.gameState.status == GameStatus.finished) {
        _showGameEndDialog(result.gameState);
      }

    } catch (e) {
      _showMessage('Invalid move: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleTokenSelect(String tokenId) {
    // Token selection is handled by the board widget
  }

  void _handleDiceRoll() async {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    setState(() => _isLoading = true);

    try {
      final result = GameEngine.rollDice(gameState);
      
      // Update game state
      ref.read(gameStateProvider.notifier).state = result.gameState;

      // Check if player has valid moves
      if (!result.hasValidMoves) {
        _showMessage('No valid moves available. Turn skipped.');
        // Auto-skip turn after a delay
        Future.delayed(const Duration(seconds: 2), () {
          final currentState = ref.read(gameStateProvider);
          if (currentState != null) {
            final newState = GameEngine.skipTurn(currentState);
            ref.read(gameStateProvider.notifier).state = newState;
          }
        });
      }

    } catch (e) {
      _showMessage('Error rolling dice: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleMenuAction(String action, gameState) {
    switch (action) {
      case 'pause':
        final pausedState = GameEngine.pauseGame(gameState);
        ref.read(gameStateProvider.notifier).state = pausedState;
        _showMessage('Game paused');
        break;
      case 'settings':
        AppRouter.pushSettings(context);
        break;
      case 'end':
        _showEndGameDialog();
        break;
    }
  }

  void _showGameInfo(BuildContext context, gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Game ID: ${widget.gameId}'),
            Text('Status: ${gameState.status.displayName}'),
            Text('Mode: ${gameState.gameMode.displayName}'),
            Text('Players: ${gameState.players.length}'),
            Text('Current Turn: ${gameState.currentPlayer.name}'),
            if (gameState.gameDuration != null)
              Text('Duration: ${_formatDuration(gameState.gameDuration!)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEndGameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Game'),
        content: const Text('Are you sure you want to end this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          LudoButton(
            text: 'End Game',
            type: ButtonType.danger,
            size: ButtonSize.small,
            onPressed: () {
              Navigator.of(context).pop();
              final gameState = ref.read(gameStateProvider);
              if (gameState != null) {
                final endedState = GameEngine.endGame(gameState);
                ref.read(gameStateProvider.notifier).state = endedState;
              }
              AppRouter.goToHome(context);
            },
          ),
        ],
      ),
    );
  }

  void _showGameEndDialog(gameState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            const SizedBox(width: 8),
            const Text('Game Over!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉 ${gameState.winner?.name ?? "Unknown"} Wins! 🎉',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text('Final Score: ${gameState.winner?.score ?? 0}'),
            if (gameState.gameDuration != null)
              Text('Game Duration: ${_formatDuration(gameState.gameDuration!)}'),
          ],
        ),
        actions: [
          LudoButton(
            text: 'Play Again',
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(gameStateProvider.notifier).createQuickGame();
            },
          ),
          LudoButton(
            text: 'Home',
            type: ButtonType.secondary,
            onPressed: () {
              Navigator.of(context).pop();
              AppRouter.goToHome(context);
            },
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getPlayerColor(PlayerColor playerColor) {
    switch (playerColor) {
      case PlayerColor.red:
        return const Color(0xFFE53E3E);
      case PlayerColor.blue:
        return const Color(0xFF3182CE);
      case PlayerColor.green:
        return const Color(0xFF38A169);
      case PlayerColor.yellow:
        return const Color(0xFFD69E2E);
    }
  }
}