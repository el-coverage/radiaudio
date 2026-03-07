import 'package:radio_player_simple/player/model/player_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerPreferencesSnapshot {
  const PlayerPreferencesSnapshot({
    required this.defaultMusicFolderPath,
    required this.defaultPlaybackSpeed,
    required this.chapterUnitSec,
    required this.selectedLanguageCode,
    required this.isPremiumUser,
    required this.preventAutoSleepDuringPlayback,
    required this.adsDisabledUntil,
    required this.adOpportunityCount,
    required this.lastInterstitialAt,
  });

  final String defaultMusicFolderPath;
  final double defaultPlaybackSpeed;
  final double chapterUnitSec;
  final String selectedLanguageCode;
  final bool isPremiumUser;
  final bool preventAutoSleepDuringPlayback;
  final DateTime? adsDisabledUntil;
  final int adOpportunityCount;
  final DateTime? lastInterstitialAt;
}

Future<PlayerPreferencesSnapshot> loadPlayerPreferences({
  required List<String> supportedLanguageCodes,
  required double fallbackDefaultPlaybackSpeed,
  required double fallbackChapterUnitSec,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final loadedLanguageCode =
      prefs.getString(PlayerConstants.prefLanguageCode) ?? 'ja';
  final normalizedLanguageCode = supportedLanguageCodes.contains(loadedLanguageCode)
      ? loadedLanguageCode
      : 'ja';

  final loadedDefaultSpeed =
      prefs.getDouble(PlayerConstants.prefDefaultPlaybackSpeed) ?? fallbackDefaultPlaybackSpeed;
  final normalizedDefaultSpeed = loadedDefaultSpeed.clamp(0.25, 3.0);

  final loadedChapterUnitSec =
      prefs.getDouble(PlayerConstants.prefChapterUnitSec) ?? fallbackChapterUnitSec;
  final normalizedChapterUnitSec = loadedChapterUnitSec.clamp(
    PlayerConstants.minChapterUnitSec,
    PlayerConstants.maxChapterUnitSec,
  );

  final loadedAdsDisabledUntilIso =
      prefs.getString(PlayerConstants.prefAdsDisabledUntilIso);
  final loadedLastInterstitialAtIso =
      prefs.getString(PlayerConstants.prefLastInterstitialAtIso);

  return PlayerPreferencesSnapshot(
    defaultMusicFolderPath:
        prefs.getString(PlayerConstants.prefDefaultMusicFolderPath) ?? '',
    defaultPlaybackSpeed: normalizedDefaultSpeed,
    chapterUnitSec: normalizedChapterUnitSec,
    selectedLanguageCode: normalizedLanguageCode,
    isPremiumUser: prefs.getBool(PlayerConstants.prefIsPremiumUser) ?? false,
    preventAutoSleepDuringPlayback:
        prefs.getBool(PlayerConstants.prefPreventAutoSleepDuringPlayback) ?? false,
    adsDisabledUntil: loadedAdsDisabledUntilIso == null
        ? null
        : DateTime.tryParse(loadedAdsDisabledUntilIso),
    adOpportunityCount: prefs.getInt(PlayerConstants.prefAdOpportunityCount) ?? 0,
    lastInterstitialAt: loadedLastInterstitialAtIso == null
        ? null
        : DateTime.tryParse(loadedLastInterstitialAtIso),
  );
}

Future<void> savePlayerDefaultSettings({
  required String path,
  required double defaultSpeed,
  required double chapterSeconds,
  required String languageCode,
  required bool preventAutoSleepDuringPlayback,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(PlayerConstants.prefDefaultMusicFolderPath, path);
  await prefs.setDouble(PlayerConstants.prefDefaultPlaybackSpeed, defaultSpeed);
  await prefs.setDouble(PlayerConstants.prefChapterUnitSec, chapterSeconds);
  await prefs.setString(PlayerConstants.prefLanguageCode, languageCode);
  await prefs.setBool(
    PlayerConstants.prefPreventAutoSleepDuringPlayback,
    preventAutoSleepDuringPlayback,
  );
}

Future<void> savePlayerLanguagePreference(String languageCode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(PlayerConstants.prefLanguageCode, languageCode);
}

Future<void> saveAdsDisabledUntil(DateTime until) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    PlayerConstants.prefAdsDisabledUntilIso,
    until.toIso8601String(),
  );
}

Future<void> saveAdOpportunityCount(int count) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(PlayerConstants.prefAdOpportunityCount, count);
}

Future<void> saveLastInterstitialAt(DateTime time) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    PlayerConstants.prefLastInterstitialAtIso,
    time.toIso8601String(),
  );
}