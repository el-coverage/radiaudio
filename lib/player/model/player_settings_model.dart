class PlayerSettingsModel {
  const PlayerSettingsModel({
    required this.supportedLanguageCodes,
    required this.languageDisplayNames,
    required this.defaultMusicFolderPath,
    required this.defaultPlaybackSpeed,
    required this.chapterUnitSec,
    required this.minChapterUnitSec,
    required this.maxChapterUnitSec,
    required this.selectedLanguageCode,
    required this.preventAutoSleepDuringPlayback,
    required this.isPremiumUser,
    required this.usesMockPremiumBilling,
    required this.adsDisabledUntil,
    required this.musicDetectionEnabled,
  });

  final List<String> supportedLanguageCodes;
  final Map<String, String> languageDisplayNames;
  final String defaultMusicFolderPath;
  final double defaultPlaybackSpeed;
  final double chapterUnitSec;
  final double minChapterUnitSec;
  final double maxChapterUnitSec;
  final String selectedLanguageCode;
  final bool preventAutoSleepDuringPlayback;
  final bool isPremiumUser;
  final bool usesMockPremiumBilling;
  final DateTime? adsDisabledUntil;
  final bool musicDetectionEnabled;
}
