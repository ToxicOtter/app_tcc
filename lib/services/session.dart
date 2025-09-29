import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SessionService {
  final String baseUrl;
  SessionService(this.baseUrl);

  // chaves únicas e consistentes
  static const _kUserId = 'userId';
  static const _kFcmToken = 'fcmToken';

  String _platform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'other';
    }
  }

  // ---------- Persistência local ----------
  Future<void> saveSession({required int userId, required String fcmToken}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kUserId, userId);
    await sp.setString(_kFcmToken, fcmToken);
  }

  Future<void> clearSession() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kUserId);
    await sp.remove(_kFcmToken);
  }

  Future<int?> currentUserId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kUserId);
  }

  Future<String?> currentFcmToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kFcmToken);
  }

  // ---------- Login simples (exemplo) ----------
  /// Ajuste esta rota para a sua API real. Aqui mandei username/email.
  Future<int?> login({String? username, String? email}) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email}), // corrigido
    );
    if (resp.statusCode == 200) {
      final js = jsonDecode(resp.body);
      return js['user']?['id'] as int?;
    }
    return null;
  }

  // ---------- Vincular device ao usuário ----------
  /// Pega o token atual do FCM, envia para o backend e persiste localmente.
  Future<bool> attachDeviceToUser(int userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return false;

    final r = await http.post(
      Uri.parse('$baseUrl/api/devices/register'), // corrigido
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'fcm_token': token,
        'platform': _platform(), // corrigido
      }),
    );

    if (r.statusCode == 200) {
      await saveSession(userId: userId, fcmToken: token);
      return true;
    }
    return false;
  }

  // ---------- Logout ----------
  /// Remove o device no backend e limpa sessão local
  Future<bool> logout() async {
    final sp = await SharedPreferences.getInstance();
    final userId = sp.getInt(_kUserId);
    final token = sp.getString(_kFcmToken);

    if (userId != null && token != null && token.isNotEmpty) {
      await http.post(
        Uri.parse('$baseUrl/api/devices/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'fcm_token': token}),
      );
    }

    // invalida token local do FCM (gera outro no próximo login)
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}

    await clearSession();
    return true;
  }

  // ---------- Refresh do token ----------
  /// Se o FCM rotacionar token, avisa o backend e atualiza localmente
  Future<void> handleTokenRefresh() async {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final sp = await SharedPreferences.getInstance();
      final userId = sp.getInt(_kUserId);
      final oldToken = sp.getString(_kFcmToken);

      if (userId != null && oldToken != null && oldToken.isNotEmpty) {
        await http.post(
          Uri.parse('$baseUrl/api/devices/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'old_token': oldToken,
            'new_token': newToken,
            'platform': _platform(), // corrigido
          }),
        );
        await sp.setString(_kFcmToken, newToken);
      }
    });
  }
}
