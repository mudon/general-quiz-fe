import 'question.dart';

class DueReviewItem {
  final String questionId;
  final String questionText;
  final String questionType;
  final String categoryId;
  final String dueAt;
  final int intervalDays;
  final int repetitions;
  final int lapses;
  final List<QuestionOption> options;

  DueReviewItem({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.categoryId,
    required this.dueAt,
    required this.intervalDays,
    required this.repetitions,
    required this.lapses,
    required this.options,
  });

  factory DueReviewItem.fromJson(Map<String, dynamic> json) {
    return DueReviewItem(
      questionId: (json['questionId'] ?? '').toString(),
      questionText: json['questionText'] ?? '',
      questionType: json['questionType'] ?? 'single_choice',
      categoryId: (json['categoryId'] ?? '').toString(),
      dueAt: json['dueAt'] ?? '',
      intervalDays: json['intervalDays'] ?? 0,
      repetitions: json['repetitions'] ?? 0,
      lapses: json['lapses'] ?? 0,
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ReviewPage {
  final List<DueReviewItem> items;
  final String? nextCursor;
  final bool hasMore;

  ReviewPage({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  factory ReviewPage.fromJson(Map<String, dynamic> json) {
    return ReviewPage(
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => DueReviewItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      nextCursor: json['nextCursor']?.toString(),
      hasMore: json['hasMore'] ?? false,
    );
  }
}
