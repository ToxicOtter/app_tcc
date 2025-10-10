import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SessionService {
  final String baseUrl;
  SessionService(this.baseUrl);

  static const _kUserIdKey = 'user_id';
  static const _kFcmKey    = 'fcm_token';

  String _platform(){
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return 'android';
      case TargetPlatform.iOS: return 'ios';
      default: return 'other';
    }
  }

  Future<void> saveSession({required int userId, String? fcmToken}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kUserIdKey, userId);
    if(fcmToken != null && fcmToken.isNotEmpty){
      await sp.setString(_kFcmKey,    fcmToken);
    };
  }

  // (opcional) helper explícito
  Future<void> saveUserId(int userId) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kUserIdKey, userId);
  }

  Future<void> clearSession() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kUserIdKey);
    await sp.remove(_kFcmKey);
  }

  Future<int?> currentUserId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kUserIdKey);
  }

  Future<String?> currentFcmToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kFcmKey);
  }

  /// Exemplo de login (ajuste para sua API)
  Future<int?> login({String? username, String? email}) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email}),
    );
    if (resp.statusCode == 200) {
      final js = jsonDecode(resp.body) as Map<String, dynamic>;
      return (js['user']?['id']) as int?;
    }
    return null;
  }

  /// Registra/atualiza o device no backend e persiste sessão
  Future<bool> attachDeviceToUser(int userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return false;

    final r = await http.post(
      Uri.parse('$baseUrl/api/devices/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'fcm_token': token,
        'platform': _platform(),
      }),
    );
    if (r.statusCode == 200) {
      await saveSession(userId: userId, fcmToken: token);
      return true;
    }
    return false;
  }

  Future<bool> logout() async {
    final sp = await SharedPreferences.getInstance();
    final userId = sp.getInt(_kUserIdKey);
    final token  = sp.getString(_kFcmKey);

    if (userId != null && token != null && token.isNotEmpty) {
      // se tiver endpoint de remoção de device, chame aqui
      await http.post(
        Uri.parse('$baseUrl/api/devices/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'fcm_token': token}),
      );
    }

    try { await FirebaseMessaging.instance.deleteToken(); } catch (_) {}
    await clearSession();
    return true;
  }

  Future<void> handleTokenRefresh() async {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final sp = await SharedPreferences.getInstance();
      final userId = sp.getInt(_kUserIdKey);
      final oldToken = sp.getString(_kFcmKey);

      if (userId != null && (oldToken ?? '').isNotEmpty) {
        await http.post(
          Uri.parse('$baseUrl/api/devices/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'old_token': oldToken,
            'new_token': newToken,
            'platform': _platform(),
          }),
        );
        await sp.setString(_kFcmKey, newToken);
      }
    });
  }
}
