typedef OnLanguageChanged = Future<void> Function(String value);
typedef OnPickDefaultFolder = Future<String?> Function(String? currentPath);
typedef OnDefaultFolderChanged = Future<void> Function(String selectedPath);
typedef OnDefaultSpeedChanged = Future<void> Function(double value);
typedef OnChapterUnitChanged = Future<void> Function(double value);
typedef OnChapterUnitChangeEnd = Future<void> Function();
typedef OnPreventAutoSleepChanged = Future<void> Function(bool value);
typedef OnPremiumChanged = Future<void> Function(bool value);
typedef OnRestorePremiumPurchases = Future<void> Function();
typedef OnWatchRewardAd = Future<void> Function();
typedef GetIsPremiumUser = bool Function();
typedef GetAdsDisabledUntil = DateTime? Function();
typedef OnMusicDetectionEnabledChanged = Future<void> Function(bool value);

class PlayerSettingsActions {
  const PlayerSettingsActions({
    required this.onLanguageChanged,
    required this.onPickDefaultFolder,
    required this.onDefaultFolderChanged,
    required this.onDefaultSpeedChanged,
    required this.onChapterUnitChanged,
    required this.onChapterUnitChangeEnd,
    required this.onPreventAutoSleepChanged,
    required this.onPremiumChanged,
    required this.onRestorePremiumPurchases,
    required this.onWatchRewardAd,
    required this.getIsPremiumUser,
    required this.getAdsDisabledUntil,
    required this.onMusicDetectionEnabledChanged,
  });

  final OnLanguageChanged onLanguageChanged;
  final OnPickDefaultFolder onPickDefaultFolder;
  final OnDefaultFolderChanged onDefaultFolderChanged;
  final OnDefaultSpeedChanged onDefaultSpeedChanged;
  final OnChapterUnitChanged onChapterUnitChanged;
  final OnChapterUnitChangeEnd onChapterUnitChangeEnd;
  final OnPreventAutoSleepChanged onPreventAutoSleepChanged;
  final OnPremiumChanged onPremiumChanged;
  final OnRestorePremiumPurchases onRestorePremiumPurchases;
  final OnWatchRewardAd onWatchRewardAd;
  final GetIsPremiumUser getIsPremiumUser;
  final GetAdsDisabledUntil getAdsDisabledUntil;
  final OnMusicDetectionEnabledChanged onMusicDetectionEnabledChanged;
}
