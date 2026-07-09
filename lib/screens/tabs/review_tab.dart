import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/review_cubit.dart';
import '../../models/review.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../quiz/question_screen.dart';
import '../../models/question.dart' as qm;

class ReviewTab extends StatelessWidget {
  final QuizService quizService;

  const ReviewTab({super.key, required this.quizService});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewCubit, ReviewState>(
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
              child: Row(
                children: [
                  Text('Review',
                      style: DeckTheme.spaceGrotesk(fontSize: 17)),
                  const Spacer(),
                  if (state.items != null && state.items!.isNotEmpty)
                    _buildPill(
                        '${state.items!.length} due'),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        );
      },
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DeckColors.graphiteFaint),
      ),
      child: Text(text,
          style: DeckTheme.ibmPlexMono(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: DeckColors.graphite)),
    );
  }

  Widget _buildBody(BuildContext context, ReviewState state) {
    if (state.loading) {
      return const Center(
        child: Text('Loading review...',
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
                  () => context.read<ReviewCubit>().load()),
            ],
          ),
        ),
      );
    }

    if (state.items == null || state.items!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: DeckColors.greenFaint,
                  shape: BoxShape.circle,
                  border: Border.all(color: DeckColors.green, width: 2),
                ),
                child: const Center(
                  child: Text('\u2705', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 16),
              Text('ALL CAUGHT UP!',
                  style: DeckTheme.spaceGrotesk(fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                'No review due right now.\nAnswer more questions to build your queue.',
                textAlign: TextAlign.center,
                style: DeckTheme.literata(
                    fontSize: 13, color: DeckColors.graphite, height: 1.4),
              ),
              const SizedBox(height: 16),
              _btnOutline('REFRESH',
                  () => context.read<ReviewCubit>().load()),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ReviewCubit>().load(),
      color: DeckColors.blue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.items!.length,
        itemBuilder: (context, index) =>
            _buildCard(context, state.items![index]),
      ),
    );
  }

  Widget _buildCard(BuildContext context, DueReviewItem item) {
    final levelColor = _levelColor(item.repetitions);

    return GestureDetector(
      onTap: () => _openQuestion(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DeckColors.paperDark,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: DeckColors.rule),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: levelColor.withAlpha(20),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: levelColor.withAlpha(80), width: 1.5),
              ),
              child: Center(
                child: Text(_levelEmoji(item.repetitions),
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.questionText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DeckTheme.spaceGrotesk(fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _tag(
                          item.questionType == 'single_choice'
                              ? 'SINGLE'
                              : item.questionType == 'multiple_choice'
                                  ? 'MULTI'
                                  : 'FILL',
                          levelColor),
                      const SizedBox(width: 6),
                      _tag('${item.intervalDays}d',
                          DeckColors.graphite),
                      const SizedBox(width: 6),
                      _tag('${item.repetitions}x',
                          DeckColors.graphite),
                      if (item.lapses > 0) ...[
                        const SizedBox(width: 6),
                        _tag('${item.lapses}', DeckColors.red),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text('\u203A',
                style: TextStyle(
                    fontSize: 14, color: DeckColors.graphiteFaint)),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: DeckTheme.ibmPlexMono(
              fontSize: 8.5, fontWeight: FontWeight.w600, color: color)),
    );
  }

  void _openQuestion(BuildContext context, DueReviewItem item) {
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
          quizService: quizService,
          categoryName: 'Review',
          sessionId: '',
          initialQuestion: q,
          isReviewMode: true,
        ),
      ),
    );
  }

  String _levelEmoji(int repetitions) {
    if (repetitions >= 5) return '\u{1F9E0}';
    if (repetitions >= 3) return '\u{1F4AA}';
    if (repetitions >= 1) return '\u{1F4D6}';
    return '\u{1F195}';
  }

  Color _levelColor(int repetitions) {
    if (repetitions >= 5) return DeckColors.green;
    if (repetitions >= 3) return DeckColors.blue;
    if (repetitions >= 1) return DeckColors.yellow;
    return DeckColors.red;
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

  Widget _btnOutline(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: DeckColors.ink, width: 1.5),
          ),
          child: Center(
            child: Text(label,
                style: DeckTheme.spaceGrotesk(
                    fontSize: 13.5, color: DeckColors.ink)),
          ),
        ),
      ),
    );
  }
}
