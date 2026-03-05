import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:ffmpeg_helper/ffmpeg_helper.dart';
import 'package:just_audio/just_audio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:radio_player_simple/localization/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const RadioMockApp());
}

class RadioMockApp extends StatelessWidget {
  const RadioMockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const PlayerScreen(),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  String currentTitle =
      "これはとても長いラジオ番組タイトルのサンプルです。高齢者でも読みやすいように3行固定表示します。256文字程度を想定しています。";

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
  static const String _prefDefaultMusicFolderPath = 'default_music_folder_path';
  static const String _prefDefaultPlaybackSpeed = 'default_playback_speed';
  static const String _prefChapterUnitSec = 'chapter_unit_sec';
  static const String _prefSilenceSeparateMinSec = 'silence_separate_min_sec';
  static const String _prefLanguageCode = 'language_code';
  static const String _prefIsPremiumUser = 'is_premium_user';
  static const String _prefAdsDisabledUntilIso = 'ads_disabled_until_iso';
  static const String _prefAdOpportunityCount = 'ad_opportunity_count';
  static const String _prefLastInterstitialAtIso = 'last_interstitial_at_iso';
  static const double _minChapterUnitSec = 0.3;
  static const double _maxChapterUnitSec = 2.0;
  static const double _silenceNoiseDb = -70.0;
  static const double _minSilenceSeparateMinSec = 0.1;
  static const double _maxSilenceSeparateMinSec = 3.0;
  static const double _fixedMinSegmentSecForSilenceSplit = 8.0;
  static const double _fixedMaxSegmentSecWithoutSplit = 24.0;
  static const double _hardMinChapterSec = 8.0;
  static const double _silenceDetectWindowSec = 0.01;
  double silenceSeparateMinSec = 1.0;
  static const int _minVolumeLevel = 0;
  static const int _maxVolumeLevel = 20;
  static const int _interstitialEveryOpportunities = 6;
  static const Duration _interstitialCooldown = Duration(minutes: 15);
  static const Set<String> _audioExtensions = {
    'mp3',
    'wav',
    'm4a',
    'aac',
    'flac',
    'ogg',
    'opus',
  };
  List<double> _silenceTriggersSec = [];
  int _nextSilenceTriggerIndex = 0;
  bool _isAnalyzingSilence = false;
  bool _notifiedSilenceAnalyzerUnsupported = false;
  bool _notifiedDefaultFolderUnsupported = false;
  bool _isPreparingWindowsAnalyzer = false;
  String? _silenceAnalysisPath;
  bool _isAnalyzingWaveform = false;
  String? _waveformAnalysisPath;
  List<double> _waveformLevels = [];
  final Map<String, List<double>> _waveformCache = {};
  DateTime? _lastPreviousChapterTapAt;
  static const Duration _chapterDoubleTapWindow = Duration(milliseconds: 350);
  String selectedLanguageCode = 'ja';
  bool _isPremiumUser = false;
  DateTime? _adsDisabledUntil;
  int _adOpportunityCount = 0;
  DateTime? _lastInterstitialAt;

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
    final normalized = (volumeLevel / _maxVolumeLevel).clamp(0.0, 1.0);
    await _player.setVolume(normalized);
  }

  /// 音量を1段階上げる。
  Future<void> increaseVolume() async {
    if (volumeLevel >= _maxVolumeLevel) return;
    setState(() {
      volumeLevel++;
    });
    await _applyPlayerVolume();
    showQuickSnack(_tr('volumeWithValue', {'value': '$volumeLevel'}));
  }

  /// 音量を1段階下げる。
  Future<void> decreaseVolume() async {
    if (volumeLevel <= _minVolumeLevel) return;
    setState(() {
      volumeLevel--;
    });
    await _applyPlayerVolume();
    showQuickSnack(_tr('volumeWithValue', {'value': '$volumeLevel'}));
  }

  /// 現在の再生位置から、次に監視すべき無音トリガー位置を再計算する。
  void _syncSilenceTriggerIndexWithPosition(double positionSec) {
    if (_silenceTriggersSec.isEmpty) {
      _nextSilenceTriggerIndex = 0;
      return;
    }
    _nextSilenceTriggerIndex = _silenceTriggersSec.indexWhere(
      (triggerSec) => triggerSec > positionSec + 0.02,
    );
    if (_nextSilenceTriggerIndex < 0) {
      _nextSilenceTriggerIndex = _silenceTriggersSec.length;
    }
  }

  @override

  /// ストリーム購読を初期化し、再生位置・再生状態をUIへ反映する。
  void initState() {
    super.initState();
    loadPreferences();
    _player.positionStream.listen((position) {
      if (!mounted) return;
      if (isDraggingSeekBar) return;
      final positionSec = position.inMilliseconds / 1000;
      setState(() {
        currentPositionSec = positionSec;
      });
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
    });
  }

  /// 保存済み設定（デフォルトフォルダ、チャプター単位秒数）を読み込む。
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedLanguageCode = prefs.getString(_prefLanguageCode) ?? 'ja';
    final normalizedLanguageCode =
        supportedLanguageCodes.contains(loadedLanguageCode)
            ? loadedLanguageCode
            : 'ja';
    final loadedDefaultSpeed =
        prefs.getDouble(_prefDefaultPlaybackSpeed) ?? defaultPlaybackSpeed;
    final normalizedDefaultSpeed = loadedDefaultSpeed.clamp(0.25, 3.0);
    final loadedChapterUnitSec =
        prefs.getDouble(_prefChapterUnitSec) ?? chapterUnitSec;
    final normalizedChapterUnitSec = loadedChapterUnitSec.clamp(
      _minChapterUnitSec,
      _maxChapterUnitSec,
    );
    final loadedSilenceSeparateMinSec =
        prefs.getDouble(_prefSilenceSeparateMinSec) ?? silenceSeparateMinSec;
    final normalizedSilenceSeparateMinSec = loadedSilenceSeparateMinSec.clamp(
      _minSilenceSeparateMinSec,
      _maxSilenceSeparateMinSec,
    );
    final loadedPremium = prefs.getBool(_prefIsPremiumUser) ?? false;
    final loadedAdsDisabledUntilIso = prefs.getString(_prefAdsDisabledUntilIso);
    final loadedAdsDisabledUntil = loadedAdsDisabledUntilIso == null
        ? null
        : DateTime.tryParse(loadedAdsDisabledUntilIso);
    final loadedAdOpportunityCount = prefs.getInt(_prefAdOpportunityCount) ?? 0;
    final loadedLastInterstitialAtIso =
        prefs.getString(_prefLastInterstitialAtIso);
    final loadedLastInterstitialAt = loadedLastInterstitialAtIso == null
        ? null
        : DateTime.tryParse(loadedLastInterstitialAtIso);
    if (!mounted) return;
    setState(() {
      defaultMusicFolderPath =
          prefs.getString(_prefDefaultMusicFolderPath) ?? "";
      defaultPlaybackSpeed = normalizedDefaultSpeed;
      playbackSpeed = normalizedDefaultSpeed;
      chapterUnitSec = normalizedChapterUnitSec;
      silenceSeparateMinSec = normalizedSilenceSeparateMinSec;
      selectedLanguageCode = normalizedLanguageCode;
      _isPremiumUser = loadedPremium;
      _adsDisabledUntil = loadedAdsDisabledUntil;
      _adOpportunityCount = loadedAdOpportunityCount;
      _lastInterstitialAt = loadedLastInterstitialAt;
    });
    await _player.setSpeed(normalizedDefaultSpeed);
    await _applyPlayerVolume();
  }

  /// 設定ダイアログで確定した設定値を永続化する。
  Future<void> saveDefaultSettings({
    required String path,
    required double defaultSpeed,
    required double chapterSeconds,
    required double silenceMinSec,
    required String languageCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDefaultMusicFolderPath, path);
    await prefs.setDouble(_prefDefaultPlaybackSpeed, defaultSpeed);
    await prefs.setDouble(_prefChapterUnitSec, chapterSeconds);
    await prefs.setDouble(_prefSilenceSeparateMinSec, silenceMinSec);
    await prefs.setString(_prefLanguageCode, languageCode);
  }

  Future<void> _setPremiumStatus(bool premium) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isPremiumUser = premium;
      if (premium) {
        _adsDisabledUntil = null;
      }
    });
    await prefs.setBool(_prefIsPremiumUser, premium);
    if (premium) {
      await prefs.remove(_prefAdsDisabledUntilIso);
      showQuickSnack('Premium enabled. Ads are now disabled.',
          milliseconds: 1200);
    } else {
      showQuickSnack('Premium disabled. Ads may appear again.',
          milliseconds: 1200);
    }
  }

  Future<void> _grantRewardAdFree(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final until = now.add(duration);
    if (!mounted) return;
    setState(() {
      _adsDisabledUntil = until;
    });
    await prefs.setString(_prefAdsDisabledUntilIso, until.toIso8601String());
    showQuickSnack('Reward unlocked: ads off for 24 hours.',
        milliseconds: 1200);
  }

  Future<void> _registerAdOpportunity({required String source}) async {
    if (_isAdFree) return;
    if (isPlaying) return;

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    _adOpportunityCount += 1;
    await prefs.setInt(_prefAdOpportunityCount, _adOpportunityCount);

    if (_adOpportunityCount % _interstitialEveryOpportunities != 0) {
      return;
    }
    final last = _lastInterstitialAt;
    if (last != null && now.difference(last) < _interstitialCooldown) {
      return;
    }

    _lastInterstitialAt = now;
    await prefs.setString(_prefLastInterstitialAtIso, now.toIso8601String());
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog.fullscreen(
          child: SafeArea(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'AD',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Interstitial ad placeholder ($source)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close Ad'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// サンプル表示用に疑似波形バーの高さを生成する。
  double sampleBarHeight(int row, int index) {
    final seed = ((row + 1) * 73856093) ^ ((index + 1) * 19349663);
    final normalized = (seed & 1023) / 1023;
    return 5 + normalized * 40;
  }

  /// チャプター番号に応じたバー色を返す。
  Color _chapterColorForIndex(int chapterIndex, bool isPlayed) {
    const baseColors = <Color>[
      Color(0xFF1976D2),
      Color(0xFF2E7D32),
      Color(0xFF6A1B9A),
      Color(0xFFEF6C00),
      Color(0xFF00838F),
      Color(0xFFAD1457),
    ];
    final base = baseColors[chapterIndex % baseColors.length];
    return isPlayed ? base : Color.lerp(base, Colors.white, 0.45)!;
  }

  /// 画面下部に短時間メッセージを表示する。
  void showQuickSnack(String text, {int milliseconds = 300}) {
    _statusMessage.value = text;
    final messenger = ScaffoldMessenger.of(context);
    final serial = ++_actionMessageSerial;
    messenger.removeCurrentSnackBar(reason: SnackBarClosedReason.remove);
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: Duration(milliseconds: milliseconds),
      ),
    );
    controller.closed.then((_) {
      if (!mounted) return;
      if (_actionMessageSerial != serial) return;
      _statusMessage.value = "";
    });
  }

  /// 再生速度を0.25刻みで加算し、最大値超過時は循環させる。
  void increaseSpeed() {
    setState(() {
      playbackSpeed += 0.25;
      if (playbackSpeed > 3.0) playbackSpeed = 0.25;
    });
    _player.setSpeed(playbackSpeed);
    showQuickSnack('${playbackSpeed.toStringAsFixed(2)}x');
  }

  /// 前チャプターボタン押下を処理し、短時間の連続押下なら2チャプター戻す。
  void handlePreviousChapterTap() {
    final now = DateTime.now();
    final isDoubleTap = _lastPreviousChapterTapAt != null &&
        now.difference(_lastPreviousChapterTapAt!) <= _chapterDoubleTapWindow;
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

    final currentSec = seekBarValue;
    double? targetSec;

    if (forward) {
      for (final triggerSec in _silenceTriggersSec) {
        if (triggerSec > currentSec + 0.02) {
          targetSec = triggerSec;
          break;
        }
      }
      if (targetSec == null) {
        showQuickSnack(_tr('lastChapter'));
        return;
      }
    } else {
      final stepsToMove = backwardSteps < 1 ? 1 : backwardSteps;
      var matchedCount = 0;
      for (var i = _silenceTriggersSec.length - 1; i >= 0; i--) {
        final triggerSec = _silenceTriggersSec[i];
        if (triggerSec < currentSec - 0.02) {
          matchedCount++;
          if (matchedCount >= stepsToMove) {
            targetSec = triggerSec;
            break;
          }
        }
      }
      if (targetSec == null) {
        if (currentSec > 0.2) {
          targetSec = 0;
        } else {
          showQuickSnack(_tr('firstChapter'));
          return;
        }
      }
    }

    await _player.seek(Duration(milliseconds: (targetSec * 1000).toInt()));
    if (!mounted) return;
    setState(() {
      currentPositionSec = targetSec!;
    });
    _syncSilenceTriggerIndexWithPosition(targetSec);
    final chapterMessage = forward
        ? _tr('nextChapter')
        : (backwardSteps >= 2 ? _tr('prevPrevChapter') : _tr('prevChapter'));
    showQuickSnack(chapterMessage);
  }

  /// 曲を前後に移動する（長押し操作用）。
  Future<void> skipTrack(bool forward) async {
    var moved = false;
    var message = forward ? _tr('nextTrack') : _tr('prevTrack');
    setState(() {
      if (folderAudioFiles.isNotEmpty && currentFilePath != null) {
        final currentPathLower = normalizedPathKey(currentFilePath!);
        final currentPos = folderAudioFiles.indexWhere(
          (path) => normalizedPathKey(path) == currentPathLower,
        );
        if (currentPos >= 0) {
          if (forward && currentPos >= folderAudioFiles.length - 1) {
            message = _tr('lastFile');
          } else if (!forward && currentPos <= 0) {
            message = _tr('firstFile');
          } else {
            final nextPos = forward ? currentPos + 1 : currentPos - 1;
            moved = true;
            currentFilePath = folderAudioFiles[nextPos];
            currentTitle = fileNameFromPath(currentFilePath!);
            currentIndex = nextPos + 1;
            totalCount = folderAudioFiles.length;
          }
        }
      } else {
        final beforeIndex = currentIndex;
        if (forward) {
          if (currentIndex < totalCount) currentIndex++;
        } else {
          if (currentIndex > 1) currentIndex--;
        }
        if (currentIndex == beforeIndex) {
          message = forward ? _tr('lastFile') : _tr('firstFile');
        }
      }
      currentPositionSec = 0;
    });
    if (moved) {
      await loadCurrentFile(resetPlayState: true, autoPlay: true);
      unawaited(_registerAdOpportunity(source: 'skip_track'));
    }
    showQuickSnack(message);
  }

  /// 再生速度を0.25刻みで減算し、最小値未満時は循環させる。
  void decreaseSpeed() {
    setState(() {
      playbackSpeed -= 0.25;
      if (playbackSpeed < 0.25) playbackSpeed = 3.0;
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
        _nextSilenceTriggerIndex = 0;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isAnalyzingSilence = true;
      _silenceAnalysisPath = audioPath;
      _silenceTriggersSec = [];
      _nextSilenceTriggerIndex = 0;
    });

    final silenceStarts = <double>[];
    final silenceEnds = <double>[];
    final silenceDurations = <double>[];
    final startPattern = RegExp(r'silence_start:\s*([0-9]+(?:\.[0-9]+)?)');
    final endPattern = RegExp(
      r'silence_end:\s*([0-9]+(?:\.[0-9]+)?)\s*\|\s*silence_duration:\s*([0-9]+(?:\.[0-9]+)?)',
    );

    try {
      String output = '';
      if (Platform.isWindows) {
        if (!mounted) return;
        setState(() {
          _isPreparingWindowsAnalyzer = true;
        });
        final windowsFfmpegPath = await _ensureWindowsBundledFfmpeg();
        if (windowsFfmpegPath == null) {
          if (!mounted) return;
          setState(() {
            _isPreparingWindowsAnalyzer = false;
            _isAnalyzingSilence = false;
          });
          return;
        }
        final result = await Process.run(windowsFfmpegPath, [
          '-hide_banner',
          '-i',
          audioPath,
          '-af',
          'silencedetect=noise=${_silenceNoiseDb.toStringAsFixed(1)}dB:d=$_silenceDetectWindowSec',
          '-f',
          'null',
          '-',
        ]);
        output = '${result.stderr}\n${result.stdout}';
      } else {
        final command =
          '-hide_banner -i "$audioPath" -af "silencedetect=noise=${_silenceNoiseDb.toStringAsFixed(1)}dB:d=$_silenceDetectWindowSec" -f null -';
        final session = await FFmpegKit.execute(command);
        output = (await session.getAllLogsAsString()) ??
            (await session.getOutput()) ??
            '';
        final returnCode = await session.getReturnCode();
        if (returnCode != null &&
            !ReturnCode.isSuccess(returnCode) &&
            !ReturnCode.isCancel(returnCode)) {
          if (output.isEmpty) {
            if (!mounted) return;
            setState(() {
              _isAnalyzingSilence = false;
            });
            return;
          }
        }
      }

      for (final match in startPattern.allMatches(output)) {
        final raw = match.group(1);
        final startSec = double.tryParse(raw ?? '');
        if (startSec == null) continue;
        silenceStarts.add(startSec);
      }

      for (final match in endPattern.allMatches(output)) {
        final endRaw = match.group(1);
        final durationRaw = match.group(2);
        final endSec = double.tryParse(endRaw ?? '');
        final durationSec = double.tryParse(durationRaw ?? '');
        if (endSec == null || durationSec == null) continue;
        silenceEnds.add(endSec);
        silenceDurations.add(durationSec);
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

    if (!mounted) return;
    if (_silenceAnalysisPath != audioPath) return;
    final splitTriggers = <double>[];
    var termStartSec = 0.0;
    final intervalCount = math.min(
      silenceStarts.length,
      math.min(silenceEnds.length, silenceDurations.length),
    );

    for (var i = 0; i < intervalCount; i++) {
      final silenceStartSec = silenceStarts[i];
      final silenceEndSec = silenceEnds[i];
      final silenceDurationSec = silenceDurations[i];
      if (!silenceEndSec.isFinite || silenceEndSec <= 0) continue;
      if (silenceEndSec <= silenceStartSec) continue;
      final segmentLenSec = silenceEndSec - termStartSec;
        if (segmentLenSec < _hardMinChapterSec) continue;
      final shouldSplit = ((silenceDurationSec > silenceSeparateMinSec &&
            segmentLenSec > _fixedMinSegmentSecForSilenceSplit) ||
          segmentLenSec > _fixedMaxSegmentSecWithoutSplit);
      if (!shouldSplit) continue;
      splitTriggers.add(silenceEndSec);
      termStartSec = silenceEndSec;
    }

    splitTriggers.sort();
    setState(() {
      _isPreparingWindowsAnalyzer = false;
      _isAnalyzingSilence = false;
      _silenceTriggersSec = splitTriggers;
      _nextSilenceTriggerIndex = 0;
    });
    _syncSilenceTriggerIndexWithPosition(currentPositionSec);
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

    final pcmFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}radiaudio_wave_${audioPath.hashCode.abs()}.pcm',
    );

    try {
      if (Platform.isWindows) {
        final windowsFfmpegPath = await _ensureWindowsBundledFfmpeg();
        if (windowsFfmpegPath == null) {
          if (!mounted) return;
          setState(() {
            _isAnalyzingWaveform = false;
          });
          return;
        }
        await Process.run(windowsFfmpegPath, [
          '-hide_banner',
          '-i',
          audioPath,
          '-vn',
          '-ac',
          '1',
          '-ar',
          '8000',
          '-f',
          's16le',
          '-y',
          pcmFile.path,
        ]);
      } else {
        final command =
            '-hide_banner -i "$audioPath" -vn -ac 1 -ar 8000 -f s16le -y "${pcmFile.path}"';
        final session = await FFmpegKit.execute(command);
        final returnCode = await session.getReturnCode();
        if (returnCode != null && !ReturnCode.isSuccess(returnCode)) {
          if (!mounted) return;
          setState(() {
            _isAnalyzingWaveform = false;
          });
          return;
        }
      }

      if (!await pcmFile.exists()) {
        if (!mounted) return;
        setState(() {
          _isAnalyzingWaveform = false;
        });
        return;
      }

      final pcmBytes = await pcmFile.readAsBytes();
      final waveform = _extractAmplitudeLevelsFromPcm(
        pcmBytes,
        targetBins: 2400,
      );

      if (!mounted) return;
      if (_waveformAnalysisPath != audioPath) return;
      setState(() {
        _waveformLevels = waveform;
        _isAnalyzingWaveform = false;
      });
      _waveformCache[audioPath] = waveform;
    } catch (_) {
      if (!mounted) return;
      if (_waveformAnalysisPath != audioPath) return;
      setState(() {
        _isAnalyzingWaveform = false;
        _waveformLevels = [];
      });
    } finally {
      if (await pcmFile.exists()) {
        await pcmFile.delete();
      }
    }
  }

  /// PCM（16-bit little-endian）データを0.0〜1.0の振幅配列へ変換する。
  List<double> _extractAmplitudeLevelsFromPcm(
    Uint8List pcmBytes, {
    required int targetBins,
  }) {
    final totalSamples = pcmBytes.length ~/ 2;
    if (totalSamples <= 0) return [];

    final bins = math.min(targetBins, totalSamples);
    final samplesPerBin = (totalSamples / bins).ceil();
    final byteData = ByteData.sublistView(pcmBytes);
    final levels = <double>[];
    var maxLevel = 0.0;

    for (var bin = 0; bin < bins; bin++) {
      final startSample = bin * samplesPerBin;
      if (startSample >= totalSamples) break;
      final endSample = math.min(startSample + samplesPerBin, totalSamples);

      var peak = 0;
      for (var i = startSample; i < endSample; i++) {
        final sample = byteData.getInt16(i * 2, Endian.little).abs();
        if (sample > peak) peak = sample;
      }

      final level = peak / 32768.0;
      levels.add(level);
      if (level > maxLevel) {
        maxLevel = level;
      }
    }

    if (maxLevel <= 0) {
      return List<double>.filled(levels.length, 0.08);
    }

    return levels
        .map((level) => math.max(0.08, math.sqrt(level / maxLevel)))
        .toList(growable: false);
  }

  /// シークバー1本分の振幅レベルを返す。未解析時は `-1` を返す。
  double _waveformLevelForBar(int barIndex, int totalBars) {
    if (_waveformLevels.isEmpty || totalBars <= 0) return -1;
    final mappedIndex = ((barIndex / totalBars) * _waveformLevels.length)
        .floor()
        .clamp(0, _waveformLevels.length - 1);
    return _waveformLevels[mappedIndex];
  }

  /// Windows用の同梱FFmpegを準備し、実行可能パスを返す。
  Future<String?> _ensureWindowsBundledFfmpeg() async {
    if (!Platform.isWindows) return null;
    try {
      await FFMpegHelper.instance.initialize();
      final isPresent = await FFMpegHelper.instance.isFFMpegPresent();
      if (!isPresent) {
        final setupOk = await FFMpegHelper.instance.setupFFMpegOnWindows();
        if (!setupOk) return null;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final appDocDir = await getApplicationDocumentsDirectory();
      final ffmpegPath = path.join(
        appDocDir.path,
        packageInfo.appName,
        'ffmpeg',
        'ffmpeg-master-latest-win64-gpl',
        'bin',
        'ffmpeg.exe',
      );
      final ffmpegFile = File(ffmpegPath);
      if (!await ffmpegFile.exists()) {
        return null;
      }
      return ffmpegPath;
    } catch (_) {
      return null;
    }
  }

  /// 現在選択中のファイルをプレイヤーへ読み込み、必要なら自動再生する。
  Future<void> loadCurrentFile({
    bool resetPlayState = false,
    bool autoPlay = false,
  }) async {
    final path = currentFilePath;
    if (path == null) return;

    try {
      await _player.setFilePath(path);
      await _player.setSpeed(playbackSpeed);
      if (autoPlay) {
        await _player.play();
      }
      if (!mounted) return;
      setState(() {
        currentPositionSec = 0;
        totalDurationSec = (_player.duration?.inMilliseconds ?? 0) / 1000;
        if (resetPlayState && !autoPlay) {
          isPlaying = false;
        } else if (autoPlay) {
          isPlaying = true;
        }
      });
      unawaited(_analyzeSilenceForAutoChapter(path));
      unawaited(_analyzeWaveformForSeekbar(path));
    } catch (_) {
      if (!mounted) return;
      showQuickSnack(_tr('loadFailed'), milliseconds: 1000);
    }
  }

  /// 設定ダイアログを表示し、フォルダとチャプター秒数を編集できるようにする。
  void showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempFolderPath = defaultMusicFolderPath;
        double tempDefaultSpeed = defaultPlaybackSpeed;
        double tempChapterUnitSec = chapterUnitSec;
        double tempSilenceSeparateMinSec = silenceSeparateMinSec;
        String tempLanguageCode = selectedLanguageCode;
        bool tempPremium = _isPremiumUser;
        DateTime? tempAdsDisabledUntil = _adsDisabledUntil;

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text(_tr('settings')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_tr('language')),
                        DropdownButton<String>(
                          value: tempLanguageCode,
                          onChanged: (value) {
                            if (value == null) return;
                            dialogSetState(() {
                              tempLanguageCode = value;
                            });
                          },
                          items: supportedLanguageCodes
                              .map(
                                (code) => DropdownMenuItem<String>(
                                  value: code,
                                  child: Text(
                                    languageDisplayNames[code] ?? code,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                    const Divider(),
                    ListTile(
                      title: Text(_tr('defaultFolder')),
                      subtitle: Text(
                        tempFolderPath.isEmpty
                            ? _tr('unselected')
                            : tempFolderPath,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: () async {
                          if (!_supportsDefaultFolderSelection) {
                            if (!_notifiedDefaultFolderUnsupported) {
                              _notifiedDefaultFolderUnsupported = true;
                              showQuickSnack(
                                _tr('iosDefaultFolderUnsupported'),
                                milliseconds: 1200,
                              );
                            }
                            return;
                          }
                          final selectedPath = await getDirectoryPath(
                            initialDirectory:
                                tempFolderPath.isEmpty ? null : tempFolderPath,
                            confirmButtonText: _tr('useThisFolder'),
                          );
                          if (selectedPath == null || selectedPath.isEmpty) {
                            return;
                          }
                          dialogSetState(() {
                            tempFolderPath = selectedPath;
                          });
                        },
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_tr('defaultPlaybackSpeed')),
                        Text("${tempDefaultSpeed.toStringAsFixed(2)}x"),
                      ],
                    ),
                    Slider(
                      min: 0.25,
                      max: 3.0,
                      divisions: 11,
                      value: tempDefaultSpeed,
                      onChanged: (v) {
                        dialogSetState(() => tempDefaultSpeed = v);
                      },
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_tr('chapterUnitSeconds')),
                        Text(
                          _tr(
                            'secondsSuffix',
                            {'value': tempChapterUnitSec.toStringAsFixed(1)},
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      min: _minChapterUnitSec,
                      max: _maxChapterUnitSec,
                      divisions: 7,
                      value: tempChapterUnitSec,
                      onChanged: (v) {
                        dialogSetState(() => tempChapterUnitSec = v);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('分割に必要な最小無音秒'),
                        Text(
                            '${tempSilenceSeparateMinSec.toStringAsFixed(2)}s'),
                      ],
                    ),
                    Slider(
                      min: _minSilenceSeparateMinSec,
                      max: _maxSilenceSeparateMinSec,
                      divisions: ((_maxSilenceSeparateMinSec -
                                  _minSilenceSeparateMinSec) *
                              20)
                          .toInt(),
                      value: tempSilenceSeparateMinSec,
                      onChanged: (v) {
                        dialogSetState(() => tempSilenceSeparateMinSec = v);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Premium (No Ads)'),
                      subtitle: const Text('Simulated license switch for now'),
                      value: tempPremium,
                      onChanged: (value) async {
                        await _setPremiumStatus(value);
                        dialogSetState(() {
                          tempPremium = _isPremiumUser;
                          tempAdsDisabledUntil = _adsDisabledUntil;
                        });
                      },
                    ),
                    if (!tempPremium)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          tempAdsDisabledUntil != null &&
                                  DateTime.now().isBefore(tempAdsDisabledUntil!)
                              ? 'Ad-free until: ${tempAdsDisabledUntil!.toLocal()}'
                              : 'Ad-free reward not active',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    if (!tempPremium)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () async {
                            await _grantRewardAdFree(const Duration(hours: 24));
                            dialogSetState(() {
                              tempAdsDisabledUntil = _adsDisabledUntil;
                            });
                          },
                          icon: const Icon(Icons.ondemand_video),
                          label: const Text(
                              'Watch reward ad (simulate) -> 24h no ads'),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final shouldReanalyzeSilence =
                        (chapterUnitSec - tempChapterUnitSec).abs() > 0.0001 ||
                            (silenceSeparateMinSec - tempSilenceSeparateMinSec)
                            .abs() >
                          0.0001;
                    final currentPath = currentFilePath;
                    setState(() {
                      defaultMusicFolderPath = tempFolderPath;
                      defaultPlaybackSpeed = tempDefaultSpeed;
                      playbackSpeed = tempDefaultSpeed;
                      chapterUnitSec = tempChapterUnitSec;
                      silenceSeparateMinSec = tempSilenceSeparateMinSec;
                      selectedLanguageCode = tempLanguageCode;
                    });
                    await _player.setSpeed(tempDefaultSpeed);
                    await saveDefaultSettings(
                      path: tempFolderPath,
                      defaultSpeed: tempDefaultSpeed,
                      chapterSeconds: tempChapterUnitSec,
                      silenceMinSec: tempSilenceSeparateMinSec,
                      languageCode: tempLanguageCode,
                    );
                    Navigator.pop(context);
                    showQuickSnack(_tr('settingsSaved'), milliseconds: 700);
                    unawaited(_registerAdOpportunity(source: 'settings_save'));
                    if (shouldReanalyzeSilence && currentPath != null) {
                      unawaited(_analyzeSilenceForAutoChapter(currentPath));
                    }
                  },
                  child: Text(_tr('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// フルパスからファイル名のみを抽出する。
  String fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  /// フルパスから親ディレクトリパスを抽出する。
  String? directoryPathFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final splitIndex = normalized.lastIndexOf('/');
    if (splitIndex <= 0) return null;
    return normalized.substring(0, splitIndex);
  }

  /// 比較用にパス文字列を正規化する。
  String normalizedPathKey(String path) {
    return path.replaceAll('\\', '/').toLowerCase();
  }

  /// 拡張子が対応音声フォーマットかどうかを判定する。
  bool isAudioFilePath(String path) {
    final fileName = fileNameFromPath(path);
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) return false;
    final ext = fileName.substring(dotIndex + 1).toLowerCase();
    return _audioExtensions.contains(ext);
  }

  /// 選択ファイルと同フォルダの音声ファイル一覧を取得する。
  Future<List<String>> loadAudioFilesInSameFolder(String selectedPath) async {
    final folderPath = directoryPathFromPath(selectedPath);
    if (folderPath == null) return [selectedPath];

    // Mobile document providers often restrict sibling-file listing.
    if (Platform.isAndroid || Platform.isIOS) {
      return [selectedPath];
    }

    final directory = Directory(folderPath);
    if (!await directory.exists()) return [selectedPath];

    final files = <String>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final path = entity.path;
      if (!isAudioFilePath(path)) continue;
      files.add(path);
    }

    files.sort((a, b) {
      final aName = fileNameFromPath(a).toLowerCase();
      final bName = fileNameFromPath(b).toLowerCase();
      return aName.compareTo(bName);
    });

    if (files.isEmpty) {
      return [selectedPath];
    }
    return files;
  }

  /// 音声ファイルを選択し、再生対象とチャプター一覧を更新して自動再生する。
  Future<void> openAudioFile() async {
    const audioTypeGroup = XTypeGroup(
      label: 'audio',
      extensions: ['mp3', 'wav', 'm4a', 'aac', 'flac', 'ogg', 'opus'],
    );

    final initialDirectory =
        defaultMusicFolderPath.isEmpty ? null : defaultMusicFolderPath;
    final file = await openFile(
      acceptedTypeGroups: [audioTypeGroup],
      initialDirectory: initialDirectory,
    );
    if (file == null) return;

    final files = await loadAudioFilesInSameFolder(file.path);
    final selectedPathLower = normalizedPathKey(file.path);
    final selectedIndex = files.indexWhere(
      (path) => normalizedPathKey(path) == selectedPathLower,
    );
    final resolvedIndex = selectedIndex >= 0 ? selectedIndex : 0;
    final resolvedPath = files[resolvedIndex];
    final resolvedFileName = fileNameFromPath(resolvedPath);
    setState(() {
      folderAudioFiles = files;
      currentFilePath = resolvedPath;
      currentTitle = resolvedFileName;
      currentIndex = resolvedIndex + 1;
      totalCount = files.length;
      currentPositionSec = 0;
      totalDurationSec = 0;
      isPlaying = false;
    });
    unawaited(_registerAdOpportunity(source: 'open_audio'));
    await loadCurrentFile(resetPlayState: true, autoPlay: true);
    showQuickSnack(
      _tr('loadedFile', {'file': resolvedFileName}),
      milliseconds: 900,
    );
  }

  /// 秒数を `mm:ss` 形式の文字列に変換する。
  String formatTime(double sec) {
    int s = sec.toInt();
    int minutes = s ~/ 60;
    int seconds = s % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  /// タイムライン表示用に秒数を `m:ss` 形式へ変換する。
  String formatTimelineTime(double sec) {
    final safeSec = sec.isFinite ? sec : 0;
    final totalSeconds = safeSec < 0 ? 0 : safeSec.floor();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// シーク操作中の値を優先して、表示用シーク位置を返す。
  double get seekBarValue {
    final double maxValue = totalDurationSec > 0 ? totalDurationSec : 1.0;
    final rawValue = isDraggingSeekBar ? draggingSeekSec : currentPositionSec;
    if (rawValue < 0) return 0;
    if (rawValue > maxValue) return maxValue;
    return rawValue;
  }

  /// 上段シークバー内のタップ/ドラッグ座標を再生秒数へ変換する。
  double _seekSecFromLocalPosition({
    required Offset localPosition,
    required Size size,
    required int rows,
    required double durationSec,
  }) {
    final safeWidth = size.width <= 0 ? 1.0 : size.width;
    final safeHeight = size.height <= 0 ? 1.0 : size.height;
    final x = localPosition.dx.clamp(0.0, safeWidth);
    final y = localPosition.dy.clamp(0.0, safeHeight);

    final rowHeight = safeHeight / rows;
    final rowIndex = (y / rowHeight).floor().clamp(0, rows - 1);
    final rowProgress = (x / safeWidth).clamp(0.0, 1.0);
    final rowSpanSec = durationSec / rows;
    final seekSec = (rowIndex * rowSpanSec) + (rowProgress * rowSpanSec);
    return seekSec.clamp(0.0, durationSec);
  }

  /// ドラッグ中のプレビュー位置を更新する。
  void _previewSeekFromLocalPosition({
    required Offset localPosition,
    required Size size,
    required int rows,
    required double durationSec,
  }) {
    final previewSec = _seekSecFromLocalPosition(
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

    await _player.seek(Duration(milliseconds: (targetSec * 1000).toInt()));
    if (!mounted) return;
    setState(() {
      isDraggingSeekBar = false;
      currentPositionSec = targetSec;
    });
    _syncSilenceTriggerIndexWithPosition(targetSec);
  }

  Widget _buildAdBannerPlaceholder() {
    return SafeArea(
      top: false,
      child: Container(
        height: 56,
        color: Colors.grey.shade900,
        alignment: Alignment.center,
        child: const Text(
          'Banner Ad Placeholder',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override

  /// プレイヤー画面全体のUIを構築する。
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _isAdFree ? null : _buildAdBannerPlaceholder(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: Column(
            children: [
              // ===== タイトル + 設定 =====
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル（3行固定）
                    Expanded(
                      child: Text(
                        currentTitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),

                    // 設定ボタン
                    IconButton(
                      iconSize: 32,
                      onPressed: showSettingsDialog,
                      icon: const Icon(Icons.settings),
                    )
                  ],
                ),
              ),

              // ===== シークバー領域 =====
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const double labelColumnWidth = 52;
                      const double targetRowHeight = 44;
                      final dynamicRows =
                          (constraints.maxHeight / targetRowHeight).floor();
                      final rows = dynamicRows.clamp(3, 12).toInt();
                      final barsAreaWidth =
                          (constraints.maxWidth - labelColumnWidth - 8)
                              .clamp(60.0, double.infinity);
                      final dynamicBarsPerRow = (barsAreaWidth / 6).floor();
                      final barsPerRow =
                          dynamicBarsPerRow.clamp(8, 300).toInt();
                      final hasWaveform =
                          currentFilePath != null && _waveformLevels.isNotEmpty;
                      final rowSpanSec =
                          totalDurationSec > 0 ? totalDurationSec / rows : 0.0;
                      final effectiveDurationSec =
                          totalDurationSec > 0 ? totalDurationSec : rows * 30.0;
                      final seekProgressSec = seekBarValue.clamp(
                        0.0,
                        effectiveDurationSec,
                      );
                      final totalBars = rows * barsPerRow;
                      final secPerBar = effectiveDurationSec / totalBars;
                      int chapterIndexForSec(double sec) {
                        var chapterIndex = 0;
                        for (final triggerSec in _silenceTriggersSec) {
                          if (sec >= triggerSec) {
                            chapterIndex++;
                          } else {
                            break;
                          }
                        }
                        return chapterIndex;
                      }

                      return Row(
                        children: [
                          SizedBox(
                            width: labelColumnWidth,
                            child: Column(
                              children: List.generate(rows, (row) {
                                final rowStartSec = row * rowSpanSec;
                                return Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      formatTimelineTime(rowStartSec),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, barConstraints) {
                                final barSize = Size(
                                  barConstraints.maxWidth,
                                  barConstraints.maxHeight,
                                );
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (details) {
                                    _previewSeekFromLocalPosition(
                                      localPosition: details.localPosition,
                                      size: barSize,
                                      rows: rows,
                                      durationSec: effectiveDurationSec,
                                    );
                                    _commitSeekPreview();
                                  },
                                  onPanStart: (details) {
                                    _previewSeekFromLocalPosition(
                                      localPosition: details.localPosition,
                                      size: barSize,
                                      rows: rows,
                                      durationSec: effectiveDurationSec,
                                    );
                                  },
                                  onPanUpdate: (details) {
                                    _previewSeekFromLocalPosition(
                                      localPosition: details.localPosition,
                                      size: barSize,
                                      rows: rows,
                                      durationSec: effectiveDurationSec,
                                    );
                                  },
                                  onPanEnd: (_) {
                                    _commitSeekPreview();
                                  },
                                  onPanCancel: () {
                                    setState(() {
                                      isDraggingSeekBar = false;
                                    });
                                  },
                                  child: Column(
                                    children: List.generate(rows, (row) {
                                      return Expanded(
                                        child: Stack(
                                          children: [
                                            Row(
                                              children: List.generate(
                                                  barsPerRow, (i) {
                                                final flatIndex =
                                                    (row * barsPerRow) + i;
                                                final waveformLevel =
                                                    _waveformLevelForBar(
                                                  flatIndex,
                                                  totalBars,
                                                );
                                                final barSec =
                                                    (flatIndex + 1) * secPerBar;
                                                final double renderedHeight =
                                                    hasWaveform
                                                        ? (waveformLevel >= 0
                                                            ? 4.0 +
                                                                (waveformLevel *
                                                                    41.0)
                                                            : 0.0)
                                                        : 0.0;
                                                final isPlayed =
                                                    barSec <= seekProgressSec;
                                                final chapterIndex =
                                                    chapterIndexForSec(barSec);

                                                return Expanded(
                                                  child: Container(
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 1,
                                                    ),
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    child: Container(
                                                      height: renderedHeight,
                                                      color: _isAnalyzingSilence
                                                          ? (isPlayed
                                                              ? _chapterColorForIndex(
                                                                  chapterIndex,
                                                                  true,
                                                                )
                                                              : Colors.blueGrey
                                                                  .shade300)
                                                          : _chapterColorForIndex(
                                                              chapterIndex,
                                                              isPlayed,
                                                            ),
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ),
                                            if (!hasWaveform)
                                              Positioned(
                                                left: 0,
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  height: 2,
                                                  color: Colors.black26,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ===== インデックス + 時間 =====
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 25,
                      child: SizedBox(
                        height: 60,
                        child: Tooltip(
                          message: _tr('volumeDown'),
                          child: ElevatedButton(
                            onPressed: decreaseVolume,
                            style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero),
                            child: const Icon(Icons.volume_down, size: 38),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 50,
                      child: Text(
                        "$currentIndex/$totalCount    "
                        "${formatTime(currentPositionSec)}/${formatTime(totalDurationSec)}    "
                        "${_tr('volumeLabel', {'value': '$volumeLevel'})}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    Expanded(
                      flex: 25,
                      child: SizedBox(
                        height: 60,
                        child: Tooltip(
                          message: _tr('volumeUp'),
                          child: ElevatedButton(
                            onPressed: increaseVolume,
                            style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero),
                            child: const Icon(Icons.volume_up, size: 38),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 22,
                child: ValueListenableBuilder<String>(
                  valueListenable: _statusMessage,
                  builder: (context, message, _) {
                    if (currentFilePath == null) {
                      return Text(
                        _tr('pleaseSelectAudioFile'),
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black54),
                      );
                    }
                    final chapterCount = _silenceTriggersSec.isEmpty
                        ? 1
                        : _silenceTriggersSec.length + 1;
                    final currentChapter = _silenceTriggersSec.isEmpty
                        ? 1
                        : (_silenceTriggersSec
                                    .where((sec) => sec <= seekBarValue + 0.02)
                                    .length +
                                1)
                            .clamp(1, chapterCount);
                    final silenceInfo = _isPreparingWindowsAnalyzer
                        ? _tr('silencePreparing')
                        : (_isAnalyzingSilence
                            ? _tr('silenceAnalyzing')
                            : (_isAnalyzingWaveform
                                ? _tr('waveformAnalyzing')
                                : _tr(
                                    'chapterStatus',
                                    {
                                      'current': '$currentChapter',
                                      'total': '$chapterCount',
                                    },
                                  )));
                    final displayMessage = message.isEmpty
                        ? silenceInfo
                        : '$silenceInfo  $message';
                    return Text(
                      displayMessage,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black54),
                    );
                  },
                ),
              ),

              // ===== 再生ボタン群 =====
              SizedBox(
                height: 70,
                child: Row(
                  children: [
                    Expanded(
                      flex: 25,
                      child: Tooltip(
                        message: _tr('chapterPrevTooltip'),
                        child: ElevatedButton(
                          onPressed: handlePreviousChapterTap,
                          onLongPress: () => skipTrack(false),
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero),
                          child: const Icon(Icons.skip_previous, size: 40),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 50,
                      child: Tooltip(
                        message: _tr('playTooltip'),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (currentFilePath == null) {
                              showQuickSnack(_tr('pleaseOpenAudioFirst'),
                                  milliseconds: 1000);
                              return;
                            }
                            try {
                              if (_player.playing) {
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
                              showQuickSnack(_tr('playActionFailed'),
                                  milliseconds: 1000);
                            }
                          },
                          onLongPress: stopPlayback,
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.yellow.shade600),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 25,
                      child: Tooltip(
                        message: _tr('chapterNextTooltip'),
                        child: ElevatedButton(
                          onPressed: () => skipChapter(true),
                          onLongPress: () => skipTrack(true),
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero),
                          child: const Icon(Icons.skip_next, size: 40),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== 速度 + 開く =====
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    Expanded(
                      flex: 50,
                      child: Tooltip(
                        message: _tr('speedTooltip'),
                        child: ElevatedButton(
                          onPressed: increaseSpeed,
                          onLongPress: decreaseSpeed,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size.fromHeight(60),
                          ),
                          child: Text(
                            "${playbackSpeed.toStringAsFixed(2)}x",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 50,
                      child: ElevatedButton(
                        onPressed: openAudioFile,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size.fromHeight(60),
                        ),
                        child: const Icon(Icons.folder_open, size: 40),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
