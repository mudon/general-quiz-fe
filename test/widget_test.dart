import 'package:flutter_test/flutter_test.dart';
import 'package:general_quiz_flutter/main.dart';
import 'package:general_quiz_flutter/services/api_service.dart';
import 'package:general_quiz_flutter/services/auth_service.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    final api = ApiService();
    final auth = AuthService(api);
    await tester.pumpWidget(QuizApp(authService: auth, apiService: api));
    expect(find.text('General Knowledge Quiz'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
