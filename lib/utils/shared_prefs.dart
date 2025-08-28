import 'package:shared_preferences/shared_preferences.dart';

class SeenStore {
  static const _key = 'seen_movie_ids';

  static Future<Set<String>> getSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.toSet();
  }

  static Future<void> addSeen(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final set = await getSeenIds();
    set.add(id);
    await prefs.setStringList(_key, set.toList());
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
