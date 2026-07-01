import 'dart:convert';
import '../config/api_config.dart';
import '../models/review.dart';
import 'api_service.dart';

class ReviewService {
  final ApiService _api;

  ReviewService(this._api);

  Future<ReviewPage> getDueForReview({String? cursor, int limit = 20}) async {
    final params = <String, String>{
      'limit': limit.toString(),
    };
    if (cursor != null) params['cursor'] = cursor;

    final res = await _api.get(ApiConfig.reviewDue, queryParams: params, auth: true);
    if (res.statusCode == 200) {
      return ReviewPage.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Failed to load review items');
  }
}
