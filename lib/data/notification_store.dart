import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_notification.dart';

class NotificationStore {
  static const _key = 'notif_history_v1';

  static Future<List<AppNotification>> getAll() async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_key) ?? <String>[];
    return list
        .map((s) => AppNotification.fromMap(jsonDecode(s)))
        .toList()
      ..sort((a,b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> add(AppNotification n) async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_key) ?? <String>[];
    list.add (jsonEncode(n.toMap()));
    const maxItens = 200;
    final trimmed = list.length > maxItens ? list.sublist(list.length - maxItens) : list;
    await sp.setStringList(_key, trimmed);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }
}