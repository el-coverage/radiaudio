import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:radio_player_simple/localization/app_localization.dart';
import 'package:radio_player_simple/player/controller/audio_analysis_controller.dart';
import 'package:radio_player_simple/player/controller/audio_file_picker.dart';
import 'package:radio_player_simple/player/controller/chapter_skip_storage.dart';
import 'package:radio_player_simple/player/controller/player_preferences_storage.dart';
import 'package:radio_player_simple/player/controller/premium_billing_gateway.dart';
import 'package:radio_player_simple/player/controller/silence_detect_runner.dart';
import 'package:radio_player_simple/player/model/ad_opportunity_logic.dart';
import 'package:radio_player_simple/player/model/chapter_logic.dart';
import 'package:radio_player_simple/player/model/chapter_seek_logic.dart';
import 'package:radio_player_simple/player/model/music_interval.dart';
import 'package:radio_player_simple/player/model/seek_timeline_logic.dart';
import 'package:radio_player_simple/player/model/silence_split_collector.dart';
import 'package:radio_player_simple/player/model/player_settings_actions.dart';
import 'package:radio_player_simple/player/model/playback_value_utils.dart';
import 'package:radio_player_simple/player/model/playlist_navigation.dart';
import 'package:radio_player_simple/player/model/player_constants.dart';
import 'package:radio_player_simple/player/model/player_settings_model.dart';
import 'package:radio_player_simple/player/utils/path_utils.dart';
import 'package:radio_player_simple/player/utils/seek_position_utils.dart';
import 'package:radio_player_simple/player/utils/time_format_utils.dart';
import 'package:radio_player_simple/player/view/widgets/interstitial_ad_dialog.dart';
import 'package:radio_player_simple/player/view/widgets/player_main_body.dart';
import 'package:radio_player_simple/player/view/widgets/player_settings_dialog.dart';
import 'package:radio_player_simple/player/view/widgets/quick_snack.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  if (Platform.isAndroid || Platform.isIOS) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.radiaudio.playback',
      androidNotificationChannelName: 'Radiaudio Playback',
      androidNotificationOngoing: true,
    );
  }
  runApp(const RadioMockApp());
}

