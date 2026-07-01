import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

class CategoryBubble extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final int colorIndex;

  const CategoryBubble({
    super.key,
    required this.category,
    required this.onTap,
    this.colorIndex = 0,
  });

  String _emojiForCategory(String? icon) {
    switch (icon) {
      case 'microscope': case 'dna': case 'flask': case 'atom': case 'rocket':
      case 'calculator': case 'brain': case 'bolt': case 'beaker': return '🔬';
      case 'scroll': case 'landmark': case 'swords': case 'building':
      case 'helmet': case 'bomb': return '🏛️';
      case 'globe': case 'map': case 'city': case 'waves':
      case 'monument': case 'compass': return '🌍';
      case 'film': case 'clapperboard': case 'music': case 'tv':
      case 'gamepad': case 'award': return '🎬';
      case 'laptop': case 'smartphone': case 'shield': return '💻';
      case 'trophy': case 'football': case 'basketball': case 'medal': return '⚽';
      case 'utensils': case 'bowl': case 'cake': case 'coffee': return '🍕';
      default: return '⭐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.bubbleColors[colorIndex % AppColors.bubbleColors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 105,
        margin: const EdgeInsets.all(7),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outline, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 0,
              offset: const Offset(5, 5),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _emojiForCategory(category.icon),
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
