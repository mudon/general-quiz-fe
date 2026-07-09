import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

class CategoryBubble extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final int colorIndex;
  final int totalQuestions;
  final int answeredQuestions;
  final bool completed;
  final bool locked;

  const CategoryBubble({
    super.key,
    required this.category,
    required this.onTap,
    this.colorIndex = 0,
    this.totalQuestions = 0,
    this.answeredQuestions = 0,
    this.completed = false,
    this.locked = false,
  });

  String _emojiForCategory(String? icon) {
    switch (icon) {
      case 'microscope':
      case 'dna':
      case 'flask':
      case 'atom':
      case 'rocket':
      case 'calculator':
      case 'brain':
      case 'bolt':
      case 'beaker':
        return '\u{1F52C}';
      case 'scroll':
      case 'landmark':
      case 'swords':
      case 'building':
      case 'helmet':
      case 'bomb':
        return '\u{1F3DB}\uFE0F';
      case 'globe':
      case 'map':
      case 'city':
      case 'waves':
      case 'monument':
      case 'compass':
        return '\u{1F30D}';
      case 'film':
      case 'clapperboard':
      case 'music':
      case 'tv':
      case 'gamepad':
      case 'award':
        return '\u{1F3AC}';
      case 'laptop':
      case 'smartphone':
      case 'shield':
        return '\u{1F4BB}';
      case 'trophy':
      case 'football':
      case 'basketball':
      case 'medal':
        return '\u26BD';
      case 'utensils':
      case 'bowl':
      case 'cake':
      case 'coffee':
        return '\u{1F354}';
      default:
        return '\u2B50';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: locked ? 0.55 : 1.0,
        child: Container(
          width: 105,
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: DeckColors.paperDark,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: completed ? DeckColors.green : DeckColors.rule,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _emojiForCategory(category.icon),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 6),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DeckTheme.spaceGrotesk(fontSize: 11),
              ),
              if (!locked && !completed && totalQuestions > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '$answeredQuestions/$totalQuestions',
                  style: DeckTheme.ibmPlexMono(fontSize: 8),
                ),
              ],
              if (completed) ...[
                const SizedBox(height: 4),
                Text('Completed',
                    style: DeckTheme.ibmPlexMono(
                        fontSize: 8, color: DeckColors.green)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
