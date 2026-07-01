import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../quiz/question_screen.dart';
import '../../models/question.dart' as qm;

class ReviewTab extends StatefulWidget {
  final ReviewService reviewService;
  final QuizService quizService;

  const ReviewTab({
    super.key,
    required this.reviewService,
    required this.quizService,
  });

  @override
  State<ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<ReviewTab> {
  List<DueReviewItem>? _items;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final page = await widget.reviewService.getDueForReview();
      if (mounted) {
        setState(() {
          _items = page.items;
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

  void _openQuestion(DueReviewItem item) {
    final q = qm.Question(
      id: item.questionId,
      categoryId: item.categoryId,
      categoryName: '',
      categoryPath: '',
      questionText: item.questionText,
      questionType: item.questionType,
      options: item.options,
      createdAt: '',
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuestionScreen(
          quizService: widget.quizService,
          categoryId: item.categoryId,
          categoryName: 'Review',
          initialQuestion: q,
          isReviewMode: true,
        ),
      ),
    );
  }

  String _levelEmoji(int repetitions) {
    if (repetitions >= 5) return '🧠';
    if (repetitions >= 3) return '💪';
    if (repetitions >= 1) return '📖';
    return '🆕';
  }

  Color _levelColor(int repetitions) {
    if (repetitions >= 5) return AppColors.success;
    if (repetitions >= 3) return AppColors.primary;
    if (repetitions >= 1) return AppColors.sky;
    return AppColors.secondary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📚', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('REVIEW DUE',
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
            const Text('📚', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('Loading review...',
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
                onPressed: () {
                  setState(() { _loading = true; _error = null; });
                  _load();
                },
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items == null || _items!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.outline, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 0,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: AppColors.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🎉', style: TextStyle(fontSize: 44)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('ALL CAUGHT UP!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.5)),
              const SizedBox(height: 8),
              const Text('No review due right now.\nAnswer more questions to build your study queue!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _load,
                child: const Text('REFRESH 🔄'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _items!.length,
        itemBuilder: (context, index) => _buildCard(_items![index]),
      ),
    );
  }

  Widget _buildCard(DueReviewItem item) {
    final color = _levelColor(item.repetitions);

    return GestureDetector(
      onTap: () => _openQuestion(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                ),
                child: Center(
                  child: Text(
                    _levelEmoji(item.repetitions),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.questionText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTag(
                          item.questionType == 'single_choice'
                              ? '🎯'
                              : item.questionType == 'multiple_choice'
                                  ? '✅'
                                  : '✏️',
                          item.questionType == 'single_choice'
                              ? 'SINGLE'
                              : item.questionType == 'multiple_choice'
                                  ? 'MULTI'
                                  : 'FILL',
                          color,
                        ),
                        const SizedBox(width: 8),
                        _buildTag('📅', '${item.intervalDays}d', AppColors.textSecondary),
                        const SizedBox(width: 8),
                        _buildTag('🔄', '${item.repetitions}x', AppColors.textSecondary),
                        if (item.lapses > 0) ...[
                          const SizedBox(width: 8),
                          _buildTag('❌', '${item.lapses}', AppColors.error),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String emoji, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
