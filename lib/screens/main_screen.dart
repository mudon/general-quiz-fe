import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/categories_cubit.dart';
import '../cubits/category_completion_cubit.dart';
import '../cubits/review_cubit.dart';
import '../cubits/stats_cubit.dart';
import '../cubits/profile_cubit.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/quiz_service.dart';
import '../services/review_service.dart';
import '../services/stats_service.dart';
import '../services/profile_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import 'tabs/quiz_tab.dart';
import 'tabs/review_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/stats_tab.dart';

class MainScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;

  const MainScreen(
      {super.key, required this.authService, required this.apiService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    final catService = CategoryService(widget.apiService);
    final quizService = QuizService(widget.apiService);
    final reviewService = ReviewService(widget.apiService);
    final statsService = StatsService(widget.apiService);
    final profileService = ProfileService(widget.apiService);
    final subscriptionService = SubscriptionService(widget.apiService);

    _tabs = [
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => CategoriesCubit(catService)..load()),
          BlocProvider(
              create: (_) => CategoryCompletionCubit(catService)..load()),
        ],
        child: QuizTab(
          quizService: quizService,
          subscriptionService: subscriptionService,
          apiService: widget.apiService,
        ),
      ),
      BlocProvider(
        create: (_) => ReviewCubit(reviewService)..load(),
        child: ReviewTab(quizService: quizService),
      ),
      BlocProvider(
        create: (_) => StatsCubit(statsService)..load(),
        child: const StatsTab(),
      ),
      BlocProvider(
        create: (_) => ProfileCubit(profileService)..load(),
        child: ProfileTab(
            authService: widget.authService,
            subscriptionService: subscriptionService),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: DeckColors.ink, width: 2),
          ),
          color: DeckColors.paper,
        ),
        padding: const EdgeInsets.only(top: 7, bottom: 10),
        child: Row(
          children: [
            _buildTab(0, '\u{1F9E0}', 'Quiz'),
            _buildTab(1, '\u{1F4DA}', 'Review'),
            _buildTab(2, '\u{1F4CA}', 'Stats'),
            _buildTab(3, '\u{1F464}', 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String icon, String label) {
    final active = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 2),
            Text(
              label,
              style: DeckTheme.ibmPlexMono(
                fontSize: 8.5,
                color: active ? DeckColors.ink : DeckColors.graphiteFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
