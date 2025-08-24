import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/game_state.dart';
import '../../../data/models/player.dart';
import '../../providers/game_provider.dart';
import '../widgets.dart';

/// Widget containing game controls like dice, current player info, and actions
class GameControlsWidget extends ConsumerWidget {
  final GameState gameState;
  final VoidCallback? onDiceRoll;
  final VoidCallback? onPauseGame;
  final VoidCallback? onEndGame;

  const GameControlsWidget({
    super.key,
    required this.gameState,
    this.onDiceRoll,
    this.onPauseGame,
    this.onEndGame,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDiceRolling = ref.watch(diceAnimationProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current player info
          _buildCurrentPlayerInfo(theme),
          
          const SizedBox(height: 20),
          
          // Dice section
          _buildDiceSection(context, ref, isDiceRolling),
          
          const SizedBox(height: 20),
          
          // Game actions
          _buildGameActions(context),
          
          const SizedBox(height: 16),
          
          // Turn timer
          _buildTurnTimer(theme),
        ],
      ),
    );
  }

  Widget _buildCurrentPlayerInfo(ThemeData theme) {
    final currentPlayer = gameState.currentPlayer;
    
    return LudoCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Player avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getPlayerColor(currentPlayer.color),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentPlayer.name}\'s Turn',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Score: ${currentPlayer.score}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          
          // Turn indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPlayerColor(currentPlayer.color),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Active',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiceSection(BuildContext context, WidgetRef ref, bool isDiceRolling) {
    final theme = Theme.of(context);
    final canRoll = gameState.canRollDice && !isDiceRolling;
    final lastRoll = gameState.lastDiceRoll;
    
    return Column(
      children: [
        // Dice
        DiceRollButton(
          lastRoll: lastRoll > 0 ? lastRoll : null,
          isRolling: isDiceRolling,
          canRoll: canRoll,
          onRoll: () {
            if (canRoll) {
              ref.read(diceAnimationProvider.notifier).startAnimation();
              onDiceRoll?.call();
              
              // Stop animation after delay
              Future.delayed(const Duration(seconds: 1), () {
                ref.read(diceAnimationProvider.notifier).stopAnimation();
              });
            }
          },
          message: _getDiceMessage(),
        ),
        
        const SizedBox(height: 12),
        
        // Move instruction
        if (lastRoll > 0 && !isDiceRolling)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              _getMoveInstruction(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildGameActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LudoButton(
            text: 'Pause',
            type: ButtonType.secondary,
            size: ButtonSize.small,
            icon: Icons.pause,
            onPressed: onPauseGame,
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: LudoButton(
            text: 'End Game',
            type: ButtonType.danger,
            size: ButtonSize.small,
            icon: Icons.stop,
            onPressed: onEndGame,
          ),
        ),
      ],
    );
  }

  Widget _buildTurnTimer(ThemeData theme) {
    final remainingTime = gameState.remainingTurnTime;
    final totalTime = gameState.turnTimeLimit;
    final progress = remainingTime.inSeconds / totalTime;
    
    return Column(
      children: [
        Text(
          'Turn Timer',
          style: theme.textTheme.bodySmall,
        ),
        
        const SizedBox(height: 4),
        
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress > 0.3 ? theme.primaryColor : Colors.red,
          ),
        ),
        
        const SizedBox(height: 4),
        
        Text(
          '${remainingTime.inSeconds}s',
          style: theme.textTheme.bodySmall?.copyWith(
            color: progress > 0.3 ? theme.primaryColor : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getDiceMessage() {
    if (gameState.status != GameStatus.playing) {
      return 'Game not active';
    }
    
    if (gameState.consecutiveSixes >= 2) {
      return 'Be careful! ${gameState.consecutiveSixes} sixes in a row';
    }
    
    if (gameState.lastDiceRoll == 6) {
      return 'Great! Roll again';
    }
    
    return 'Roll the dice to move';
  }

  String _getMoveInstruction() {
    final lastRoll = gameState.lastDiceRoll;
    final currentPlayer = gameState.currentPlayer;
    
    if (lastRoll == 6) {
      final tokensAtHome = currentPlayer.tokensAtHomeCount;
      if (tokensAtHome > 0) {
        return 'You can bring a token out of home or move an existing token';
      } else {
        return 'Move any of your tokens $lastRoll spaces';
      }
    } else {
      return 'Select a token to move $lastRoll spaces';
    }
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

/// Widget showing game statistics during play
class GameStatsWidget extends StatelessWidget {
  final GameState gameState;

  const GameStatsWidget({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: GameStatsCard(
                  title: 'Moves',
                  value: '${gameState.moveHistory.length}',
                  icon: Icons.timeline,
                ),
              ),
              
              Expanded(
                child: GameStatsCard(
                  title: 'Duration',
                  value: _formatDuration(gameState.gameDuration ?? Duration.zero),
                  icon: Icons.timer,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: GameStatsCard(
                  title: 'Current Turn',
                  value: '${gameState.currentPlayerIndex + 1}',
                  icon: Icons.person,
                  iconColor: _getPlayerColor(gameState.currentPlayer.color),
                ),
              ),
              
              Expanded(
                child: GameStatsCard(
                  title: 'Last Roll',
                  value: '${gameState.lastDiceRoll}',
                  icon: Icons.casino,
                ),
              ),
            ],
          ),
        ],
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