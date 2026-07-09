import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  await apiService.init();

  final sessionAlive = await apiService.tryAutoRefresh();

  final authService = AuthService(apiService);

  apiService.onLogout = () {
    authService.logout();
  };

  runApp(QuizApp(
    authService: authService,
    apiService: apiService,
    isAutoLoggedIn: sessionAlive,
  ));
}

class QuizApp extends StatelessWidget {
  final AuthService authService;
  final ApiService apiService;
  final bool isAutoLoggedIn;

  const QuizApp({
    super.key,
    required this.authService,
    required this.apiService,
    this.isAutoLoggedIn = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Deck',
      debugShowCheckedModeBanner: false,
      theme: DeckTheme.light,
      initialRoute: isAutoLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (_) => LoginScreen(authService: authService),
        '/register': (_) => RegisterScreen(authService: authService),
        '/forgot-password': (_) =>
            ForgotPasswordScreen(authService: authService),
        '/home': (_) =>
            MainScreen(authService: authService, apiService: apiService),
      },
    );
  }
}
