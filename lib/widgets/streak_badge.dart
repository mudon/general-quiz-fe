import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StreakBadge extends StatelessWidget {
  final int streak;
  final bool animate;

  const StreakBadge({super.key, required this.streak, this.animate = false});

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) return const SizedBox.shrink();

    return AnimatedScale(
      scale: animate ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: DeckColors.yellowBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DeckColors.yellow),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\u{1F525}', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: DeckTheme.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DeckColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
