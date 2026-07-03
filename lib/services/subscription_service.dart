import 'dart:convert';
import '../config/api_config.dart';
import 'api_service.dart';

class PlanInfo {
  final String plan;
  final String name;
  final int tier;
  final double priceMYR;
  final double priceUSD;
  final int? categoryLimit;

  PlanInfo({
    required this.plan,
    required this.name,
    required this.tier,
    required this.priceMYR,
    required this.priceUSD,
    this.categoryLimit,
  });

  factory PlanInfo.fromJson(Map<String, dynamic> json) {
    return PlanInfo(
      plan: json['plan'] ?? '',
      name: json['name'] ?? '',
      tier: json['tier'] ?? 0,
      priceMYR: (json['priceMYR'] ?? 0).toDouble(),
      priceUSD: (json['priceUSD'] ?? 0).toDouble(),
      categoryLimit: json['categoryLimit'],
    );
  }
}

class SubscriptionService {
  final ApiService _api;

  SubscriptionService(this._api);

  Future<List<PlanInfo>> getPlans() async {
    final res = await _api.get(ApiConfig.subPlans);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((p) => PlanInfo.fromJson(p as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load plans');
  }

  Future<Map<String, dynamic>> checkout(String plan, String currency) async {
    final res = await _api.post(
      ApiConfig.subCheckout,
      {'plan': plan, 'currency': currency},
      auth: true,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Checkout failed');
  }
}
