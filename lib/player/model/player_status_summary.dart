import 'package:radio_player_simple/player/model/chapter_logic.dart';

class PlayerStatusSummary {
  const PlayerStatusSummary({
    required this.currentChapter,
    required this.chapterCount,
    required this.centerText,
  });

  final int currentChapter;
  final int chapterCount;
  final String centerText;
}

PlayerStatusSummary buildPlayerStatusSummary({
  required List<double> silenceTriggersSec,
  required double seekBarValue,
  required bool isPreparingWindowsAnalyzer,
  required bool isAnalyzingSilence,
  required bool isAnalyzingWaveform,
  required bool isAnalyzingMusicSegments,
  required String Function(String, [Map<String, String>]) tr,
}) {
  final chapterCount = chapterCountFromTriggers(silenceTriggersSec);
  final currentChapter = (chapterIndexForSec(
              silenceTriggersSec: silenceTriggersSec,
              sec: seekBarValue + 0.02) +
          1)
      .clamp(1, chapterCount);

  final centerText = _buildCenterText(
    tr: tr,
    isPreparingWindowsAnalyzer: isPreparingWindowsAnalyzer,
    isAnalyzingSilence: isAnalyzingSilence,
    isAnalyzingWaveform: isAnalyzingWaveform,
    isAnalyzingMusicSegments: isAnalyzingMusicSegments,
    currentChapter: currentChapter,
    chapterCount: chapterCount,
  );

  return PlayerStatusSummary(
    currentChapter: currentChapter,
    chapterCount: chapterCount,
    centerText: centerText,
  );
}

String _buildCenterText({
  required String Function(String, [Map<String, String>]) tr,
  required bool isPreparingWindowsAnalyzer,
  required bool isAnalyzingSilence,
  required bool isAnalyzingWaveform,
  required bool isAnalyzingMusicSegments,
  required int currentChapter,
  required int chapterCount,
}) {
  if (isPreparingWindowsAnalyzer) {
    return tr('silencePreparing');
  }
  if (isAnalyzingSilence) {
    return tr('silenceAnalyzing');
  }
  if (isAnalyzingWaveform || isAnalyzingMusicSegments) {
    return tr('voiceMusicAnalyzing');
  }
  return tr(
    'chapterStatus',
    {
      'current': '$currentChapter',
      'total': '$chapterCount',
    },
  );
}
