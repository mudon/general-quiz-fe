import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AuthHeader extends StatelessWidget {
  final String subtitle;

  const AuthHeader({super.key, this.subtitle = ''});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: DeckColors.paperDark,
            shape: BoxShape.circle,
            border: Border.all(color: DeckColors.rule, width: 2),
          ),
          child: const Center(
            child: Text('\u{1F9E0}', style: TextStyle(fontSize: 36)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Quiz Deck',
            style: DeckTheme.spaceGrotesk(fontSize: 24, color: DeckColors.ink)),
        const SizedBox(height: 4),
        if (subtitle.isNotEmpty)
          Text(subtitle,
              style: DeckTheme.ibmPlexMono(
                  fontSize: 10, color: DeckColors.graphite)),
      ],
    );
  }
}
