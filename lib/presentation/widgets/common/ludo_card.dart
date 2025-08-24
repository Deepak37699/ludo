import 'package:flutter/material.dart';

/// Custom card widget with Ludo game styling
class LudoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? selectedColor;
  final double? width;
  final double? height;

  const LudoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.backgroundColor,
    this.borderRadius,
    this.onTap,
    this.isSelected = false,
    this.selectedColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(8),
      child: Material(
        elevation: elevation ?? (isSelected ? 8 : 4),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        color: _getBackgroundColor(theme),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                      color: selectedColor ?? theme.primaryColor,
                      width: 2,
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (backgroundColor != null) return backgroundColor!;
    if (isSelected) {
      return selectedColor?.withOpacity(0.1) ?? theme.primaryColor.withOpacity(0.1);
    }
    return theme.cardColor;
  }
}

/// Player info card widget
class PlayerCard extends StatelessWidget {
  final String playerName;
  final String? avatarUrl;
  final Color playerColor;
  final int score;
  final bool isCurrentTurn;
  final bool isWinner;
  final int tokensFinished;
  final VoidCallback? onTap;

  const PlayerCard({
    super.key,
    required this.playerName,
    this.avatarUrl,
    required this.playerColor,
    required this.score,
    this.isCurrentTurn = false,
    this.isWinner = false,
    required this.tokensFinished,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LudoCard(
      onTap: onTap,
      isSelected: isCurrentTurn,
      selectedColor: playerColor,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: playerColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrentTurn ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          
          const SizedBox(width: 12),
          
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        playerName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCurrentTurn ? playerColor : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isWinner)
                      Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 20,
                      ),
                    if (isCurrentTurn && !isWinner)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: playerColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Turn',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Text(
                      'Score: $score',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Tokens: $tokensFinished/4',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      color: Colors.white,
      size: 24,
    );
  }
}

/// Game stats card widget
class GameStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const GameStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LudoCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 32,
            color: iconColor ?? theme.primaryColor,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}