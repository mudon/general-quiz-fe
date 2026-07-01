import 'dart:convert';
import 'dart:math';
import '../config/api_config.dart';
import '../models/question.dart';
import 'api_service.dart';

class QuizService {
  final ApiService _api;

  QuizService(this._api);

  Future<QuestionsPage> getQuestionsByCategory({
    required String categoryId,
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'categoryId': categoryId,
      'limit': limit.toString(),
    };
    if (cursor != null) params['cursor'] = cursor;

    final res = await _api.get(ApiConfig.questions, queryParams: params);
    if (res.statusCode == 200) {
      return QuestionsPage.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to load questions');
  }

  Future<Question?> getRandomQuestion({required String categoryId}) async {
    var allQuestions = <Question>[];
    String? cursor;

    do {
      final page = await getQuestionsByCategory(
        categoryId: categoryId,
        cursor: cursor,
        limit: 50,
      );
      allQuestions.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);

    if (allQuestions.isEmpty) return null;

    final rng = Random();
    return allQuestions[rng.nextInt(allQuestions.length)];
  }

  Future<Question?> getQuestionById(String id) async {
    final res = await _api.get(ApiConfig.questionById(id));
    if (res.statusCode == 200) {
      return Question.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to load question');
  }

  Future<AnswerResult> submitAnswer({
    required String questionId,
    required String questionType,
    String? submittedSingleChoice,
    List<String>? submittedMultipleChoice,
    String? submittedFillIn,
  }) async {
    final body = <String, dynamic>{};
    if (questionType == 'single_choice') {
      body['submittedSingleChoice'] = submittedSingleChoice;
    } else if (questionType == 'multiple_choice') {
      body['submittedMultipleChoice'] = submittedMultipleChoice;
    } else if (questionType == 'fill_in_blank') {
      body['submittedFillIn'] = submittedFillIn;
    }

    final res = await _api.post(
      ApiConfig.answerQuestion(questionId),
      body,
      auth: true,
    );

    if (res.statusCode == 200) {
      return AnswerResult.fromJson(jsonDecode(res.body));
    }

    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to submit answer');
  }
}
