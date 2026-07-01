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
      scale: animate ? 1.25 : 1.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.5),
              blurRadius: 0,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔥', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
