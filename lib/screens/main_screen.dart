import 'package:flutter/material.dart';
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
      QuizTab(categoryService: catService, quizService: quizService),
      ReviewTab(reviewService: reviewService, quizService: quizService),
      StatsTab(statsService: statsService),
      ProfileTab(authService: widget.authService, profileService: profileService),
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
