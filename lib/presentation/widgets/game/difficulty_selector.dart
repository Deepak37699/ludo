import 'package:flutter/material.dart';
import '../../../core/enums/game_enums.dart';

/// Widget for selecting AI difficulty level
class DifficultySelector extends StatelessWidget {
  final AIDifficulty selectedDifficulty;
  final ValueChanged<AIDifficulty> onDifficultyChanged;

  const DifficultySelector({
    super.key,
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: AIDifficulty.values.map((difficulty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _DifficultyOption(
            difficulty: difficulty,
            isSelected: selectedDifficulty == difficulty,
            onTap: () => onDifficultyChanged(difficulty),
          ),
        );
      }).toList(),
    );
  }
}

/// Individual difficulty option widget
class _DifficultyOption extends StatelessWidget {
  final AIDifficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyOption({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficultyInfo = _getDifficultyInfo(difficulty);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected 
            ? theme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.primaryColor : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? theme.primaryColor : Colors.transparent,
              ),
              child: isSelected
                ? const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  )
                : null,
            ),
            const SizedBox(width: 16),
            
            // Difficulty icon
            Icon(
              difficultyInfo.icon,
              color: difficultyInfo.color,
              size: 24,
            ),
            const SizedBox(width: 12),
            
            // Difficulty info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    difficultyInfo.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? theme.primaryColor : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    difficultyInfo.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Difficulty level indicator
            _buildDifficultyIndicator(difficultyInfo.level),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyIndicator(int level) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < level 
              ? _getDifficultyInfo(difficulty).color
              : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  DifficultyInfo _getDifficultyInfo(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return DifficultyInfo(
          name: 'Easy',
          description: 'Perfect for beginners. AI makes simple moves.',
          icon: Icons.sentiment_satisfied,
          color: Colors.green,
          level: 1,
        );
      case AIDifficulty.medium:
        return DifficultyInfo(
          name: 'Medium',
          description: 'Balanced gameplay. Good for casual players.',
          icon: Icons.sentiment_neutral,
          color: Colors.orange,
          level: 2,
        );
      case AIDifficulty.hard:
        return DifficultyInfo(
          name: 'Hard',
          description: 'Challenging AI with strategic thinking.',
          icon: Icons.sentiment_dissatisfied,
          color: Colors.red,
          level: 3,
        );
      case AIDifficulty.expert:
        return DifficultyInfo(
          name: 'Expert',
          description: 'Maximum challenge. AI uses advanced strategies.',
          icon: Icons.psychology,
          color: Colors.purple,
          level: 4,
        );
    }
  }
}

/// Information about a difficulty level
class DifficultyInfo {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int level;

  const DifficultyInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.level,
  });
}

/// Compact difficulty selector for smaller spaces
class CompactDifficultySelector extends StatelessWidget {
  final AIDifficulty selectedDifficulty;
  final ValueChanged<AIDifficulty> onDifficultyChanged;

  const CompactDifficultySelector({
    super.key,
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AIDifficulty.values.map((difficulty) {
        final info = _getDifficultyInfo(difficulty);
        final isSelected = selectedDifficulty == difficulty;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => onDifficultyChanged(difficulty),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected 
                    ? info.color.withOpacity(0.2)
                    : Colors.grey.shade100,
                  border: Border.all(
                    color: isSelected ? info.color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      info.icon,
                      color: isSelected ? info.color : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? info.color : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  DifficultyInfo _getDifficultyInfo(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return const DifficultyInfo(
          name: 'Easy',
          description: '',
          icon: Icons.sentiment_satisfied,
          color: Colors.green,
          level: 1,
        );
      case AIDifficulty.medium:
        return const DifficultyInfo(
          name: 'Medium',
          description: '',
          icon: Icons.sentiment_neutral,
          color: Colors.orange,
          level: 2,
        );
      case AIDifficulty.hard:
        return const DifficultyInfo(
          name: 'Hard',
          description: '',
          icon: Icons.sentiment_dissatisfied,
          color: Colors.red,
          level: 3,
        );
      case AIDifficulty.expert:
        return const DifficultyInfo(
          name: 'Expert',
          description: '',
          icon: Icons.psychology,
          color: Colors.purple,
          level: 4,
        );
    }
  }
}

/// Difficulty selector with dropdown
class DropdownDifficultySelector extends StatelessWidget {
  final AIDifficulty selectedDifficulty;
  final ValueChanged<AIDifficulty> onDifficultyChanged;
  final String? label;

  const DropdownDifficultySelector({
    super.key,
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<AIDifficulty>(
      value: selectedDifficulty,
      decoration: InputDecoration(
        labelText: label ?? 'AI Difficulty',
        prefixIcon: const Icon(Icons.psychology),
      ),
      items: AIDifficulty.values.map((difficulty) {
        final info = _getDifficultyInfo(difficulty);
        return DropdownMenuItem(
          value: difficulty,
          child: Row(
            children: [
              Icon(info.icon, color: info.color, size: 20),
              const SizedBox(width: 12),
              Text(info.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (difficulty) {
        if (difficulty != null) {
          onDifficultyChanged(difficulty);
        }
      },
    );
  }

  DifficultyInfo _getDifficultyInfo(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return const DifficultyInfo(
          name: 'Easy',
          description: '',
          icon: Icons.sentiment_satisfied,
          color: Colors.green,
          level: 1,
        );
      case AIDifficulty.medium:
        return const DifficultyInfo(
          name: 'Medium',
          description: '',
          icon: Icons.sentiment_neutral,
          color: Colors.orange,
          level: 2,
        );
      case AIDifficulty.hard:
        return const DifficultyInfo(
          name: 'Hard',
          description: '',
          icon: Icons.sentiment_dissatisfied,
          color: Colors.red,
          level: 3,
        );
      case AIDifficulty.expert:
        return const DifficultyInfo(
          name: 'Expert',
          description: '',
          icon: Icons.psychology,
          color: Colors.purple,
          level: 4,
        );
    }
  }
}