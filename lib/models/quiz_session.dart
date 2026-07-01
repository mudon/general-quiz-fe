import 'question.dart';

class QuizSession {
  final String sessionId;
  final String categoryId;
  final String categoryName;
  final int totalQuestions;
  final int answeredCount;
  final int correctCount;
  final String createdAt;
  final String? completedAt;

  QuizSession({
    required this.sessionId,
    required this.categoryId,
    required this.categoryName,
    required this.totalQuestions,
    required this.answeredCount,
    required this.correctCount,
    required this.createdAt,
    this.completedAt,
  });

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    return QuizSession(
      sessionId: (json['sessionId'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? '').toString(),
      categoryName: json['categoryName'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      answeredCount: json['answeredCount'] ?? 0,
      correctCount: json['correctCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      completedAt: json['completedAt']?.toString(),
    );
  }
}

class NextQuestionResponse {
  final bool completed;
  final int totalQuestions;
  final int answeredCount;
  final Question? question;
  final int remainingCount;

  NextQuestionResponse({
    required this.completed,
    required this.totalQuestions,
    required this.answeredCount,
    this.question,
    this.remainingCount = 0,
  });

  factory NextQuestionResponse.fromJson(Map<String, dynamic> json) {
    if (json['completed'] == true) {
      return NextQuestionResponse(
        completed: true,
        totalQuestions: json['totalQuestions'] ?? 0,
        answeredCount: json['answeredCount'] ?? 0,
      );
    }
    return NextQuestionResponse(
      completed: false,
      totalQuestions: json['session']?['totalQuestions'] ?? 0,
      answeredCount: json['session']?['answeredCount'] ?? 0,
      remainingCount: json['session']?['remainingCount'] ?? 0,
      question: Question(
        id: (json['questionId'] ?? '').toString(),
        categoryId: (json['categoryId'] ?? '').toString(),
        categoryName: json['categoryName'] ?? '',
        categoryPath: '',
        questionText: json['questionText'] ?? '',
        questionType: json['questionType'] ?? 'single_choice',
        options: (json['options'] as List<dynamic>?)
                ?.map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
                .toList() ?? [],
        createdAt: '',
      ),
    );
  }
}
