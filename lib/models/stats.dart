class UserStats {
  final int totalQuestionsAnswered;
  final int totalCorrectStreak;
  final int currentLoginStreak;
  final int longestLoginStreak;
  final String? lastActivityDate;

  UserStats({
    required this.totalQuestionsAnswered,
    required this.totalCorrectStreak,
    required this.currentLoginStreak,
    required this.longestLoginStreak,
    this.lastActivityDate,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalQuestionsAnswered: json['totalQuestionsAnswered'] ?? 0,
      totalCorrectStreak: json['totalCorrectStreak'] ?? 0,
      currentLoginStreak: json['currentLoginStreak'] ?? 0,
      longestLoginStreak: json['longestLoginStreak'] ?? 0,
      lastActivityDate: json['lastActivityDate']?.toString(),
    );
  }
}

class CategoryStat {
  final String categoryId;
  final String categoryName;
  final String categoryPath;
  final int questionsAnswered;
  final int correctAnswers;
  final double accuracy;
  final String? lastAnsweredAt;

  CategoryStat({
    required this.categoryId,
    required this.categoryName,
    required this.categoryPath,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.accuracy,
    this.lastAnsweredAt,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      categoryId: (json['categoryId'] ?? '').toString(),
      categoryName: json['categoryName'] ?? '',
      categoryPath: json['categoryPath'] ?? '',
      questionsAnswered: json['questionsAnswered'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      lastAnsweredAt: json['lastAnsweredAt']?.toString(),
    );
  }
}
