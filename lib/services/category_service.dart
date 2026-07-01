import 'dart:convert';
import '../config/api_config.dart';
import '../models/category.dart';
import 'api_service.dart';

class CategoryService {
  final ApiService _api;

  CategoryService(this._api);

  Future<List<Category>> getCategories() async {
    final res = await _api.get('/api/categories', queryParams: {'tree': 'true'});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((c) => Category.fromJson(c as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load categories');
  }

  Future<Map<String, Map<String, int>>> getCompletionStatus() async {
    final res = await _api.get(ApiConfig.categoryCompletion, auth: true);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      final map = <String, Map<String, int>>{};
      for (final item in data) {
        final id = (item['categoryId'] ?? '').toString();
        map[id] = {
          'total': item['totalQuestions'] ?? 0,
          'answered': item['answeredQuestions'] ?? 0,
          'completed': (item['completed'] == true) ? 1 : 0,
        };
      }
      return map;
    }
    throw Exception('Failed to load completion status');
  }
}
