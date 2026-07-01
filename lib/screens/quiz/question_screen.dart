import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../models/quiz_session.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/confetti_overlay.dart';

class QuestionScreen extends StatefulWidget {
  final QuizService quizService;
  final String categoryName;
  final String sessionId;
  final Question? initialQuestion;
  final bool isReviewMode;

  const QuestionScreen({
    super.key,
    required this.quizService,
    required this.sessionId,
    required this.categoryName,
    this.initialQuestion,
    this.isReviewMode = false,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen>
    with SingleTickerProviderStateMixin {
  Question? _question;
  bool _loading = true;
  String? _error;

  String? _selectedSingle;
  final _selectedMultiple = <String>{};
  final _fillInController = TextEditingController();

  AnswerResult? _result;
  bool _submitting = false;
  int _streak = 0;
  bool _showConfetti = false;
  bool _resultAnimating = false;

  NextQuestionResponse? _next;
  int _sessionAnswered = 0;
  int _sessionTotal = 0;
  bool _sessionCompleted = false;

  late AnimationController _cardController;
  late Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardScale = CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    );
    _loadQuestion();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _fillInController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _loading = true;
      _error = null;
      _question = null;
      _result = null;
      _selectedSingle = null;
      _selectedMultiple.clear();
      _fillInController.clear();
      _showConfetti = false;
      _resultAnimating = false;
    });
    try {
      if (widget.isReviewMode && widget.initialQuestion != null) {
        setState(() {
          _question = widget.initialQuestion;
          _loading = false;
        });
        _cardController.forward(from: 0);
        return;
      }

      final next = await widget.quizService.getNextQuestion(widget.sessionId);
      if (mounted) {
        if (next.completed) {
          setState(() {
            _sessionCompleted = true;
            _sessionTotal = next.totalQuestions;
            _sessionAnswered = next.answeredCount;
            _loading = false;
          });
        } else {
          setState(() {
            _question = next.question;
            _next = next;
            _sessionTotal = next.totalQuestions;
            _sessionAnswered = next.answeredCount;
            _loading = false;
          });
          _cardController.forward(from: 0);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  Future<void> _submitAnswer() async {
    if (_question == null || _submitting) return;
    final q = _question!;
    final hasSelection = q.isSingleChoice && _selectedSingle != null ||
        q.isMultipleChoice && _selectedMultiple.isNotEmpty ||
        q.isFillInBlank && _fillInController.text.trim().isNotEmpty;
    if (!hasSelection) return;

    setState(() => _submitting = true);
    try {
      final result = await widget.quizService.submitAnswer(
        questionId: q.id,
        questionType: q.questionType,
        submittedSingleChoice: _selectedSingle,
        submittedMultipleChoice:
            _selectedMultiple.isNotEmpty ? _selectedMultiple.toList() : null,
        submittedFillIn: q.isFillInBlank ? _fillInController.text.trim() : null,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _submitting = false;
          _resultAnimating = true;
          if (result.isCorrect) {
            _streak++;
            _showConfetti = true;
          } else {
            _streak = 0;
          }
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() => _resultAnimating = false);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          _sessionCompleted
              ? '${widget.categoryName}  ✅'
              : _sessionTotal > 0
                  ? '${widget.categoryName}  ${_sessionAnswered + 1}/$_sessionTotal'
                  : widget.categoryName,
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_resultAnimating && _streak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 12),
              child: StreakBadge(streak: _streak, animate: true),
            )
          else if (_streak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 12),
              child: StreakBadge(streak: _streak),
            ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_showConfetti)
            ConfettiOverlay(
              play: _showConfetti,
              key: ValueKey('confetti_${DateTime.now().millisecondsSinceEpoch}'),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🤔', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Finding a question...',
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
              const Text('😵', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadQuestion, child: const Text('TRY AGAIN')),
            ],
          ),
        ),
      );
    }

    if (_sessionCompleted) {
      return _buildCompletedScreen();
    }

    if (_question == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😴', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              const Text('No questions here yet!',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('GO BACK')),
            ],
          ),
        ),
      );
    }

    final q = _question!;
    final answered = _result != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSpeechBubble(q, answered),
          const SizedBox(height: 24),
          if (answered)
            _buildResultBubble()
          else ...[
            _buildOptions(q),
            const SizedBox(height: 28),
            _buildSubmitButton(q),
          ],
          const SizedBox(height: 32),
          if (answered)
            _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildCompletedScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: AppColors.outline, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.4),
                    blurRadius: 0,
                    offset: const Offset(6, 6),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Text('🎉', style: TextStyle(fontSize: 64)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ALL DONE!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You answered $_sessionTotal questions\nin ${widget.categoryName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Text('👈', style: TextStyle(fontSize: 16)),
              label: const Text('BACK TO CATEGORIES'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shadowColor: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeechBubble(Question q, bool answered) {
    final color = q.isSingleChoice
        ? AppColors.primary
        : q.isMultipleChoice
            ? AppColors.secondary
            : AppColors.sky;

    return ScaleTransition(
      scale: _cardScale,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.outline, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 0,
                  offset: const Offset(6, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        q.isSingleChoice
                            ? '🎯 PICK ONE'
                            : q.isMultipleChoice
                                ? '✅ PICK ALL'
                                : '✏️ TYPE IT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (answered && _result != null)
                      _result!.isCorrect
                          ? const Text('🎉', style: TextStyle(fontSize: 28))
                          : const Text('😅', style: TextStyle(fontSize: 28)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  q.questionText,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.5,
                    letterSpacing: 0.3,
                  ),
                ),
                if (answered && _result?.explanation != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _result!.isCorrect
                          ? AppColors.successBg
                          : AppColors.errorBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _result!.isCorrect
                            ? AppColors.success
                            : AppColors.error,
                        width: 2.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _result!.isCorrect ? '💡 ' : '📝 ',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Expanded(
                          child: Text(
                            _result!.explanation!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _result!.isCorrect
                                  ? AppColors.success
                                  : AppColors.error,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          CustomPaint(
            size: const Size(30, 16),
            painter: _SpeechTrianglePainter(color: AppColors.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(Question q) {
    if (q.isSingleChoice) return _buildSingleChoiceOptions(q);
    if (q.isMultipleChoice) return _buildMultipleChoiceOptions(q);
    return _buildFillInBlankInput();
  }

  Widget _buildSingleChoiceOptions(Question q) {
    return Column(
      children: q.options.asMap().entries.map((entry) {
        final idx = entry.key;
        final opt = entry.value;
        final isSelected = _selectedSingle == opt.id;
        final emojis = ['🅰️', '🅱️', '©️', '🇩'];
        final emoji = emojis[idx % emojis.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => setState(() => _selectedSingle = opt.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.outline,
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 0,
                          offset: const Offset(4, 4),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.outline.withValues(alpha: 0.2),
                          blurRadius: 0,
                          offset: const Offset(4, 4),
                        )
                      ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opt.text,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleChoiceOptions(Question q) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '👇 TAP ALL CORRECT ANSWERS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.secondary,
              letterSpacing: 1,
            ),
          ),
        ),
        ...q.options.map((opt) {
          final isSelected = _selectedMultiple.contains(opt.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isSelected
                      ? _selectedMultiple.remove(opt.id)
                      : _selectedMultiple.add(opt.id);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? AppColors.secondary : AppColors.outline,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.5),
                            blurRadius: 0,
                            offset: const Offset(4, 4),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: AppColors.outline.withValues(alpha: 0.2),
                            blurRadius: 0,
                            offset: const Offset(4, 4),
                          )
                        ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected ? Colors.white : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? Colors.white : AppColors.outline,
                            width: 2.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: AppColors.secondary, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          opt.text,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color:
                                isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFillInBlankInput() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.sky.withValues(alpha: 0.3),
            blurRadius: 0,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('✏️', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text(
                  'TYPE YOUR ANSWER',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _fillInController,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submitAnswer(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
              decoration: InputDecoration(
                hintText: 'Type here...',
                hintStyle: TextStyle(
                  color: AppColors.outline.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.outline, width: 2.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.sky, width: 3),
                ),
                filled: true,
                fillColor: AppColors.sky.withValues(alpha: 0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultBubble() {
    if (_result == null) return const SizedBox.shrink();
    final r = _result!;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: r.isCorrect ? AppColors.success : AppColors.error,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline, width: 3),
        boxShadow: [
          BoxShadow(
            color: (r.isCorrect ? AppColors.success : AppColors.error).withValues(alpha: 0.5),
            blurRadius: 0,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AnimatedScale(
              scale: _resultAnimating ? 1.4 : 1.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              child: Text(
                r.isCorrect ? '🎉' : '😅',
                style: const TextStyle(fontSize: 52),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              r.isCorrect ? 'AWESOME!' : 'OOPS!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              r.isCorrect ? 'You got it right!' : 'Better luck next time!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            if (!r.isCorrect) ...[
              const SizedBox(height: 14),
              _buildCorrectAnswer(r),
            ],
            if (r.newBadges.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏅', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Badge: ${r.newBadges.join(', ')}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectAnswer(AnswerResult r) {
    final correct = r.correctAnswer;
    String? correctText;

    if (r.questionType == 'single_choice' && correct.singleChoiceAnswer != null) {
      final opt = r.options
          .where((o) => o.id == correct.singleChoiceAnswer)
          .firstOrNull;
      correctText = opt?.text ?? '???';
    } else if (r.questionType == 'multiple_choice' &&
        correct.multipleChoiceAnswer != null) {
      correctText = correct.multipleChoiceAnswer!
          .map((id) => r.options.where((o) => o.id == id).firstOrNull?.text ?? id)
          .join(' + ');
    } else if (r.questionType == 'fill_in_blank' && correct.fillInAnswer != null) {
      correctText = correct.fillInAnswer;
    }

    if (correctText == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline, width: 2),
      ),
      child: Row(
        children: [
          const Text('✅', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Answer: $correctText',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(Question q) {
    final canSubmit = q.isSingleChoice && _selectedSingle != null ||
        q.isMultipleChoice && _selectedMultiple.isNotEmpty ||
        q.isFillInBlank && _fillInController.text.trim().isNotEmpty;

    return FilledButton(
      onPressed: canSubmit && !_submitting ? _submitAnswer : null,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.secondary,
        disabledBackgroundColor: AppColors.outline.withValues(alpha: 0.2),
        shadowColor: AppColors.secondary.withValues(alpha: 0.5),
      ),
      child: _submitting
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
            )
          : const Text('SUBMIT!'),
    );
  }

  Widget _buildNextButton() {
    if (widget.isReviewMode) {
      return FilledButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Text('📚', style: TextStyle(fontSize: 16)),
        label: const Text('BACK TO REVIEW'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shadowColor: AppColors.primary.withValues(alpha: 0.5),
        ),
      );
    }
    return FilledButton.icon(
      onPressed: _loadQuestion,
      icon: const Text('▶️', style: TextStyle(fontSize: 16)),
      label: Text(_next?.remainingCount != null && _next!.remainingCount > 0
          ? 'NEXT QUESTION  (${_next!.remainingCount} left)'
          : 'NEXT QUESTION'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        shadowColor: AppColors.primary.withValues(alpha: 0.5),
      ),
    );
  }
}

class _SpeechTrianglePainter extends CustomPainter {
  final Color color;
  _SpeechTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2 - 15, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + 15, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
