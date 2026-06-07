import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineQueueService {
  static const _key = 'upload_queue';

  Future<void> enqueue(Map<String, dynamic> payload) async {
    final pref = await SharedPreferences.getInstance();
    final queue = pref.getStringList(_key) ?? [];
    queue.add(jsonEncode(payload));
    await pref.setStringList(_key, queue);
  }

  Future<List<Map<String, dynamic>>> pending() async {
    final pref = await SharedPreferences.getInstance();
    final queue = pref.getStringList(_key) ?? [];
    return queue.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<void> clear() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_key);
  }

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}