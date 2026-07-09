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
        final body = _buildBody(context, state);
        return Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: DeckColors.ink, width: 2)),
                color: DeckColors.paper,
              ),
              child: Text('Stats',
                  style: DeckTheme.spaceGrotesk(fontSize: 17)),
            ),
            Expanded(child: body),
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

    if (state.stats == null) {
      return Center(
        child: Text('No stats yet!',
            style: DeckTheme.spaceGrotesk(
                fontSize: 14, color: DeckColors.graphite)),
      );
    }

    final s = state.stats!;

    return RefreshIndicator(
      onRefresh: () => context.read<StatsCubit>().load(),
      color: DeckColors.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Overview'),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _statCell(
                    '${s.totalQuestionsAnswered}', 'Answered'),
                _statCell(
                    '${s.totalCorrectStreak}',
                    'Correct streak'),
                _statCell('${s.currentLoginStreak}', 'Login streak'),
                _statCell('${s.longestLoginStreak}',
                    'Longest streak'),
              ],
            ),
            if (state.categoryStats != null &&
                state.categoryStats!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionLabel('By Category'),
              ...state.categoryStats!.map(_buildCategoryStat),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: DeckTheme.ibmPlexMono(
              fontSize: 9,
              color: DeckColors.graphite,
              letterSpacing: 0.1)),
    );
  }

  Widget _statCell(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DeckColors.paperDark,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: DeckColors.rule),
      ),
      child: Column(
        children: [
          Text(value,
              style: DeckTheme.spaceGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: DeckColors.ink)),
          const SizedBox(height: 2),
          Text(label,
              style: DeckTheme.ibmPlexMono(
                  fontSize: 8, color: DeckColors.graphite)),
        ],
      ),
    );
  }

  Widget _buildCategoryStat(CategoryStat cat) {
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
              '${cat.correctAnswers}/${cat.questionsAnswered} correct',
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
