import 'package:flutter/material.dart';
import '../../models/stats.dart';
import '../../services/stats_service.dart';
import '../../theme/app_theme.dart';

class StatsTab extends StatefulWidget {
  final StatsService statsService;

  const StatsTab({super.key, required this.statsService});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  UserStats? _stats;
  List<CategoryStat>? _categoryStats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.statsService.getStats(),
        widget.statsService.getCategoryStats(),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as UserStats;
          _categoryStats = results[1] as List<CategoryStat>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('Loading stats...',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😵', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      );
    }

    if (_stats == null) {
      return const Center(
        child: Text('😴 No stats yet!',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatCards(),
            if (_categoryStats != null && _categoryStats!.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildCategoriesSection(),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    final s = _stats!;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildStatCard('🤔', 'ANSWERED', '${s.totalQuestionsAnswered}', AppColors.primary),
        _buildStatCard('🔥', 'CORRECT STREAK', '${s.totalCorrectStreak}', AppColors.secondary),
        _buildStatCard('📅', 'LOGIN STREAK', '${s.currentLoginStreak}', AppColors.sky),
        _buildStatCard('🏆', 'BEST STREAK', '${s.longestLoginStreak}', AppColors.gold),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, Color color) {
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
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              Text(
                'BY CATEGORY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        ..._categoryStats!.map((cat) => _buildCategoryCard(cat)),
      ],
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
                  child: Text(
                    cat.categoryName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${cat.accuracy.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: accuracyColor,
                  ),
                ),
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
            Row(
              children: [
                _buildMiniTag('${cat.correctAnswers}/${cat.questionsAnswered} correct', AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
