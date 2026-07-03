import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/auth_tokens.dart';

class ApiService {
  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  SharedPreferences? _prefs;
  String? _accessToken;
  String? _refreshToken;

  bool _isRefreshing = false;
  final List<Completer<void>> _refreshQueue = [];

  VoidCallback? onLogout;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _accessToken = await _secure.read(key: 'access_token');
    _refreshToken = await _secure.read(key: 'refresh_token');
  }

  String? get accessToken => _accessToken;

  Future<void> setTokens(AuthTokens tokens) async {
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    await _secure.write(key: 'access_token', value: tokens.accessToken);
    await _secure.write(key: 'refresh_token', value: tokens.refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _secure.delete(key: 'access_token');
    await _secure.delete(key: 'refresh_token');
    await _prefs?.remove('user_name');
    await _prefs?.remove('user_email');
  }

  Future<bool> hasStoredTokens() async {
    final rt = await _secure.read(key: 'refresh_token');
    return rt != null && rt.isNotEmpty;
  }

  Future<bool> tryAutoRefresh() async {
    if (_refreshToken == null) return false;
    if (_accessToken == null) return false;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refresh}');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accessToken': _accessToken,
          'refreshToken': _refreshToken,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        await _secure.write(key: 'access_token', value: _accessToken);
        await _secure.write(key: 'refresh_token', value: _refreshToken);
        return true;
      }
    } catch (_) {}
    return false;
  }

  void cacheUserInfo(String name, String email, {int tier = 0}) {
    _prefs?.setString('user_name', name);
    _prefs?.setString('user_email', email);
    _prefs?.setInt('user_tier', tier);
  }

  String? get cachedUserName => _prefs?.getString('user_name');
  String? get cachedUserEmail => _prefs?.getString('user_email');
  int get cachedUserTier => _prefs?.getInt('user_tier') ?? 0;

  // ---------------------------------------------------------------- headers

  Map<String, String> _headers({bool auth = false}) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth && _accessToken != null) {
      h['Authorization'] = 'Bearer $_accessToken';
    }
    return h;
  }

  // ---------------------------------------------------------------- refresh

  Future<http.Response> _withRefresh(Future<http.Response> Function() sender) async {
    final first = await sender();
    if (first.statusCode != 401 || _refreshToken == null) return first;

    if (_isRefreshing) {
      final completer = Completer<void>();
      _refreshQueue.add(completer);
      await completer.future;
      return sender();
    }

    _isRefreshing = true;
    try {
      final ok = await _performRefresh();
      if (ok) return sender();
    } finally {
      _isRefreshing = false;
      for (final c in _refreshQueue) {
        c.complete();
      }
      _refreshQueue.clear();
    }

    _handleLogout();
    return first;
  }

  Future<bool> _performRefresh() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refresh}');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accessToken': _accessToken,
          'refreshToken': _refreshToken,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        await _secure.write(key: 'access_token', value: _accessToken);
        await _secure.write(key: 'refresh_token', value: _refreshToken);
        return true;
      }
    } catch (_) {}
    return false;
  }

  void _handleLogout() {
    clearTokens();
    onLogout?.call();
  }

  // ---------------------------------------------------------------- HTTP

  Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    return _withRefresh(() {
      return http.post(uri, headers: _headers(auth: auth), body: jsonEncode(body));
    });
  }

  Future<http.Response> get(
    String path, {
    bool auth = false,
    Map<String, String>? queryParams,
  }) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    return _withRefresh(() {
      return http.get(uri, headers: _headers(auth: auth));
    });
  }

  Future<http.Response> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    return _withRefresh(() {
      return http.put(uri, headers: _headers(auth: auth), body: jsonEncode(body));
    });
  }

  Future<http.Response> delete(
    String path, {
    bool auth = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    return _withRefresh(() {
      return http.delete(uri, headers: _headers(auth: auth));
    });
  }
}
