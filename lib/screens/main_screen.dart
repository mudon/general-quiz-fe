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
import 'tabs/quiz_tab.dart';
import 'tabs/review_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/stats_tab.dart';

class MainScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;

  const MainScreen({super.key, required this.authService, required this.apiService});

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

    _tabs = [
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => CategoriesCubit(catService)..load()),
          BlocProvider(create: (_) => CategoryCompletionCubit(catService)..load()),
        ],
        child: QuizTab(quizService: quizService),
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
        child: ProfileTab(authService: widget.authService),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        animationDuration: const Duration(milliseconds: 400),
        destinations: const [
          NavigationDestination(
            icon: Text('🧠', style: TextStyle(fontSize: 24)),
            selectedIcon: Text('🧠', style: TextStyle(fontSize: 24)),
            label: 'QUIZ',
          ),
          NavigationDestination(
            icon: Text('📚', style: TextStyle(fontSize: 24)),
            selectedIcon: Text('📚', style: TextStyle(fontSize: 24)),
            label: 'REVIEW',
          ),
          NavigationDestination(
            icon: Text('📊', style: TextStyle(fontSize: 24)),
            selectedIcon: Text('📊', style: TextStyle(fontSize: 24)),
            label: 'STATS',
          ),
          NavigationDestination(
            icon: Text('😎', style: TextStyle(fontSize: 24)),
            selectedIcon: Text('😎', style: TextStyle(fontSize: 24)),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }
}
