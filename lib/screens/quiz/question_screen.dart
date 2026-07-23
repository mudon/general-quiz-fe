import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';

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

  int _sessionAnswered = 0;
  int _sessionTotal = 0;
  bool _sessionCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  @override
  void dispose() {
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
    });
    try {
      if (widget.isReviewMode && widget.initialQuestion != null) {
        setState(() {
          _question = widget.initialQuestion;
          _loading = false;
        });
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
            _sessionTotal = next.totalQuestions;
            _sessionAnswered = next.answeredCount;
            _loading = false;
          });
        }
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
        submittedFillIn:
            q.isFillInBlank ? _fillInController.text.trim() : null,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _submitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString(),
                  style: DeckTheme.ibmPlexMono(
                      color: DeckColors.paper, fontSize: 10))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DeckColors.paper,
      appBar: AppBar(
        title: Text(
          _sessionCompleted ? 'Session complete' : widget.categoryName,
          style: DeckTheme.spaceGrotesk(fontSize: 17),
        ),
        leading: _backButton(context),
        actions: [
          if (!_sessionCompleted && _sessionTotal > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildPill(
                  'Q ${_sessionAnswered + 1}/$_sessionTotal'),
            ),
        ],
      ),
      body: _buildBody(),
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

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('\u{1F914}', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Finding a question...',
                style: TextStyle(fontSize: 14, color: DeckColors.graphite)),
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
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: DeckTheme.ibmPlexMono(color: DeckColors.graphite)),
              const SizedBox(height: 16),
              _btn('TRY AGAIN', () => _loadQuestion()),
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
              Text('No questions here yet!',
                  style: DeckTheme.spaceGrotesk(
                      fontSize: 16, color: DeckColors.graphite)),
              const SizedBox(height: 16),
              _btn('GO BACK', () => Navigator.of(context).pop()),
            ],
          ),
        ),
      );
    }

    final q = _question!;
    final answered = _result != null;
    final progress = _sessionTotal > 0
        ? (_sessionAnswered + (answered ? 1 : 0)) / _sessionTotal
        : 0.0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgress(progress),
                _buildMeta(q),
                const SizedBox(height: 12),
                Text(q.questionText,
                    style: DeckTheme.literata(
                        fontSize: 16.5, height: 1.4)),
                const SizedBox(height: 14),
                if (answered)
                  _buildRevealedOptions(q)
                else
                  _buildOptions(q),
                if (answered) ...[
                  const SizedBox(height: 14),
                  _buildFeedback(),
                ],
              ],
            ),
          ),
        ),
        if (!answered)
          _buildBottomAction(q)
        else
          _buildBottomNext(),
      ],
    );
  }

  Widget _buildProgress(double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Container(
          height: 4,
          color: DeckColors.rule,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(color: DeckColors.blue),
          ),
        ),
      ),
    );
  }

  Widget _buildMeta(Question q) {
    String type;
    switch (q.questionType) {
      case 'multiple_choice':
        type = 'Multiple choice';
        break;
      case 'fill_in_blank':
        type = 'Fill in the blank';
        break;
      default:
        type = 'Single choice';
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            q.categoryPath.isNotEmpty ? q.categoryPath : widget.categoryName,
            style: DeckTheme.ibmPlexMono(fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: DeckColors.graphiteFaint),
          ),
          child: Text(type,
              style: DeckTheme.ibmPlexMono(
                  fontSize: 8.5, letterSpacing: 0.06)),
        ),
      ],
    );
  }

  Widget _buildOptions(Question q) {
    if (q.isSingleChoice) return _buildSingleChoiceOptions(q, false);
    if (q.isMultipleChoice) return _buildMultipleChoiceOptions(q, false);
    return _buildFillInBlankInput(false);
  }

  Widget _buildRevealedOptions(Question q) {
    if (q.isSingleChoice) return _buildSingleChoiceOptions(q, true);
    if (q.isMultipleChoice) return _buildMultipleChoiceOptions(q, true);
    return _buildFillInBlankInput(true);
  }

  Widget _buildSingleChoiceOptions(Question q, bool revealed) {
    return Column(
      children: q.options.map((opt) {
        final isSelected = _selectedSingle == opt.id;
        final isCorrect = revealed &&
            _result?.correctAnswer.singleChoiceAnswer == opt.id;
        final isIncorrectSelection =
            revealed && isSelected && !isCorrect;

        Color? borderColor;
        Color? bgColor;
        if (isIncorrectSelection) {
          borderColor = DeckColors.red;
          bgColor = DeckColors.redFaint;
        } else if (isCorrect) {
          borderColor = DeckColors.green;
          bgColor = DeckColors.greenFaint;
        } else if (isSelected) {
          borderColor = DeckColors.blue;
          bgColor = DeckColors.blueFaint;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: revealed ? null : () => setState(() => _selectedSingle = opt.id),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: bgColor ?? DeckColors.paper,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: borderColor ?? DeckColors.rule, width: 1.5),
              ),
              child: Row(
                children: [
                  _buildBubble(
                      (isCorrect || isSelected) && !isIncorrectSelection,
                      borderColor ?? DeckColors.graphite,
                      false),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(opt.text,
                        style: DeckTheme.spaceGrotesk(fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleChoiceOptions(Question q, bool revealed) {
    return Column(
      children: q.options.map((opt) {
        final isSelected = _selectedMultiple.contains(opt.id);
        final isCorrect = revealed &&
            (_result?.correctAnswer.multipleChoiceAnswer
                    ?.contains(opt.id) ??
                false);
        final isIncorrectSelection =
            revealed && isSelected && !isCorrect;

        Color? borderColor;
        Color? bgColor;
        if (isIncorrectSelection) {
          borderColor = DeckColors.red;
          bgColor = DeckColors.redFaint;
        } else if (isCorrect) {
          borderColor = DeckColors.green;
          bgColor = DeckColors.greenFaint;
        } else if (isSelected) {
          borderColor = DeckColors.blue;
          bgColor = DeckColors.blueFaint;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: revealed
                ? null
                : () {
                    setState(() {
                      if (isSelected) {
                        _selectedMultiple.remove(opt.id);
                      } else {
                        _selectedMultiple.add(opt.id);
                      }
                    });
                  },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: bgColor ?? DeckColors.paper,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: borderColor ?? DeckColors.rule, width: 1.5),
              ),
              child: Row(
                children: [
                  _buildBubble(
                      (isCorrect || isSelected) && !isIncorrectSelection,
                      borderColor ?? DeckColors.graphite,
                      true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(opt.text,
                        style: DeckTheme.spaceGrotesk(fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBubble(bool checked, Color borderColor, bool isCheckbox) {
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        color: DeckColors.paper,
        borderRadius:
            BorderRadius.circular(isCheckbox ? 5 : 19),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: checked
          ? CustomPaint(
              painter: _CheckmarkPainter(borderColor),
              size: const Size(19, 19),
            )
          : null,
    );
  }

  Widget _buildFillInBlankInput(bool revealed) {
    if (revealed && _result != null) {
      final isCorrect = _result!.isCorrect;
      final submitted = _fillInController.text.trim();
      final correctAnswer = _result!.correctAnswer.fillInAnswer ?? '';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color:
                  isCorrect ? DeckColors.greenFaint : DeckColors.redFaint,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: isCorrect ? DeckColors.green : DeckColors.red,
                  width: 1.5),
            ),
            child: Text(
              submitted.isNotEmpty ? submitted : correctAnswer,
              style: DeckTheme.literata(
                  fontSize: 14, color: DeckColors.ink),
            ),
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 7),
            Text('Accepted answer: $correctAnswer',
                style: DeckTheme.ibmPlexMono(
                    fontSize: 9.5, color: DeckColors.green)),
          ],
        ],
      );
    }

    return TextField(
      controller: _fillInController,
      style: DeckTheme.literata(fontSize: 14, color: DeckColors.ink),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Type your answer...',
        hintStyle: DeckTheme.literata(
            fontSize: 14, color: DeckColors.graphiteFaint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: DeckColors.rule),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: DeckColors.rule),
        ),
        filled: true,
        fillColor: DeckColors.paper,
      ),
    );
  }

  Widget _buildFeedback() {
    if (_result == null) return const SizedBox.shrink();
    final r = _result!;
    final isCorrect = r.isCorrect;

    return Container(
      padding:
          const EdgeInsets.only(top: 11, left: 13, right: 13, bottom: 11),
      decoration: BoxDecoration(
        color: isCorrect ? DeckColors.greenFaint : DeckColors.redFaint,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
            color: isCorrect ? DeckColors.green : DeckColors.red),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 70),
                child: Text(isCorrect ? 'Correct' : 'Not quite',
                    style: DeckTheme.spaceGrotesk(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              if (r.explanation != null && r.explanation!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 32),
                  child: Text(r.explanation!,
                      style: DeckTheme.literata(
                          fontSize: 12, height: 1.4)),
                ),
              ],
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Transform.rotate(
              angle: -6 * pi / 180,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color:
                          isCorrect ? DeckColors.green : DeckColors.red,
                      width: 2),
                ),
                child: Text(isCorrect ? 'CORRECT' : 'INCORRECT',
                    style: DeckTheme.ibmPlexMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isCorrect
                            ? DeckColors.green
                            : DeckColors.red,
                        letterSpacing: 0.1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(Question q) {
    final canSubmit = q.isSingleChoice && _selectedSingle != null ||
        q.isMultipleChoice && _selectedMultiple.isNotEmpty ||
        q.isFillInBlank && _fillInController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 14),
      decoration: const BoxDecoration(
        color: DeckColors.paper,
        border: Border(
            top: BorderSide(color: DeckColors.rule)),
      ),
      child: _btn(
        'Lock in answer',
        canSubmit ? () => _submitAnswer() : null,
        enabled: canSubmit,
        loading: _submitting,
      ),
    );
  }

  Widget _buildBottomNext() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 14),
      decoration: const BoxDecoration(
        color: DeckColors.paper,
        border: Border(
            top: BorderSide(color: DeckColors.rule)),
      ),
      child: Column(
        children: [
          _btn(
            widget.isReviewMode ? 'BACK TO REVIEW' : 'Next question',
            () {
              if (widget.isReviewMode) {
                Navigator.of(context).pop();
              } else {
                _loadQuestion();
              }
            },
          ),
          if (!widget.isReviewMode) ...[
            const SizedBox(height: 7),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text('Back to categories',
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'IBM Plex Mono',
                    color: DeckColors.graphiteFaint,
                    decoration: TextDecoration.underline,
                  )),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedScreen() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.categoryName,
                      style: DeckTheme.ibmPlexMono(
                          fontSize: 10,
                          color: DeckColors.graphite,
                          letterSpacing: 0.08)),
                  const SizedBox(height: 4),
                  Text('$_sessionAnswered/$_sessionTotal',
                      style: DeckTheme.spaceGrotesk(
                          fontSize: 42,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${_sessionTotal > 0 ? (_sessionAnswered * 100 ~/ _sessionTotal) : 0}% correct',
                    style: DeckTheme.ibmPlexMono(
                        fontSize: 10,
                        color: DeckColors.graphite,
                        letterSpacing: 0.08),
                  ),
                  const SizedBox(height: 24),
                  _buildBadgeRow(),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 14),
          decoration: const BoxDecoration(
            color: DeckColors.paper,
            border: Border(
                top: BorderSide(color: DeckColors.rule)),
          ),
          child: Column(
            children: [
              _btn('Finished', () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeRow() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Badge(icon: '\u{1F525}', label: 'Streak', isNew: false),
        SizedBox(width: 12),
        _Badge(icon: '\u{1F3AF}', label: 'Sharp', isNew: true),
        SizedBox(width: 12),
        _Badge(icon: '\u{1F9E0}', label: 'Genius', isNew: false),
      ],
    );
  }

  Widget _btn(String label, VoidCallback? onTap,
      {bool enabled = true, bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: (enabled && !loading) ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: enabled ? DeckColors.ink : DeckColors.graphiteFaint,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: DeckColors.paper),
                  )
                : Text(label,
                    style: DeckTheme.spaceGrotesk(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: DeckColors.paper)),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String icon;
  final String label;
  final bool isNew;

  const _Badge(
      {required this.icon, required this.label, required this.isNew});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNew ? DeckColors.yellowBg : DeckColors.paperDark,
              border: Border.all(
                  color: isNew ? DeckColors.yellow : DeckColors.rule,
                  width: 2),
              boxShadow: isNew
                  ? [
                      BoxShadow(
                          color: DeckColors.yellowBg,
                          blurRadius: 0,
                          offset: const Offset(0, 0),
                          spreadRadius: 3),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: DeckTheme.ibmPlexMono(
                  fontSize: 8.5, color: DeckColors.graphite)),
        ],
      ),
    );
  }
}

Widget _backButton(BuildContext context) {
  return GestureDetector(
    onTap: () => Navigator.of(context).pop(),
    child: Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: DeckColors.paperDark,
        shape: BoxShape.circle,
        border: Border.all(color: DeckColors.rule),
      ),
      child: const Center(
        child: Text('\u2190', style: TextStyle(fontSize: 13, color: DeckColors.ink)),
      ),
    ),
  );
}

class _CheckmarkPainter extends CustomPainter {
  final Color color;
  _CheckmarkPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.69)
      ..lineTo(size.width * 0.78, size.height * 0.31);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
