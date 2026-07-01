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
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📊', style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Text('MY STATS',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
              ],
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, StatsState state) {
    if (state.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📊', style: TextStyle(fontSize: 56)),
            SizedBox(height: 12),
            Text('Loading stats...',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😵', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<StatsCubit>().load(),
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.stats == null) {
      return const Center(
        child: Text('😴 No stats yet!',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<StatsCubit>().load(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatCards(context, state.stats!),
            if (state.categoryStats != null && state.categoryStats!.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildCategoriesSection(state.categoryStats!),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, UserStats s) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildStatCard(context, '🤔', 'ANSWERED', '${s.totalQuestionsAnswered}', AppColors.primary),
        _buildStatCard(context, '🔥', 'CORRECT STREAK', '${s.totalCorrectStreak}', AppColors.secondary),
        _buildStatCard(context, '📅', 'LOGIN STREAK', '${s.currentLoginStreak}', AppColors.sky),
        _buildStatCard(context, '🏆', 'BEST STREAK', '${s.longestLoginStreak}', AppColors.gold),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String emoji, String label, String value, Color color) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.outline, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 0,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(List<CategoryStat> cats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        ...cats.map(_buildCategoryCard),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 0,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📂', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('BY CATEGORY',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryStat cat) {
    final accuracyColor = cat.accuracy >= 75
        ? AppColors.success
        : cat.accuracy >= 50
            ? AppColors.secondary
            : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: accuracyColor.withValues(alpha: 0.2),
            blurRadius: 0,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(cat.categoryName,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ),
                Text('${cat.accuracy.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: accuracyColor)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: cat.questionsAnswered > 0 ? cat.accuracy / 100 : 0,
                backgroundColor: accuracyColor.withValues(alpha: 0.12),
                color: accuracyColor,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 10),
            Text('${cat.correctAnswers}/${cat.questionsAnswered} correct',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
