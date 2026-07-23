import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/stats_cubit.dart';
import '../../models/stats.dart';
import '../../theme/app_theme.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatsCubit, StatsState>(
      builder: (context, state) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: DeckColors.ink, width: 2)),
                color: DeckColors.paper,
              ),
              child: Row(
                children: [
                  Text('Stats',
                      style: DeckTheme.spaceGrotesk(fontSize: 17)),
                  const Spacer(),
                  if (state.stats != null)
                    Text('${state.stats!.totalQuestionsAnswered} answers',
                        style: DeckTheme.ibmPlexMono(
                            fontSize: 9, color: DeckColors.graphite)),
                ],
              ),
            ),
            Expanded(child: _buildBody(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, StatsState state) {
    if (state.loading) {
      return const Center(
        child: Text('Loading stats...',
            style: TextStyle(fontSize: 14, color: DeckColors.graphite)),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(state.error!,
                  textAlign: TextAlign.center,
                  style: DeckTheme.ibmPlexMono(color: DeckColors.graphite)),
              const SizedBox(height: 16),
              _btnPrimary('TRY AGAIN',
                  () => context.read<StatsCubit>().load()),
            ],
          ),
        ),
      );
    }

    final s = state.stats;
    final cats = state.categoryStats;

    final hasData = s != null && s.totalQuestionsAnswered > 0;

    if (!hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: DeckColors.paperDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: DeckColors.rule, width: 2),
                ),
                child: const Center(
                  child: Text('\u{1F4CA}', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(height: 16),
              Text('No stats yet',
                  style: DeckTheme.spaceGrotesk(fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                'Answer some questions and your\nstats will appear here.',
                textAlign: TextAlign.center,
                style: DeckTheme.literata(
                    fontSize: 13,
                    color: DeckColors.graphite,
                    height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<StatsCubit>().load(),
      color: DeckColors.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OVERVIEW',
                style: DeckTheme.ibmPlexMono(
                    fontSize: 9,
                    color: DeckColors.graphite,
                    letterSpacing: 0.1)),
            const SizedBox(height: 8),
            Row(
              children: [
                _statChip('${s.totalQuestionsAnswered}', 'Answered'),
                const SizedBox(width: 8),
                _statChip('${s.totalCorrectStreak}', 'Streak'),
                const SizedBox(width: 8),
                _statChip('${s.currentLoginStreak}', 'Login'),
              ],
            ),
            if (cats != null && cats.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('BY CATEGORY',
                  style: DeckTheme.ibmPlexMono(
                      fontSize: 9,
                      color: DeckColors.graphite,
                      letterSpacing: 0.1)),
              const SizedBox(height: 8),
              ...cats.map((cat) => _buildCategoryRow(cat)),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: DeckColors.paperDark,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: DeckColors.rule),
        ),
        child: Column(
          children: [
            Text(value,
                textAlign: TextAlign.center,
                style: DeckTheme.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DeckColors.ink)),
            const SizedBox(height: 2),
            Text(label,
                style: DeckTheme.ibmPlexMono(
                    fontSize: 8, color: DeckColors.graphite)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(CategoryStat cat) {
    final accuracyColor = cat.accuracy >= 75
        ? DeckColors.green
        : cat.accuracy >= 50
            ? DeckColors.yellow
            : DeckColors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DeckColors.paperDark,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: DeckColors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(cat.categoryName,
                    style: DeckTheme.spaceGrotesk(fontSize: 13)),
              ),
              Text('${cat.accuracy.toStringAsFixed(0)}%',
                  style: DeckTheme.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: accuracyColor)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              color: accuracyColor.withAlpha(30),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (cat.questionsAnswered > 0
                        ? cat.accuracy / 100
                        : 0.0)
                    .clamp(0.0, 1.0)
                    .toDouble(),
                child: Container(color: accuracyColor),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
              '${cat.correctAnswers}/${cat.questionsAnswered} correct \u00B7 Finished ${cat.completedSessions}\u00D7',
              style: DeckTheme.ibmPlexMono(
                  fontSize: 9, color: DeckColors.graphite)),
        ],
      ),
    );
  }

  Widget _btnPrimary(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: DeckColors.ink,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(label,
                style: DeckTheme.spaceGrotesk(
                    fontSize: 13.5, color: DeckColors.paper)),
          ),
        ),
      ),
    );
  }
}
