import 'dart:convert';
import '../config/api_config.dart';
import '../models/stats.dart';
import 'api_service.dart';

class StatsService {
  final ApiService _api;

  StatsService(this._api);

  Future<UserStats> getStats() async {
    final res = await _api.get(ApiConfig.stats, auth: true);
    if (res.statusCode == 200) {
      return UserStats.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to load stats');
  }

  Future<List<CategoryStat>> getCategoryStats() async {
    final res = await _api.get(ApiConfig.statsCategories, auth: true);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((c) => CategoryStat.fromJson(c as Map<String, dynamic>)).toList();
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to load category stats');
  }
}
