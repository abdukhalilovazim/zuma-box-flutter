import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyCurrentLevel = "current_level";
  static const String _keyBestScore = "best_score";
  static const String _keyUnlockedLevels = "unlocked_levels";
  static const String _keyCompletedLevels = "completed_levels";
  static const String _keySelectedTheme = "selected_theme";

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  int getCurrentLevel() {
    return _prefs.getInt(_keyCurrentLevel) ?? 1;
  }

  Future<void> setCurrentLevel(int level) async {
    await _prefs.setInt(_keyCurrentLevel, level);
  }

  int getBestScore() {
    return _prefs.getInt(_keyBestScore) ?? 0;
  }

  Future<void> setBestScore(int score) async {
    int currentBest = getBestScore();
    if (score > currentBest) {
      await _prefs.setInt(_keyBestScore, score);
    }
  }

  List<int> getUnlockedLevels() {
    final list = _prefs.getStringList(_keyUnlockedLevels);
    if (list == null) return [1];
    return list.map((e) => int.tryParse(e) ?? 1).toList();
  }

  Future<void> unlockLevel(int level) async {
    final levels = getUnlockedLevels();
    if (!levels.contains(level)) {
      levels.add(level);
      await _prefs.setStringList(
        _keyUnlockedLevels,
        levels.map((e) => e.toString()).toList(),
      );
    }
  }

  List<int> getCompletedLevels() {
    final list = _prefs.getStringList(_keyCompletedLevels);
    if (list == null) return [];
    return list.map((e) => int.tryParse(e) ?? 1).toList();
  }

  static const String _keyLanguage = "selected_language";

  Future<void> completeLevel(int level) async {
    final levels = getCompletedLevels();
    if (!levels.contains(level)) {
      levels.add(level);
      await _prefs.setStringList(
        _keyCompletedLevels,
        levels.map((e) => e.toString()).toList(),
      );
    }
  }

  String getLanguage() {
    return _prefs.getString(_keyLanguage) ?? "uz";
  }

  Future<void> setLanguage(String lang) async {
    await _prefs.setString(_keyLanguage, lang);
  }

  String getTheme() {
    return _prefs.getString(_keySelectedTheme) ?? "tokyo";
  }

  Future<void> setTheme(String theme) async {
    await _prefs.setString(_keySelectedTheme, theme);
  }

  Future<void> resetProgress() async {
    await _prefs.setInt(_keyCurrentLevel, 1);
    await _prefs.setInt(_keyBestScore, 0);
    await _prefs.setStringList(_keyUnlockedLevels, ["1"]);
    await _prefs.setStringList(_keyCompletedLevels, []);
    await _prefs.setString(_keyLanguage, "uz");
    await _prefs.setString(_keySelectedTheme, "tokyo");
  }
}
