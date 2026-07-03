class ApiConfig {
  static const String baseUrl = 'http://localhost:3000';

  // ── auth ──
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String refresh = '/api/auth/refresh';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';
  static const String changePassword = '/api/auth/password';
  static const String changeEmail = '/api/auth/change-email';
  static const String verifyNewEmail = '/api/auth/verify-new-email';
  static const String updateProfile = '/api/auth/profile';
  static const String sendVerification = '/api/auth/send-verification';
  static const String resendVerification = '/api/auth/resend-verification';
  static const String verifyEmail = '/api/auth/verify-email';

  // ── categories ──
  static const String categories = '/api/categories';
  static String categoryById(String id) => '/api/categories/$id';
  static const String categoryCompletion = '/api/categories/completion-status';
  static const String adminCategories = '/api/admin/categories';
  static String adminCategoryById(String id) => '/api/admin/categories/$id';

  // ── questions ──
  static const String questions = '/api/questions';
  static String questionById(String id) => '/api/questions/$id';
  static String answerQuestion(String id) => '/api/questions/$id/answer';
  static String adminQuestionById(String id) => '/api/admin/questions/$id';
  static const String adminQuestions = '/api/admin/questions';

  // ── answers ──
  static const String reviewDue = '/api/review/due';
  static const String answerHistory = '/api/answers/history';

  // ── stats ──
  static const String stats = '/api/stats';
  static const String statsCategories = '/api/stats/categories';

  // ── badges ──
  static const String badges = '/api/badges';
  static const String earnedBadges = '/api/badges/earned';
  static const String selectBadge = '/api/users/me/badge';
  static const String adminBadges = '/api/admin/badges';
  static String adminBadgeById(String id) => '/api/admin/badges/$id';

  // ── admin users ──
  static const String adminUsers = '/api/admin/users';
  static String adminUserById(String id) => '/api/admin/users/$id';
  static String adminUserRole(String id) => '/api/admin/users/$id/role';

  // ── quiz sessions ──
  static const String quizSessions = '/api/quiz/sessions';
  static String quizSessionNext(String id) => '/api/quiz/sessions/$id/next';
  static String quizSessionReset(String id) => '/api/quiz/sessions/$id/reset';

  // ── subscriptions ──
  static const String subPlans = '/api/subscriptions/plans';
  static const String subCheckout = '/api/subscriptions/checkout';

  // ── health ──
  static const String health = '/health';
}
