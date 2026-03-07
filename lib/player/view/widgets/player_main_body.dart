import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:radio_player_simple/player/model/player_status_summary.dart';
import 'package:radio_player_simple/player/view/widgets/chapter_colors.dart';
import 'package:radio_player_simple/player/view/widgets/player_bottom_controls.dart';
import 'package:radio_player_simple/player/view/widgets/player_screen_sections.dart';
import 'package:radio_player_simple/player/view/widgets/player_seek_timeline.dart';

Widget buildPlayerMainBody({
  required String displayTitle,
  required String? currentFilePath,
  required List<double> waveformLevels,
  required double totalDurationSec,
  required double seekBarValue,
  required List<double> silenceTriggersSec,
  required bool isPremiumUser,
  required Set<int> skipTargetChapters,
  required bool isAnalyzingSilence,
  required bool isPreparingWindowsAnalyzer,
  required bool isAnalyzingWaveform,
  required bool isAnalyzingMusicSegments,
  required int currentIndex,
  required int totalCount,
  required int volumeLevel,
  required double currentPositionSec,
  required double playbackSpeed,
  required bool isPlaying,
  required ValueListenable<String> statusMessage,
  required String Function(String, [Map<String, String>]) tr,
  required String Function(double sec) formatTimelineTime,
  required String Function(double sec) formatTime,
  required Future<void> Function() onRegisterSeekbarTapOpportunity,
  required PreviewSeekFromLocalPosition onPreviewSeek,
  required Future<void> Function() onCommitSeek,
  required VoidCallback onSeekPanCancel,
  required ToggleSkipTargetAtLocalPosition onToggleSkipTarget,
  required double Function(int barIndex, int totalBars) waveformLevelForBar,
  required CollectMusicRunsForRow collectMusicRunsForRow,
  required String Function(double maxWidth) buildMusicNotesText,
  required VoidCallback onOpenSettings,
  required VoidCallback onDecreaseVolume,
  required VoidCallback onIncreaseVolume,
  required VoidCallback onPreviousChapterTap,
  required VoidCallback onSkipPreviousTrack,
  required VoidCallback onTogglePlayPause,
  required VoidCallback onStopPlayback,
  required VoidCallback onNextChapterTap,
  required VoidCallback onSkipNextTrack,
  required VoidCallback onIncreaseSpeed,
  required VoidCallback onDecreaseSpeed,
  required VoidCallback onOpenAudioFile,
}) {
  Widget buildCenterStatusContent() {
    final statusSummary = buildPlayerStatusSummary(
      silenceTriggersSec: silenceTriggersSec,
      seekBarValue: seekBarValue,
      isPreparingWindowsAnalyzer: isPreparingWindowsAnalyzer,
      isAnalyzingSilence: isAnalyzingSilence,
      isAnalyzingWaveform: isAnalyzingWaveform,
      isAnalyzingMusicSegments: isAnalyzingMusicSegments,
      tr: tr,
    );
    final currentChapterColor = chapterColorForIndex(
      statusSummary.currentChapter - 1,
      true,
    );
    final compactFileInfo = ' ';
    final compactVolumeInfo = tr(
      'volumeWithValue',
      {'value': '$volumeLevel'},
    );
    return buildPlayerCenterStatus(
      compactFileInfo: compactFileInfo,
      chapterColor: currentChapterColor,
      silenceInfo: statusSummary.centerText,
      compactVolumeInfo: compactVolumeInfo,
    );
  }

  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 60),
      child: Column(
        children: [
          buildPlayerTitleHeaderWithIndex(
            displayTitle: displayTitle,
            onOpenSettings: onOpenSettings,
            currentIndex: currentIndex,
            totalCount: totalCount,
          ),
          buildPlayerSeekTimeline(
            currentFilePath: currentFilePath,
            waveformLevels: waveformLevels,
            totalDurationSec: totalDurationSec,
            seekBarValue: seekBarValue,
            silenceTriggersSec: silenceTriggersSec,
            isPremiumUser: isPremiumUser,
            skipTargetChapters: skipTargetChapters,
            isAnalyzingSilence: isAnalyzingSilence,
            formatTimelineTime: formatTimelineTime,
            onRegisterTapOpportunity: onRegisterSeekbarTapOpportunity,
            onPreviewSeek: onPreviewSeek,
            onCommitSeek: onCommitSeek,
            onSeekPanCancel: onSeekPanCancel,
            onToggleSkipTarget: onToggleSkipTarget,
            waveformLevelForBar: waveformLevelForBar,
            collectMusicRunsForRow: collectMusicRunsForRow,
            buildMusicNotesText: buildMusicNotesText,
          ),
          buildPlayerBottomControls(
            currentFilePath: currentFilePath,
            statusMessage: statusMessage,
            tr: tr,
            currentTimeText:
                '${formatTime(currentPositionSec)}/${formatTime(totalDurationSec)}',
            onDecreaseVolume: onDecreaseVolume,
            onIncreaseVolume: onIncreaseVolume,
            onPreviousChapterTap: onPreviousChapterTap,
            onSkipPreviousTrack: onSkipPreviousTrack,
            onTogglePlayPause: onTogglePlayPause,
            onStopPlayback: onStopPlayback,
            onNextChapterTap: onNextChapterTap,
            onSkipNextTrack: onSkipNextTrack,
            onIncreaseSpeed: onIncreaseSpeed,
            onDecreaseSpeed: onDecreaseSpeed,
            onOpenAudioFile: onOpenAudioFile,
            isPlaying: isPlaying,
            speedLabel: '${playbackSpeed.toStringAsFixed(2)}x',
            buildStatusContent: buildCenterStatusContent,
          ),
        ],
      ),
    ),
  );
}
