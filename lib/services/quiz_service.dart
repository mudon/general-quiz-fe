import 'dart:convert';
import '../config/api_config.dart';
import '../models/question.dart';
import '../models/quiz_session.dart';
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

  Future<QuizSession> createSession({required String categoryId}) async {
    final res = await _api.post(
      ApiConfig.quizSessions,
      {'categoryId': categoryId},
      auth: true,
    );

    if (res.statusCode == 200) {
      return QuizSession.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to create quiz session');
  }

  Future<List<QuizSession>> getActiveSessions() async {
    final res = await _api.get(ApiConfig.quizSessions, auth: true);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map((s) => QuizSession.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to load sessions');
  }

  Future<NextQuestionResponse> getNextQuestion(String sessionId) async {
    final res = await _api.get(ApiConfig.quizSessionNext(sessionId));
    if (res.statusCode == 200) {
      return NextQuestionResponse.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to get next question');
  }

  Future<void> resetSession(String sessionId) async {
    final res = await _api.put(ApiConfig.quizSessionReset(sessionId), {});
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['error'] ?? 'Failed to reset session');
    }
  }
}
