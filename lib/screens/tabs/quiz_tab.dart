import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/categories_cubit.dart';
import '../../cubits/category_completion_cubit.dart';
import '../../cubits/review_cubit.dart';
import '../../cubits/stats_cubit.dart';
import '../../models/category.dart';
import '../../services/api_service.dart';
import '../../services/quiz_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';
import '../quiz/question_screen.dart';
import '../subscription_screen.dart';

class QuizTab extends StatefulWidget {
  final QuizService quizService;
  final SubscriptionService subscriptionService;
  final ApiService apiService;
  final VoidCallback? onSwitchToReview;

  const QuizTab({
    super.key,
    required this.quizService,
    required this.subscriptionService,
    required this.apiService,
    this.onSwitchToReview,
  });

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  String _currency = 'myr';

  int get currentTier => widget.apiService.cachedUserTier;
  QuizService get quizService => widget.quizService;
  SubscriptionService get subscriptionService => widget.subscriptionService;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        if (state.loading) return _loadingBody();
        if (state.error != null) return _errorBody(context, state.error!);
        if (state.categories == null || state.categories!.isEmpty) {
          return _emptyBody();
        }
        final cats = state.categories!;
        return RefreshIndicator(
          onRefresh: () async {
            final cc = context.read<CategoriesCubit>();
            final co = context.read<CategoryCompletionCubit>();
            await cc.load();
            co.load();
          },
          color: DeckColors.blue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: BlocBuilder<CategoryCompletionCubit,
                Map<String, Map<String, int>>>(
              builder: (context, completion) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 14),
                    _buildStatsRow(context),
                    const SizedBox(height: 14),
                    _buildDueCard(context),
                    const SizedBox(height: 14),
                    _sectionLabel('Categories'),
                    ...cats.map((cat) {
                      final locked =
                          cat.children.isEmpty && cat.tier > currentTier;
                      return _buildCatCard(context, completion, cat, locked);
                    }),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _loadingBody() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('\u{1F9E0}', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Loading topics...',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: DeckColors.graphite)),
        ],
      ),
    );
  }

  Widget _errorBody(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error,
                textAlign: TextAlign.center,
                style: DeckTheme.ibmPlexMono(color: DeckColors.graphite)),
            const SizedBox(height: 16),
            _btnPrimary('TRY AGAIN', () => context.read<CategoriesCubit>().load()),
          ],
        ),
      ),
    );
  }

  Widget _emptyBody() {
    return Center(
      child: Text('No topics yet!',
          style: DeckTheme.spaceGrotesk(
              fontSize: 15, color: DeckColors.graphite)),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text('Quiz Deck',
            style: DeckTheme.spaceGrotesk(fontSize: 17)),
        const SizedBox(height: 2),
        BlocBuilder<StatsCubit, StatsState>(
          builder: (context, state) {
            final answered = state.stats?.totalQuestionsAnswered ?? 0;
            final streak = state.stats?.totalCorrectStreak ?? 0;
            return Text('$answered questions answered \u00B7 $streak correct in a row',
                style: DeckTheme.ibmPlexMono(
                    fontSize: 10, color: DeckColors.graphite));
          },
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return BlocBuilder<StatsCubit, StatsState>(
      builder: (context, state) {
        final s = state.stats;
        final answered = s?.totalQuestionsAnswered ?? 0;
        final streak = s?.totalCorrectStreak ?? 0;
        final login = s?.currentLoginStreak ?? 0;
        return Row(
          children: [
            _statChip('$answered', 'Answered'),
            const SizedBox(width: 8),
            _statChip('$streak', 'Streak'),
            const SizedBox(width: 8),
            _statChip('$login', 'Login'),
          ],
        );
      },
    );
  }

  Widget _statChip(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
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
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: DeckTheme.ibmPlexMono(
                    fontSize: 8, color: DeckColors.graphite)),
          ],
        ),
      ),
    );
  }

  Widget _buildDueCard(BuildContext context) {
    return BlocBuilder<ReviewCubit, ReviewState>(
      builder: (context, revState) {
        final count = revState.items?.length ?? 0;
        return GestureDetector(
          onTap: () => widget.onSwitchToReview?.call(),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: DeckColors.yellowBg,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: DeckColors.yellow,
                  width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Due for review',
                          style: DeckTheme.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Spaced-repetition queue',
                          style: DeckTheme.ibmPlexMono(
                              fontSize: 9,
                              color: DeckColors.graphite)),
                    ],
                  ),
                ),
                Text('$count',
                    style: DeckTheme.spaceGrotesk(
                        fontSize: 21,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                Text('\u2192',
                    style: TextStyle(
                        fontSize: 17,
                        color: DeckColors.graphiteFaint)),
              ],
            ),
          ),
        );
      },
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

  Widget _buildCatCard(BuildContext context,
      Map<String, Map<String, int>> completion, Category cat, bool locked) {
    final emoji = iconToEmoji(cat.icon);
    final completed = completion[cat.id]?['completed'] == 1;
    final total = completion[cat.id]?['total'] ?? 0;
    final answered = completion[cat.id]?['answered'] ?? 0;

    return GestureDetector(
      onTap: () => _onCategoryTap(context, cat),
      child: Opacity(
        opacity: locked ? 0.55 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: DeckColors.paperDark,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: DeckColors.rule),
          ),
          child: Row(
            children: [
              SizedBox(
                  width: 26,
                  child: Text(emoji, style: const TextStyle(fontSize: 19), textAlign: TextAlign.center)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name,
                        style: DeckTheme.spaceGrotesk(fontSize: 13)),
                    Text(
                      completed
                          ? 'Completed'
                          : locked
                              ? '${total} questions'
                              : '$answered/$total questions \u00B7 Free',
                      style: DeckTheme.ibmPlexMono(fontSize: 9),
                    ),
                  ],
                ),
              ),
              if (locked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DeckColors.yellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cat.tier == 3 ? 'RM99.99' : cat.tier == 2 ? 'RM54.99' : 'RM16.99',
                    style: DeckTheme.ibmPlexMono(
                        fontSize: 8, fontWeight: FontWeight.w600, color: DeckColors.ink),
                  ),
                )
              else
                Text('\u203A',
                    style: TextStyle(fontSize: 14, color: DeckColors.graphiteFaint)),
            ],
          ),
        ),
      ),
    );
  }

  void _onCategoryTap(BuildContext context, Category cat) {
    if (cat.children.isNotEmpty) {
      _showSubcategories(context, cat);
    } else if (cat.tier > currentTier) {
      _showUpgradeDialog(context, cat);
    } else {
      _startSession(context, cat);
    }
  }

  Future<void> _startSession(BuildContext context, Category cat) async {
    try {
      final sessions = await quizService.getActiveSessions();
      final active = sessions.where((s) => s.categoryId == cat.id).toList();
      if (!context.mounted) return;

      if (active.isNotEmpty) {
        final session = active.first;
        final remaining = session.totalQuestions - session.answeredCount;
        final result = await showDialog<String>(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DeckColors.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DeckColors.ink, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('\u23F3', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text('ACTIVE QUIZ',
                      style: DeckTheme.spaceGrotesk(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(cat.name,
                      style: DeckTheme.spaceGrotesk(
                          fontSize: 14, color: DeckColors.blue)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dialogStat('\u{1F4DD}',
                          '${session.answeredCount}/${session.totalQuestions}',
                          'ANSWERED'),
                      const SizedBox(width: 20),
                      _dialogStat('\u23F0', '$remaining', 'REMAINING'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _btnPrimary('RESUME', () => Navigator.pop(ctx, 'resume')),
                  const SizedBox(height: 8),
                  _btnOutline('START FRESH',
                      () => Navigator.pop(ctx, 'new')),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, 'cancel'),
                    child: Text('Cancel',
                        style: DeckTheme.ibmPlexMono(
                            fontSize: 9, color: DeckColors.graphiteFaint)),
                  ),
                ],
              ),
            ),
          ),
        );

        if (!context.mounted) return;
        if (result == 'resume') {
          await _pushQuestionScreen(context, session.sessionId, cat.name);
          return;
        }
        if (result == 'new') {
          await quizService.resetSession(session.sessionId);
          if (!context.mounted) return;
          await _pushQuestionScreen(context, session.sessionId, cat.name);
          return;
        }
        return;
      }

      final session = await quizService.createSession(categoryId: cat.id);
      if (!context.mounted) return;
      await _pushQuestionScreen(context, session.sessionId, cat.name);
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString();
        if (msg.contains('tier') ||
            msg.contains('Upgrade') ||
            msg.contains('subscription')) {
          _showUpgradeDialog(context, cat);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(msg.replaceFirst('Exception: ', ''),
                    style: DeckTheme.ibmPlexMono(
                        color: DeckColors.paper, fontSize: 10))),
          );
        }
      }
    }
  }

  Widget _dialogStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(value,
            style:
                DeckTheme.spaceGrotesk(fontSize: 18, color: DeckColors.ink)),
        Text(label,
            style: DeckTheme.ibmPlexMono(fontSize: 8)),
      ],
    );
  }

  Future<void> _pushQuestionScreen(
      BuildContext context, String sessionId, String categoryName) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuestionScreen(
          quizService: quizService,
          sessionId: sessionId,
          categoryName: categoryName,
        ),
      ),
    );
    if (context.mounted) {
      context.read<CategoryCompletionCubit>().load();
    }
  }

  void _showSubcategories(BuildContext context, Category parent) {
    final cubit = context.read<CategoryCompletionCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: _SubcategoryPage(
            parent: parent,
            currentTier: currentTier,
            onTap: (child) => _onCategoryTap(context, child),
            quizService: quizService,
          ),
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, Category cat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubscriptionScreen(
          subscriptionService: subscriptionService,
          currentTier: currentTier,
          currency: _currency,
        ),
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

class _SubcategoryPage extends StatelessWidget {
  final Category parent;
  final int currentTier;
  final void Function(Category) onTap;
  final QuizService quizService;

  const _SubcategoryPage({
    required this.parent,
    required this.currentTier,
    required this.onTap,
    required this.quizService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DeckColors.paper,
      appBar: AppBar(
        title: Text(parent.name),
        leading: _backButton(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: BlocBuilder<CategoryCompletionCubit,
              Map<String, Map<String, int>>>(
            builder: (context, completion) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Sub-categories',
                        style: DeckTheme.ibmPlexMono(
                            fontSize: 9,
                            color: DeckColors.graphite,
                            letterSpacing: 0.1)),
                  ),
                  ...parent.children.map((child) {
                    final locked =
                        child.children.isEmpty && child.tier > currentTier;
                    final emoji = iconToEmoji(child.icon);
                    final completed =
                        completion[child.id]?['completed'] == 1;
                    final total =
                        completion[child.id]?['total'] ?? 0;
                    return GestureDetector(
                      onTap: () => onTap(child),
                      child: Opacity(
                        opacity: locked ? 0.55 : 1.0,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            color: DeckColors.paperDark,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: DeckColors.rule),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                  width: 26,
                                  child: Text(emoji,
                                      style: const TextStyle(fontSize: 19),
                                      textAlign: TextAlign.center)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(child.name,
                                        style: DeckTheme.spaceGrotesk(
                                            fontSize: 13)),
                                    Text(
                                      completed
                                          ? 'Completed'
                                          : '$total questions',
                                      style: DeckTheme.ibmPlexMono(
                                          fontSize: 9),
                                    ),
                                  ],
                                ),
                              ),
                              if (locked)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: DeckColors.yellow,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    child.tier == 3 ? 'RM99.99' : child.tier == 2 ? 'RM54.99' : 'RM16.99',
                                    style: DeckTheme.ibmPlexMono(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: DeckColors.ink),
                                  ),
                                )
                              else
                                Text('\u203A',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: DeckColors.graphiteFaint)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
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

String iconToEmoji(String? icon) {
  switch (icon) {
    case 'microscope': case 'dna': case 'flask': case 'atom': case 'rocket':
    case 'calculator': case 'brain': case 'bolt': case 'beaker':
      return '\u{1F52C}';
    case 'scroll': case 'landmark': case 'swords': case 'building':
    case 'helmet': case 'bomb':
      return '\u{1F3DB}\uFE0F';
    case 'globe': case 'map': case 'city': case 'waves':
    case 'monument': case 'compass':
      return '\u{1F30D}';
    case 'film': case 'clapperboard': case 'music': case 'tv':
    case 'gamepad': case 'award':
      return '\u{1F3AC}';
    case 'laptop': case 'smartphone': case 'shield':
      return '\u{1F4BB}';
    case 'trophy': case 'football': case 'basketball': case 'medal':
      return '\u26BD';
    case 'utensils': case 'bowl': case 'cake': case 'coffee':
      return '\u{1F354}';
    default:
      return '\u2B50';
  }
}

String catEmoji(String name) {
  final n = name.toLowerCase();
  if (n.contains('geo')) return '\u{1F30D}';
  if (n.contains('sci')) return '\u{1F9EA}';
  if (n.contains('film') || n.contains('tv')) return '\u{1F3AC}';
  if (n.contains('hist')) return '\u{1F3DB}\uFE0F';
  if (n.contains('cap')) return '\u{1F3D9}';
  if (n.contains('river') || n.contains('mount')) return '\u26F0\uFE0F';
  if (n.contains('chem')) return '\u2697\uFE0F';
  if (n.contains('phys')) return '\u269B\uFE0F';
  return '\u2B50';
}
