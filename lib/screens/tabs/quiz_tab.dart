import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/categories_cubit.dart';
import '../../cubits/category_completion_cubit.dart';
import '../../models/category.dart';
import '../../services/api_service.dart';
import '../../services/quiz_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_bubble.dart';
import '../quiz/question_screen.dart';
import '../subscription_screen.dart';

class QuizTab extends StatefulWidget {
  final QuizService quizService;
  final SubscriptionService subscriptionService;
  final ApiService apiService;

  const QuizTab({
    super.key,
    required this.quizService,
    required this.subscriptionService,
    required this.apiService,
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
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🧠', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                const Text('QUIZZTOPIA',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
              ],
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CategoriesState state) {
    if (state.loading) {
      return const Center(child: _LoadingIndicator('🧠', 'Loading topics...'));
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
                onPressed: () => context.read<CategoriesCubit>().load(),
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.categories == null || state.categories!.isEmpty) {
      return const Center(
        child: Text('😴 No topics yet!',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary)),
      );
    }

    final cats = state.categories!;

    return RefreshIndicator(
      onRefresh: () async {
        final categoriesCubit = context.read<CategoriesCubit>();
        final completionCubit = context.read<CategoryCompletionCubit>();
        await categoriesCubit.load();
        completionCubit.load();
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: BlocBuilder<CategoryCompletionCubit, Map<String, Map<String, int>>>(
          builder: (context, completion) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (int i = 0; i < cats.length; i++)
                      CategoryBubble(
                        category: cats[i],
                        colorIndex: i,
                        totalQuestions: completion[cats[i].id]?['total'] ?? 0,
                        answeredQuestions: completion[cats[i].id]?['answered'] ?? 0,
                        completed: completion[cats[i].id]?['completed'] == 1,
                        locked: cats[i].children.isEmpty && cats[i].tier > currentTier,
                        onTap: () => _onCategoryTap(context, cats[i]),
                      ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('👇', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Text('PICK A TOPIC TO START!',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5)),
          SizedBox(width: 8),
          Text('👇', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDialogStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary)),
      ],
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
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.outline, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 0,
                    offset: const Offset(6, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⏳', style: TextStyle(fontSize: 44)),
                        const SizedBox(height: 8),
                        const Text('ACTIVE QUIZ',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: 2)),
                        const SizedBox(height: 6),
                        Text(cat.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDialogStat('📝', '${session.answeredCount}/${session.totalQuestions}', 'ANSWERED'),
                            const SizedBox(width: 20),
                            _buildDialogStat('⏰', '$remaining', 'REMAINING'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Text('Pick up where you left off or start fresh!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, 'resume'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          ),
                          child: const Text('▶️  RESUME',
                              style: TextStyle(fontSize: 15, letterSpacing: 2)),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, 'new'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 46),
                          ),
                          child: const Text('🔄  START FRESH',
                              style: TextStyle(fontSize: 13, letterSpacing: 1.5)),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, 'cancel'),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('✕',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.error)),
                        ),
                      ),
                    ),
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
        // 'cancel' or null = do nothing, stay on categories
        return;
      }

      final session = await quizService.createSession(categoryId: cat.id);
      if (!context.mounted) return;
      await _pushQuestionScreen(context, session.sessionId, cat.name);
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString();
        if (msg.contains('tier') || msg.contains('Upgrade') || msg.contains('subscription')) {
          _showUpgradeDialog(context, cat);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg.replaceFirst('Exception: ', ''))),
          );
        }
      }
    }
  }

  Future<void> _pushQuestionScreen(BuildContext context, String sessionId, String categoryName) async {
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
          ),
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, Category cat) {
    final nextTier = currentTier < cat.tier ? cat.tier : currentTier + 1;
    if (nextTier > 2) return;
    const tierPrices = {
      1: {'myr': 49.90, 'usd': 10.99},
      2: {'myr': 229.90, 'usd': 50.99},
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final tierName = nextTier == 2 ? 'All Access' : 'Premium';
          final tierEmoji = nextTier == 2 ? '👑' : '⭐';
          final priceText = _currency == 'usd'
              ? '\$${tierPrices[nextTier]!['usd']!.toStringAsFixed(2)}'
              : 'RM${tierPrices[nextTier]!['myr']!.toStringAsFixed(2)}';

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.outline, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 0,
                    offset: const Offset(6, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔒', style: TextStyle(fontSize: 44)),
                        const SizedBox(height: 8),
                        const Text('LOCKED CATEGORY',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: 2)),
                        const SizedBox(height: 6),
                        Text(cat.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Upgrade your plan to unlock this category and many more!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary)),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => SubscriptionScreen(
                                  subscriptionService: subscriptionService,
                                  currentTier: currentTier,
                                  currency: _currency,
                                ),
                              ),
                            ).then((paid) {
                              if (context.mounted && paid == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Plan upgraded! Refresh to see changes.'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppColors.outline, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 0,
                                  offset: const Offset(4, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(tierEmoji, style: const TextStyle(fontSize: 28)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tierName,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  letterSpacing: 1.5),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              priceText,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white.withValues(alpha: 0.8)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Text('UPGRADE  ➜',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 1)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _currencyOptionDialog('MYR', 'myr', setDialogState),
                                      const SizedBox(width: 4),
                                      _currencyOptionDialog('USD', 'usd', setDialogState),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 46)),
                          child: const Text('CANCEL',
                              style: TextStyle(fontSize: 13, letterSpacing: 1.5)),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('✕',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.error)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _currencyOptionDialog(String label, String value, void Function(void Function()) setDialogState) {
    final selected = _currency == value;
    return GestureDetector(
      onTap: () {
        setDialogState(() {
          setState(() => _currency = value);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : Colors.white70,
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

  const _SubcategoryPage({required this.parent, required this.currentTier, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(parent.name,
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: BlocBuilder<CategoryCompletionCubit, Map<String, Map<String, int>>>(
            builder: (context, completion) {
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (int i = 0; i < parent.children.length; i++)
                    CategoryBubble(
                      category: parent.children[i],
                      colorIndex: parent.depth + i + 1,
                      totalQuestions: completion[parent.children[i].id]?['total'] ?? 0,
                      answeredQuestions: completion[parent.children[i].id]?['answered'] ?? 0,
                      completed: completion[parent.children[i].id]?['completed'] == 1,
                      locked: parent.children[i].children.isEmpty && parent.children[i].tier > currentTier,
                      onTap: () => onTap(parent.children[i]),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  final String emoji;
  final String text;
  const _LoadingIndicator(this.emoji, this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(text,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
