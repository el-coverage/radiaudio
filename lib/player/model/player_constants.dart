class PlayerConstants {
  static const String prefDefaultMusicFolderPath = 'default_music_folder_path';
  static const String prefDefaultPlaybackSpeed = 'default_playback_speed';
  static const String prefChapterUnitSec = 'chapter_unit_sec';
  static const String prefSkipTargetPrefix = 'skip_targets_v1::';
  static const String prefLanguageCode = 'language_code';
  static const String prefIsPremiumUser = 'is_premium_user';
  static const String prefAdsDisabledUntilIso = 'ads_disabled_until_iso';
  static const String prefAdOpportunityCount = 'ad_opportunity_count';
  static const String prefLastInterstitialAtIso = 'last_interstitial_at_iso';
  static const String prefPreventAutoSleepDuringPlayback =
      'prevent_auto_sleep_during_playback';

  static const double minChapterUnitSec = 0.1;
  static const double maxChapterUnitSec = 2.0;
  static const double silenceNoiseDb = -70.0;
  static const double fixedMinSegmentSecForSilenceSplit = 8.0;
  static const double fixedMaxSegmentSecWithoutSplit = 24.0;
  static const double hardMinChapterSec = 8.0;
  static const double silenceDetectWindowSec = 0.01;
  static const double musicWindowSec = 8.0;
  static const double musicHopSec = 4.0;
  static const double musicMinIntervalSec = 12.0;

  static const int minVolumeLevel = 0;
  static const int maxVolumeLevel = 20;
  static const int interstitialEveryOpportunities = 6;

  static const Duration interstitialCooldown = Duration(minutes: 15);
  static const Duration chapterSkipAdOpportunityMinInterval = Duration(
    minutes: 2,
  );
  static const Duration chapterDoubleTapWindow = Duration(milliseconds: 350);

  static const Set<String> audioExtensions = {
    'mp3',
    'wav',
    'm4a',
    'aac',
    'flac',
    'ogg',
    'opus',
  };
}
