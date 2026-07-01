class QuestionOption {
  final String id;
  final String text;
  final int sortOrder;

  QuestionOption({required this.id, required this.text, required this.sortOrder});

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: (json['id'] ?? '').toString(),
      text: json['text'] ?? '',
      sortOrder: (json['sort_order'] ?? json['sortOrder'] ?? 0) is int
          ? json['sort_order'] ?? json['sortOrder'] ?? 0
          : 0,
    );
  }
}

class Question {
  final String id;
  final String categoryId;
  final String categoryName;
  final String categoryPath;
  final String questionText;
  final String questionType; // single_choice, multiple_choice, fill_in_blank
  final String? explanation;
  final List<QuestionOption> options;
  final String createdAt;

  Question({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryPath,
    required this.questionText,
    required this.questionType,
    this.explanation,
    required this.options,
    required this.createdAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: (json['id'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? '').toString(),
      categoryName: json['categoryName'] ?? '',
      categoryPath: json['categoryPath'] ?? '',
      questionText: json['questionText'] ?? '',
      questionType: json['questionType'] ?? 'single_choice',
      explanation: json['explanation'],
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }

  bool get isSingleChoice => questionType == 'single_choice';
  bool get isMultipleChoice => questionType == 'multiple_choice';
  bool get isFillInBlank => questionType == 'fill_in_blank';
}

class CorrectAnswer {
  final String? singleChoiceAnswer;
  final List<String>? multipleChoiceAnswer;
  final String? fillInAnswer;
  final List<String>? fillInAlternatives;

  CorrectAnswer({
    this.singleChoiceAnswer,
    this.multipleChoiceAnswer,
    this.fillInAnswer,
    this.fillInAlternatives,
  });

  factory CorrectAnswer.fromJson(Map<String, dynamic> json) {
    return CorrectAnswer(
      singleChoiceAnswer: json['singleChoiceAnswer']?.toString(),
      multipleChoiceAnswer: json['multipleChoiceAnswer'] != null
          ? (json['multipleChoiceAnswer'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
      fillInAnswer: json['fillInAnswer']?.toString(),
      fillInAlternatives: json['fillInAlternatives'] != null
          ? (json['fillInAlternatives'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
    );
  }
}

class AnswerResult {
  final String id;
  final bool isCorrect;
  final List<String> newBadges;
  final String questionText;
  final String questionType;
  final String? explanation;
  final CorrectAnswer correctAnswer;
  final List<QuestionOption> options;

  AnswerResult({
    required this.id,
    required this.isCorrect,
    required this.newBadges,
    required this.questionText,
    required this.questionType,
    this.explanation,
    required this.correctAnswer,
    required this.options,
  });

  factory AnswerResult.fromJson(Map<String, dynamic> json) {
    return AnswerResult(
      id: (json['id'] ?? '').toString(),
      isCorrect: json['isCorrect'] ?? false,
      newBadges: json['newBadges'] != null
          ? List<String>.from(json['newBadges'])
          : [],
      questionText: json['questionText'] ?? '',
      questionType: json['questionType'] ?? 'single_choice',
      explanation: json['explanation'],
      correctAnswer: CorrectAnswer.fromJson(
          json['correctAnswer'] is Map ? json['correctAnswer'] : {}),
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class QuestionsPage {
  final List<Question> items;
  final String? nextCursor;
  final bool hasMore;

  QuestionsPage({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  factory QuestionsPage.fromJson(Map<String, dynamic> json) {
    return QuestionsPage(
      items: (json['items'] as List<dynamic>?)
              ?.map((q) => Question.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      nextCursor: json['nextCursor']?.toString(),
      hasMore: json['hasMore'] ?? false,
    );
  }
}
