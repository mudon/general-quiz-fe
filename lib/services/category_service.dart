import 'dart:convert';
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
}