class RadioMockApp extends StatelessWidget {
  const RadioMockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PlayerScreen(),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
      Future<void> _onMusicDetectionEnabledChanged(bool value) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('musicDetectionEnabled', value);
        if (!mounted) return;
        setState(() {
          _musicDetectionEnabled = value;
        });
      }
    bool _musicDetectionEnabled = false;
  String currentTitle = '';

  int currentIndex = 0;
  int totalCount = 0;
  String? currentFilePath;
  List<String> folderAudioFiles = [];

  double currentPositionSec = 0;
  double totalDurationSec = 0;
  bool isDraggingSeekBar = false;
  double draggingSeekSec = 0;

  bool isPlaying = false;
  double defaultPlaybackSpeed = 1.0;
  double playbackSpeed = 1.0;
  int volumeLevel = 10;
  String defaultMusicFolderPath = "";
  double chapterUnitSec = 0.8;
  final ValueNotifier<String> _statusMessage = ValueNotifier<String>("");
  int _actionMessageSerial = 0;
  final AudioPlayer _player = AudioPlayer();
  List<double> _silenceTriggersSec = [];
  List<MusicInterval> _musicIntervals = [];
  Set<int> _skipTargetChapters = <int>{};
  bool _isAutoSkippingChapter = false;
  bool _isAnalyzingSilence = false;
  bool _notifiedSilenceAnalyzerUnsupported = false;
  bool _notifiedDefaultFolderUnsupported = false;
  bool _isPreparingWindowsAnalyzer = false;
  String? _silenceAnalysisPath;
  bool _isAnalyzingWaveform = false;
  bool _isAnalyzingMusicSegments = false;
  String? _waveformAnalysisPath;
  List<double> _waveformLevels = [];
  final Map<String, List<double>> _waveformCache = {};
  DateTime? _lastPreviousChapterTapAt;
  String selectedLanguageCode = 'ja';
  bool _isPremiumUser = false;
  bool _preventAutoSleepDuringPlayback = false;
  DateTime? _adsDisabledUntil;
  int _adOpportunityCount = 0;
  DateTime? _lastInterstitialAt;
  DateTime? _lastChapterSkipAdOpportunityAt;
  late final PremiumBillingGateway _premiumBilling =
      _createPremiumBillingGateway();
  VoidCallback? _premiumStateListener;

  bool get _isAdFree {
    if (_isPremiumUser) return true;
    final until = _adsDisabledUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  /// 選択中言語の文字列を返す。未定義の言語は英語へフォールバックする。
  String _tr(String key, [Map<String, String> params = const {}]) {
    return tr(selectedLanguageCode, key, params);
  }

  bool get _usesMockPremiumBilling =>
      _premiumBilling is MockPremiumBillingGateway;

  PremiumBillingGateway _createPremiumBillingGateway() {
    // TODO: Store product is ready, replace with App Store / Play billing gateway.
    return MockPremiumBillingGateway(prefKey: PlayerConstants.prefIsPremiumUser);
  }

  Future<void> _initializePremiumBilling() async {
    await _premiumBilling.initialize();
    _premiumStateListener = () {
      if (!mounted) return;
      final premium = _premiumBilling.isPremiumListenable.value;
      setState(() {
        _isPremiumUser = premium;
        if (premium) {
          _adsDisabledUntil = null;
        }
      });
    };
    _premiumBilling.isPremiumListenable.addListener(_premiumStateListener!);
    _premiumStateListener!();
  }

  Future<void> _togglePremiumForCurrentSetup(bool premium) async {
    if (_usesMockPremiumBilling) {
      await _premiumBilling.debugSetPremium(premium);
    } else if (premium) {
      await _premiumBilling.purchasePremium();
    }
    if (!mounted) return;
    showQuickSnack(_tr(premium ? 'premiumEnabled' : 'premiumDisabled'),
        milliseconds: 1200);
  }

  Future<void> _restorePremiumPurchases() async {
    await _premiumBilling.restorePurchases();
    if (!mounted) return;
    final premium = _premiumBilling.isPremiumListenable.value;
    showQuickSnack(_tr(premium ? 'premiumEnabled' : 'premiumDisabled'),
        milliseconds: 1200);
  }

  /// 無音自動チャプター解析が利用可能なプラットフォームかを返す。
  bool get _supportsSilenceAnalysis =>
      Platform.isAndroid || Platform.isIOS || Platform.isWindows;

  /// デフォルトフォルダ選択UIが利用可能かを返す。
  bool get _supportsDefaultFolderSelection => !Platform.isIOS;

  /// 現在の実行プラットフォーム名をUI表示用に返す。
  String get _platformLabel {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'この環境';
  }

  /// 音量レベル（0-20）を just_audio の 0.0-1.0 へ変換して適用する。
  Future<void> _applyPlayerVolume() async {
    final normalized =
      (volumeLevel / PlayerConstants.maxVolumeLevel).clamp(0.0, 1.0);
    await _player.setVolume(normalized);
  }

  /// 音量を1段階上げる。
  Future<void> increaseVolume() async {
    final nextLevel = increaseVolumeLevel(
      volumeLevel,
      min: PlayerConstants.minVolumeLevel,
      max: PlayerConstants.maxVolumeLevel,
    );
    if (nextLevel == volumeLevel) return;
    setState(() {
      volumeLevel = nextLevel;
    });
    await _applyPlayerVolume();
    showQuickSnack(_tr('volumeWithValue', {'value': '$volumeLevel'}));
  }

  /// 音量を1段階下げる。
  Future<void> decreaseVolume() async {
    final nextLevel = decreaseVolumeLevel(
      volumeLevel,
      min: PlayerConstants.minVolumeLevel,
      max: PlayerConstants.maxVolumeLevel,
    );
    if (nextLevel == volumeLevel) return;
    setState(() {
      volumeLevel = nextLevel;
    });
    await _applyPlayerVolume();
    showQuickSnack(_tr('volumeWithValue', {'value': '$volumeLevel'}));
  }

  /// 設定値と再生状態に応じて、自動スリープ防止を適用する。
  Future<void> _syncAutoSleepPrevention() async {
    final supportedMobile = Platform.isAndroid || Platform.isIOS;
    final shouldEnable =
        supportedMobile && _preventAutoSleepDuringPlayback && isPlaying;
    try {
      await WakelockPlus.toggle(enable: shouldEnable);
    } catch (_) {
      // Wakelock channel can be temporarily unavailable during app bootstrap.
      // Ignore this and keep playback/analysis flow alive.
    }
  }

  Future<void> _loadSkipTargetsForCurrentTrack() async {
    final filePath = currentFilePath;
    if (filePath == null) {
      if (!mounted) return;
      setState(() {
        _skipTargetChapters = <int>{};
      });
      return;
    }

    final loaded = await loadSkipTargetChaptersForTrack(
      filePath: filePath,
      chapterUnitSec: chapterUnitSec,
      maxChapterIndex: chapterCountFromTriggers(_silenceTriggersSec) - 1,
    );

    if (!mounted) return;
    setState(() {
      _skipTargetChapters = loaded;
    });
  }

  Future<void> _saveSkipTargetsForCurrentTrack() async {
    final filePath = currentFilePath;
    if (filePath == null) return;
    await saveSkipTargetChaptersForTrack(
      filePath: filePath,
      chapterUnitSec: chapterUnitSec,
      skipTargetChapters: _skipTargetChapters,
    );
  }

  Future<void> _toggleSkipTargetAtLocalPositionPremium({
    required Offset localPosition,
    required Size size,
    required int rows,
    required double durationSec,
  }) async {
    if (!_isPremiumUser) {
      showQuickSnack(_tr('premiumOnlySkipTarget'), milliseconds: 1800);
      return;
    }
    if (currentFilePath == null) {
      showQuickSnack(_tr('pleaseOpenAudioFirst'), milliseconds: 1000);
      return;
    }
    if (_isAnalyzingSilence) {
      showQuickSnack(_tr('silenceAnalyzing'), milliseconds: 800);
      return;
    }

    final targetSec = seekSecFromLocalPosition(
      localPosition: localPosition,
      size: size,
      rows: rows,
      durationSec: durationSec,
    );
    final chapterIndex = chapterIndexForSec(
      silenceTriggersSec: _silenceTriggersSec,
      sec: targetSec,
    );
    final chapterCount = chapterCountFromTriggers(_silenceTriggersSec);
    if (chapterIndex < 0 || chapterIndex >= chapterCount) return;

    if (!mounted) return;
    setState(() {
      if (_skipTargetChapters.contains(chapterIndex)) {
        _skipTargetChapters.remove(chapterIndex);
      } else {
        _skipTargetChapters.add(chapterIndex);
      }
    });
    await _saveSkipTargetsForCurrentTrack();

    final isEnabled = _skipTargetChapters.contains(chapterIndex);
    showQuickSnack(
      _tr(
        isEnabled ? 'chapterSkipOn' : 'chapterSkipOff',
        {'chapter': '${chapterIndex + 1}'},
      ),
      milliseconds: 700,
    );
  }

  Future<void> _autoSkipIfCurrentChapterIsTarget(double positionSec) async {
    if (!_isPremiumUser) return;
    if (_isAutoSkippingChapter) return;
    if (!_player.playing) return;
    if (_skipTargetChapters.isEmpty) return;

    final chapterCount = chapterCountFromTriggers(_silenceTriggersSec);
    final currentChapter = chapterIndexForSec(
      silenceTriggersSec: _silenceTriggersSec,
      sec: positionSec,
    );
    if (!_skipTargetChapters.contains(currentChapter)) return;

    var targetChapter = currentChapter + 1;
    while (targetChapter < chapterCount &&
        _skipTargetChapters.contains(targetChapter)) {
      targetChapter++;
    }
    if (targetChapter >= chapterCount) {
      return;
    }

    final targetSec = chapterStartSec(
      silenceTriggersSec: _silenceTriggersSec,
      chapterIndex: targetChapter,
      fallbackTotalDurationSec: totalDurationSec,
    );
    _isAutoSkippingChapter = true;
    try {
      await _player.seek(Duration(milliseconds: (targetSec * 1000).toInt()));
      if (!mounted) return;
      setState(() {
        currentPositionSec = targetSec;
      });
    } finally {
      _isAutoSkippingChapter = false;
    }
  }

  @override

  /// ストリーム購読を初期化し、再生位置・再生状態をUIへ反映する。
  void initState() {
    super.initState();
    unawaited(_initializePremiumBilling());
    loadPreferences();
    _player.positionStream.listen((position) {
      if (!mounted) return;
      if (isDraggingSeekBar) return;
      final positionSec = position.inMilliseconds / 1000;
      setState(() {
        currentPositionSec = positionSec;
      });
      unawaited(_autoSkipIfCurrentChapterIsTarget(positionSec));
    });
    _player.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() {
        totalDurationSec = (duration?.inMilliseconds ?? 0) / 1000;
      });
    });
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final playing = state.playing;
      if (isPlaying == playing) return;
      setState(() {
        isPlaying = playing;
      });
      unawaited(_syncAutoSleepPrevention());
    });
  }

  /// 保存済み設定（デフォルトフォルダ、チャプター単位秒数）を読み込む。
  Future<void> loadPreferences() async {
    final snapshot = await loadPlayerPreferences(
      supportedLanguageCodes: supportedLanguageCodes,
      fallbackDefaultPlaybackSpeed: defaultPlaybackSpeed,
      fallbackChapterUnitSec: chapterUnitSec,
    );
    final prefs = await SharedPreferences.getInstance();
    final musicDetectionEnabled = prefs.getBool('musicDetectionEnabled') ?? false;
    if (!mounted) return;
    setState(() {
      defaultMusicFolderPath = snapshot.defaultMusicFolderPath;
      defaultPlaybackSpeed = snapshot.defaultPlaybackSpeed;
      playbackSpeed = snapshot.defaultPlaybackSpeed;
      chapterUnitSec = snapshot.chapterUnitSec;
      selectedLanguageCode = snapshot.selectedLanguageCode;
      _isPremiumUser = snapshot.isPremiumUser;
      _preventAutoSleepDuringPlayback =
          snapshot.preventAutoSleepDuringPlayback;
      _musicDetectionEnabled = musicDetectionEnabled;
    });
    await _player.setSpeed(snapshot.defaultPlaybackSpeed);
    await _applyPlayerVolume();
    await _syncAutoSleepPrevention();
  }

  Future<void> _persistCurrentDefaultSettings({
    String? path,
    double? defaultSpeed,
    double? chapterSeconds,
    String? languageCode,
    bool? preventAutoSleepDuringPlayback,
    bool? musicDetectionEnabled,
  }) async {
    await savePlayerDefaultSettings(
      path: path ?? defaultMusicFolderPath,
      defaultSpeed: defaultSpeed ?? defaultPlaybackSpeed,
      chapterSeconds: chapterSeconds ?? chapterUnitSec,
      languageCode: languageCode ?? selectedLanguageCode,
      preventAutoSleepDuringPlayback:
          preventAutoSleepDuringPlayback ?? _preventAutoSleepDuringPlayback,
    );
    final prefs = await SharedPreferences.getInstance();
    if (musicDetectionEnabled != null) {
      await prefs.setBool('musicDetectionEnabled', musicDetectionEnabled);
    }
  }

  Future<void> _grantRewardAdFree(Duration duration) async {
    final now = DateTime.now();
    final until = now.add(duration);
    if (!mounted) return;
    setState(() {
      _adsDisabledUntil = until;
    });
    await saveAdsDisabledUntil(until);
    showQuickSnack(_tr('rewardUnlocked24h'), milliseconds: 1200);
  }

  Future<void> _registerAdOpportunity({
    required String source,
    bool allowWhilePlaying = false,
  }) async {
    if (_isAdFree) return;
    if (isPlaying && !allowWhilePlaying) return;

    final now = DateTime.now();
    final adDecision = evaluateInterstitialAdOpportunity(
      currentOpportunityCount: _adOpportunityCount,
      now: now,
      lastInterstitialAt: _lastInterstitialAt,
      everyOpportunities: PlayerConstants.interstitialEveryOpportunities,
      cooldown: PlayerConstants.interstitialCooldown,
    );
    _adOpportunityCount = adDecision.updatedOpportunityCount;
    await saveAdOpportunityCount(_adOpportunityCount);

    if (!adDecision.shouldShowInterstitial) {
      return;
    }

    _lastInterstitialAt = now;
    await saveLastInterstitialAt(now);
    if (!mounted) return;

    await showInterstitialAdDialog(
      context: context,
      source: source,
      tr: _tr,
    );
  }

  /// 次チャプタースキップ由来の広告機会を、一定間隔でのみ登録する。
  Future<void> _registerChapterSkipAdOpportunity() async {
    final now = DateTime.now();
    final last = _lastChapterSkipAdOpportunityAt;
    if (last != null &&
        now.difference(last) <
          PlayerConstants.chapterSkipAdOpportunityMinInterval) {
      return;
    }
    _lastChapterSkipAdOpportunityAt = now;
    await _registerAdOpportunity(
      source: 'skip_chapter',
      allowWhilePlaying: true,
    );
  }

  /// 画面下部に短時間メッセージを表示する。
  void showQuickSnack(String text, {int milliseconds = 300}) {
    _statusMessage.value = text;
    final serial = ++_actionMessageSerial;
    showQuickSnackMessage(
      context: context,
      text: text,
      milliseconds: milliseconds,
      onClosed: () {
        if (!mounted) return;
        if (_actionMessageSerial != serial) return;
        _statusMessage.value = "";
      },
    );
  }

  /// 再生速度を0.25刻みで加算し、最大値超過時は循環させる。
  void increaseSpeed() {
    _updatePlaybackSpeedAndNotify(increasePlaybackSpeedCycle(playbackSpeed));
  }

  /// 前チャプターボタン押下を処理し、短時間の連続押下なら2チャプター戻す。
  void handlePreviousChapterTap() {
    final now = DateTime.now();
    final isDoubleTap = _lastPreviousChapterTapAt != null &&
        now.difference(_lastPreviousChapterTapAt!) <=
          PlayerConstants.chapterDoubleTapWindow;
    _lastPreviousChapterTapAt = now;
    unawaited(skipChapter(false, backwardSteps: isDoubleTap ? 2 : 1));
  }

  /// チャプターを前後に移動する（前方向のみ `backwardSteps` を利用）。
  Future<void> skipChapter(bool forward, {int backwardSteps = 1}) async {
    if (currentFilePath == null) {
      showQuickSnack(_tr('pleaseOpenAudioFirst'), milliseconds: 1000);
      return;
    }
    if (_silenceTriggersSec.isEmpty) {
      showQuickSnack(_tr('silenceChapterNotDetected'), milliseconds: 1000);
      return;
    }

    final resolution = resolveChapterSeekTarget(
      forward: forward,
      silenceTriggersSec: _silenceTriggersSec,
      currentSec: seekBarValue,
      backwardSteps: backwardSteps,
    );
    final resolvedTargetSec = resolution.targetSec;
    if (resolvedTargetSec == null) {
      final key = resolution.failureLocalizationKey;
      if (key != null) {
        showQuickSnack(_tr(key));
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      currentPositionSec = resolvedTargetSec;
    });
    await _player.seek(
      Duration(milliseconds: (resolvedTargetSec * 1000).toInt()),
    );
    if (forward) {
      unawaited(_registerChapterSkipAdOpportunity());
    }
    final chapterMessage = forward
        ? _tr('nextChapter')
        : (backwardSteps >= 2 ? _tr('prevPrevChapter') : _tr('prevChapter'));
    showQuickSnack(chapterMessage);
  }

  /// 曲を前後に移動する（長押し操作用）。
  Future<void> skipTrack(bool forward) async {
    final decision = decideTrackSkip(
      forward: forward,
      folderAudioFiles: folderAudioFiles,
      currentFilePath: currentFilePath,
      currentIndex: currentIndex,
      totalCount: totalCount,
    );
    _applyTrackSkipDecision(decision);
    if (decision.moved) {
      await loadCurrentFile(resetPlayState: true, autoPlay: true);
      unawaited(_registerAdOpportunity(source: 'skip_track'));
    }
    showQuickSnack(_tr(trackSkipMessageLocalizationKey(decision.message)));
  }

  /// 再生速度を0.25刻みで減算し、最小値未満時は循環させる。
  void decreaseSpeed() {
    _updatePlaybackSpeedAndNotify(decreasePlaybackSpeedCycle(playbackSpeed));
  }

  void _updatePlaybackSpeedAndNotify(double nextSpeed) {
    setState(() {
      playbackSpeed = nextSpeed;
    });
    _player.setSpeed(playbackSpeed);
    showQuickSnack('${playbackSpeed.toStringAsFixed(2)}x');
  }

  /// 再生を停止し、再生位置を先頭へ戻す。
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      if (!mounted) return;
      setState(() {
        isPlaying = false;
        currentPositionSec = 0;
      });
      showQuickSnack(_tr('stop'), milliseconds: 700);
    } catch (_) {
      showQuickSnack(_tr('stopFailed'), milliseconds: 1000);
    }
  }

  @override

  /// 保持しているリソースを解放する。
  void dispose() {
    if (_premiumStateListener != null) {
      _premiumBilling.isPremiumListenable
          .removeListener(_premiumStateListener!);
    }
    unawaited(_premiumBilling.dispose());
    unawaited(WakelockPlus.disable());
    _statusMessage.dispose();
    _player.dispose();
    super.dispose();
  }

  /// 読み込みファイルを対象に無音区間を解析し、自動チャプター用トリガーを作成する。
  Future<void> _analyzeSilenceForAutoChapter(String audioPath) async {
    if (!_supportsSilenceAnalysis) {
      if (!_notifiedSilenceAnalyzerUnsupported) {
        _notifiedSilenceAnalyzerUnsupported = true;
        showQuickSnack(
          _tr('analysisUnsupported', {'platform': _platformLabel}),
          milliseconds: 1400,
        );
      }
      if (!mounted) return;
      setState(() {
        _isAnalyzingSilence = false;
        _silenceAnalysisPath = audioPath;
        _silenceTriggersSec = [];
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isAnalyzingSilence = true;
      _silenceAnalysisPath = audioPath;
      _silenceTriggersSec = [];
    });
    final isWindows = Platform.isWindows;

    final splitCollector = SilenceSplitCollector(
      chapterUnitSec: chapterUnitSec,
      hardMinChapterSec: PlayerConstants.hardMinChapterSec,
      fixedMinSegmentSecForSilenceSplit:
          PlayerConstants.fixedMinSegmentSecForSilenceSplit,
      fixedMaxSegmentSecWithoutSplit:
          PlayerConstants.fixedMaxSegmentSecWithoutSplit,
    );

    void processSilenceLogLine(String line) {
      final changed = splitCollector.processLogLine(line);
      if (!changed) return;

      if (!_isSilenceAnalysisTargetCurrent(audioPath)) return;
      setState(() {
        _silenceTriggersSec = List<double>.from(splitCollector.splitTriggers);
      });
    }

    try {
      if (isWindows) {
        if (!mounted) return;
        setState(() {
          _isPreparingWindowsAnalyzer = true;
        });
      }

      final result = await runSilenceDetectAndFeedLines(
        audioPath: audioPath,
        silenceNoiseDb: PlayerConstants.silenceNoiseDb,
        silenceDetectWindowSec: PlayerConstants.silenceDetectWindowSec,
        onLogLine: processSilenceLogLine,
      );
      if (!result.ffmpegKitSucceededOrCanceled &&
          splitCollector.splitTriggers.isEmpty) {
        if (!mounted) return;
        if (isWindows && !_notifiedSilenceAnalyzerUnsupported) {
          _notifiedSilenceAnalyzerUnsupported = true;
          showQuickSnack(_tr('analysisInitFailed'), milliseconds: 1400);
        }
        setState(() {
          _isPreparingWindowsAnalyzer = false;
          _isAnalyzingSilence = false;
        });
        return;
      }
    } catch (_) {
      if (!mounted) return;
      if (!_notifiedSilenceAnalyzerUnsupported) {
        _notifiedSilenceAnalyzerUnsupported = true;
        showQuickSnack(_tr('analysisInitFailed'), milliseconds: 1400);
      }
      setState(() {
        _isPreparingWindowsAnalyzer = false;
        _isAnalyzingSilence = false;
      });
      return;
    }

    if (!_isSilenceAnalysisTargetCurrent(audioPath)) return;
    setState(() {
      _isPreparingWindowsAnalyzer = false;
      _isAnalyzingSilence = false;
      _silenceTriggersSec = List<double>.from(splitCollector.splitTriggers);
    });
    unawaited(_loadSkipTargetsForCurrentTrack());
    unawaited(
      _analyzeMusicSegmentsForSeekbar(
        audioPath: audioPath,
      ),
    );
  }

  /// 読み込みファイルを対象に波形振幅を解析し、シークバー高さ用のデータを生成する。
  Future<void> _analyzeWaveformForSeekbar(String audioPath) async {
    final cached = _waveformCache[audioPath];
    if (cached != null && cached.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _waveformAnalysisPath = audioPath;
        _waveformLevels = cached;
        _isAnalyzingWaveform = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _waveformAnalysisPath = audioPath;
      _waveformLevels = [];
      _isAnalyzingWaveform = true;
    });

    try {
      final waveform = await analyzeWaveformLevels(audioPath: audioPath);
      if (waveform == null || waveform.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isAnalyzingWaveform = false;
          // _waveformLevelsは維持（消さない）
        });
        return;
      }

      if (!_isWaveformAnalysisTargetCurrent(audioPath)) return;
      setState(() {
        _waveformLevels = waveform;
        _isAnalyzingWaveform = false;
      });
      print('[waveform] levels length: \'${_waveformLevels.length}\', first5: \'${_waveformLevels.take(5).toList()}\');');
      _waveformCache[audioPath] = waveform;
    } catch (_) {
      if (!_isWaveformAnalysisTargetCurrent(audioPath)) return;
      setState(() {
        _isAnalyzingWaveform = false;
        // _waveformLevelsは維持（消さない）
      });
    }
  }

  /// 無音で分割した各区間を解析し、音楽らしい区間を抽出する。
  Future<void> _analyzeMusicSegmentsForSeekbar({
    required String audioPath,
  }) async {
    if (!mounted) return;
    setState(() {
      _isAnalyzingMusicSegments = true;
    });

    final musicIntervals = await analyzeMusicIntervals(
      audioPath: audioPath,
      totalDurationSec: totalDurationSec,
    );
    if (musicIntervals == null) {
      if (!_isSilenceAnalysisTargetCurrent(audioPath)) return;
      setState(() {
        _isAnalyzingMusicSegments = false;
      });
      return;
    }
    if (!_isSilenceAnalysisTargetCurrent(audioPath)) return;
    setState(() {
      _musicIntervals = musicIntervals;
      _isAnalyzingMusicSegments = false;
    });
  }

  void _startBackgroundAnalysisJobs(String audioPath) {
    unawaited(_analyzeSilenceForAutoChapter(audioPath));
    unawaited(_analyzeWaveformForSeekbar(audioPath));
  }

  Future<void> _reanalyzeSilenceForCurrentPathIfAny() async {
    final currentPath = currentFilePath;
    if (currentPath != null) {
      await _analyzeSilenceForAutoChapter(currentPath);
    }
  }

  bool _isWaveformAnalysisTargetCurrent(String audioPath) {
    return mounted && _waveformAnalysisPath == audioPath;
  }

  bool _isSilenceAnalysisTargetCurrent(String audioPath) {
    return mounted && _silenceAnalysisPath == audioPath;
  }

  bool _resolveIsPlayingAfterLoad({
    required bool resetPlayState,
    required bool autoPlay,
    required bool previousIsPlaying,
  }) {
    if (autoPlay) return true;
    if (resetPlayState) return false;
    return previousIsPlaying;
  }

  /// 現在選択中のファイルをプレイヤーへ読み込み、必要なら自動再生する。
  Future<void> loadCurrentFile({
    bool resetPlayState = false,
    bool autoPlay = false,
  }) async {
    final path = currentFilePath;
    if (path == null) return;

    if (!mounted) return;
    try {
      await _player.setAudioSource(
        AudioSource.file(
          path,
          tag: MediaItem(
            id: path,
            album: 'Radiaudio',
            title: fileNameFromPath(path),
          ),
        ),
      );
      await _player.setSpeed(playbackSpeed);
      if (autoPlay) {
        await _player.play();
      }
      if (!mounted) return;
      final nextIsPlaying = _resolveIsPlayingAfterLoad(
        resetPlayState: resetPlayState,
        autoPlay: autoPlay,
        previousIsPlaying: isPlaying,
      );
      setState(() {
        _skipTargetChapters = <int>{};
        _musicIntervals = [];
        currentPositionSec = 0;
        totalDurationSec = (_player.duration?.inMilliseconds ?? 0) / 1000;
        isPlaying = nextIsPlaying;
      });
      _startBackgroundAnalysisJobs(path);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _skipTargetChapters = <int>{};
        _musicIntervals = [];
        currentPositionSec = 0;
        totalDurationSec = 0;
        isPlaying = false;
      });
      showQuickSnack(_tr('loadFailed'), milliseconds: 1000);
    }
  }

  /// 設定ダイアログを表示し、フォルダとチャプター秒数を編集できるようにする。
  void showSettingsDialog() {
    final settingsModel = _buildPlayerSettingsModel();
    final settingsActions = _buildPlayerSettingsActions();
    unawaited(
      showPlayerSettingsDialog(
        context: context,
        tr: _tr,
        settings: settingsModel,
        actions: settingsActions,
      ),
    );
  }

  PlayerSettingsModel _buildPlayerSettingsModel() {
    return PlayerSettingsModel(
      supportedLanguageCodes: supportedLanguageCodes,
      languageDisplayNames: languageDisplayNames,
      defaultMusicFolderPath: defaultMusicFolderPath,
      defaultPlaybackSpeed: defaultPlaybackSpeed,
      chapterUnitSec: chapterUnitSec,
      minChapterUnitSec: PlayerConstants.minChapterUnitSec,
      maxChapterUnitSec: PlayerConstants.maxChapterUnitSec,
      selectedLanguageCode: selectedLanguageCode,
      preventAutoSleepDuringPlayback: _preventAutoSleepDuringPlayback,
      isPremiumUser: _isPremiumUser,
      usesMockPremiumBilling: _usesMockPremiumBilling,
      adsDisabledUntil: _adsDisabledUntil,
      musicDetectionEnabled: _musicDetectionEnabled,
    );
  }

  PlayerSettingsActions _buildPlayerSettingsActions() {
    return PlayerSettingsActions(
      onLanguageChanged: _onSettingsLanguageChanged,
      onPickDefaultFolder: _onPickDefaultFolder,
      onDefaultFolderChanged: _onDefaultFolderChanged,
      onDefaultSpeedChanged: _onDefaultSpeedChanged,
      onChapterUnitChanged: _onChapterUnitChanged,
      onChapterUnitChangeEnd: _onChapterUnitChangeEnd,
      onPreventAutoSleepChanged: _onPreventAutoSleepChanged,
      onPremiumChanged: _onPremiumChanged,
      onRestorePremiumPurchases: _onRestorePremiumPurchases,
      onWatchRewardAd: _onWatchRewardAd,
      getIsPremiumUser: () => _isPremiumUser,
      getAdsDisabledUntil: () => _adsDisabledUntil,
      onMusicDetectionEnabledChanged: _onMusicDetectionEnabledChanged,
    );
  }

  Future<void> _onSettingsLanguageChanged(String value) async {
    if (!mounted) return;
    setState(() {
      selectedLanguageCode = value;
    });
    await savePlayerLanguagePreference(value);
  }

  Future<String?> _onPickDefaultFolder(String? currentPath) {
    if (!_supportsDefaultFolderSelection) {
      if (!_notifiedDefaultFolderUnsupported) {
        _notifiedDefaultFolderUnsupported = true;
        showQuickSnack(
          _tr('iosDefaultFolderUnsupported'),
          milliseconds: 1200,
        );
      }
      return Future.value(null);
    }
    return getDirectoryPath(
      initialDirectory:
          currentPath == null || currentPath.isEmpty ? null : currentPath,
      confirmButtonText: _tr('useThisFolder'),
    );
  }

  Future<void> _onDefaultFolderChanged(String selectedPath) async {
    if (!mounted) return;
    setState(() {
      defaultMusicFolderPath = selectedPath;
    });
    await _persistCurrentDefaultSettings(path: selectedPath);
  }

  Future<void> _onDefaultSpeedChanged(double value) async {
    if (!mounted) return;
    setState(() {
      defaultPlaybackSpeed = value;
      playbackSpeed = value;
    });
    await _player.setSpeed(value);
    await _persistCurrentDefaultSettings(defaultSpeed: value);
  }

  Future<void> _onChapterUnitChanged(double value) async {
    if (!mounted) return;
    setState(() {
      chapterUnitSec = value;
    });
    await _persistCurrentDefaultSettings(chapterSeconds: value);
  }

  Future<void> _onChapterUnitChangeEnd() async {
    await _reanalyzeSilenceForCurrentPathIfAny();
  }

  Future<void> _onPreventAutoSleepChanged(bool value) async {
    if (!mounted) return;
    setState(() {
      _preventAutoSleepDuringPlayback = value;
    });
    await _syncAutoSleepPrevention();
    await _persistCurrentDefaultSettings(
      preventAutoSleepDuringPlayback: value,
    );
  }

  Future<void> _onPremiumChanged(bool value) async {
    await _togglePremiumForCurrentSetup(value);
  }

  Future<void> _onRestorePremiumPurchases() async {
    await _restorePremiumPurchases();
  }

  Future<void> _onWatchRewardAd() async {
    await _grantRewardAdFree(const Duration(hours: 24));
  }

  void _applyTrackSkipDecision(TrackSkipDecision decision) {
    setState(() {
      if (decision.moved) {
        currentFilePath = decision.nextFilePath;
        currentTitle = decision.nextTitle ?? currentTitle;
      }
      currentIndex = decision.updatedCurrentIndex;
      totalCount = decision.updatedTotalCount;
      currentPositionSec = 0;
    });
  }

  void _applySelectedTrackFromFolder({
    required List<String> files,
    required SelectedTrackResolution selected,
  }) {
    setState(() {
      folderAudioFiles = files;
      currentFilePath = selected.resolvedPath;
      currentTitle = selected.resolvedTitle;
      currentIndex = selected.resolvedIndex + 1;
      totalCount = files.length;
      currentPositionSec = 0;
      totalDurationSec = 0;
      isPlaying = false;
    });
  }

  /// 音声ファイルを選択し、再生対象とチャプター一覧を更新して自動再生する。
  Future<void> openAudioFile() async {
    final initialDirectory =
        defaultMusicFolderPath.isEmpty ? null : defaultMusicFolderPath;
    final file = await pickAudioFile(initialDirectory: initialDirectory);
    if (file == null) return;

    final files = await loadAudioFilesInSameFolder(file.path);
    final selected = resolveSelectedTrackInFolder(
      files: files,
      selectedPath: file.path,
    );
    _applySelectedTrackFromFolder(files: files, selected: selected);
    unawaited(_registerAdOpportunity(source: 'open_audio'));
    await loadCurrentFile(resetPlayState: true, autoPlay: true);
    showQuickSnack(
      _tr('loadedFile', {'file': selected.resolvedTitle}),
      milliseconds: 900,
    );
  }

  /// シーク操作中の値を優先して、表示用シーク位置を返す。
  double get seekBarValue {
    final double maxValue = totalDurationSec > 0 ? totalDurationSec : 1.0;
    final rawValue = isDraggingSeekBar ? draggingSeekSec : currentPositionSec;
    if (rawValue < 0) return 0;
    if (rawValue > maxValue) return maxValue;
    return rawValue;
  }

  /// ドラッグ中のプレビュー位置を更新する。
  void _previewSeekFromLocalPosition({
    required Offset localPosition,
    required Size size,
    required int rows,
    required double durationSec,
  }) {
    final previewSec = seekSecFromLocalPosition(
      localPosition: localPosition,
      size: size,
      rows: rows,
      durationSec: durationSec,
    );
    setState(() {
      isDraggingSeekBar = true;
      draggingSeekSec = previewSec;
      currentPositionSec = previewSec;
    });
  }

  /// プレビュー位置へ実際にシークを確定する。
  Future<void> _commitSeekPreview() async {
    final targetSec = draggingSeekSec;
    if (totalDurationSec <= 0) {
      if (!mounted) return;
      setState(() {
        isDraggingSeekBar = false;
        currentPositionSec = 0;
      });
      return;
    }

    setState(() {
      isDraggingSeekBar = false;
      currentPositionSec = targetSec;
    });
    await _player.seek(Duration(milliseconds: (targetSec * 1000).toInt()));
  }

  /// 再生/一時停止を即時UI反映で切り替える。
  Future<void> _togglePlayPause() async {
    if (currentFilePath == null) {
      showQuickSnack(_tr('pleaseOpenAudioFirst'), milliseconds: 1000);
      return;
    }

    final wasPlaying = isPlaying;
    final nextPlaying = !wasPlaying;

    if (!mounted) return;
    setState(() {
      isPlaying = nextPlaying;
    });
    unawaited(_syncAutoSleepPrevention());

    try {
      if (wasPlaying) {
        await _player.pause();
        showQuickSnack(_tr('pause'), milliseconds: 700);
      } else {
        if (_player.audioSource == null) {
          await loadCurrentFile(resetPlayState: false);
        }
        await _player.play();
        showQuickSnack(_tr('play'), milliseconds: 700);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isPlaying = wasPlaying;
      });
      unawaited(_syncAutoSleepPrevention());
      showQuickSnack(_tr('playActionFailed'), milliseconds: 1000);
    }
  }

  Widget _buildPlayerBody(String displayTitle) {
    return buildPlayerMainBody(
      displayTitle: displayTitle,
      currentFilePath: currentFilePath,
      waveformLevels: _waveformLevels,
      totalDurationSec: totalDurationSec,
      seekBarValue: seekBarValue,
      silenceTriggersSec: _silenceTriggersSec,
      isPremiumUser: _isPremiumUser,
      skipTargetChapters: _skipTargetChapters,
      isAnalyzingSilence: _isAnalyzingSilence,
      isPreparingWindowsAnalyzer: _isPreparingWindowsAnalyzer,
      isAnalyzingWaveform: _isAnalyzingWaveform,
      isAnalyzingMusicSegments: _isAnalyzingMusicSegments,
      currentIndex: currentIndex,
      totalCount: totalCount,
      volumeLevel: volumeLevel,
      currentPositionSec: currentPositionSec,
      playbackSpeed: playbackSpeed,
      isPlaying: isPlaying,
      statusMessage: _statusMessage,
      tr: _tr,
      formatTimelineTime: formatTimelineTime,
      formatTime: formatTime,
      onRegisterSeekbarTapOpportunity: () {
        return _registerAdOpportunity(
          source: 'seekbar_tap',
          allowWhilePlaying: true,
        );
      },
      onPreviewSeek: _previewSeekFromLocalPosition,
      onCommitSeek: _commitSeekPreview,
      onSeekPanCancel: () {
        setState(() {
          isDraggingSeekBar = false;
        });
      },
      onToggleSkipTarget: _toggleSkipTargetAtLocalPositionPremium,
      waveformLevelForBar: (barIndex, totalBars) {
        return waveformLevelForBar(
          waveformLevels: _waveformLevels,
          barIndex: barIndex,
          totalBars: totalBars,
        );
      },
      collectMusicRunsForRow: ({required row, required barsPerRow, required secPerBar}) {
        return collectMusicRunsForRow(
          row: row,
          barsPerRow: barsPerRow,
          secPerBar: secPerBar,
          musicIntervals: _musicIntervals,
        );
      },
      buildMusicNotesText: buildMusicNotesText,
      onOpenSettings: showSettingsDialog,
      onDecreaseVolume: decreaseVolume,
      onIncreaseVolume: increaseVolume,
      onPreviousChapterTap: handlePreviousChapterTap,
      onSkipPreviousTrack: () => skipTrack(false),
      onTogglePlayPause: _togglePlayPause,
      onStopPlayback: stopPlayback,
      onNextChapterTap: () => skipChapter(true),
      onSkipNextTrack: () => skipTrack(true),
      onIncreaseSpeed: increaseSpeed,
      onDecreaseSpeed: decreaseSpeed,
      onOpenAudioFile: openAudioFile,
    );
  }

  @override

  /// プレイヤー画面全体のUIを構築する。
  Widget build(BuildContext context) {
    final displayTitle = currentFilePath == null
        ? _tr('selectAudioFileFromFolderPrompt')
        : currentTitle;
    return Scaffold(
      bottomNavigationBar: null,
      body: _buildPlayerBody(displayTitle),
    );
  }
}
