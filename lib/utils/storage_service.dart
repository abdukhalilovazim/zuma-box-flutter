import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyCurrentLevel = "current_level";
  static const String _keyBestScore = "best_score";
  static const String _keyUnlockedLevels = "unlocked_levels";

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

  Future<void> resetProgress() async {
    await _prefs.setInt(_keyCurrentLevel, 1);
    await _prefs.setInt(_keyBestScore, 0);
    await _prefs.setStringList(_keyUnlockedLevels, ["1"]);
  }
}
