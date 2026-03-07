import 'dart:async';

import 'package:flutter/material.dart';
import 'package:radio_player_simple/player/model/chapter_logic.dart';
import 'package:radio_player_simple/player/view/widgets/chapter_colors.dart';

typedef PreviewSeekFromLocalPosition = void Function({
  required Offset localPosition,
  required Size size,
  required int rows,
  required double durationSec,
});

typedef ToggleSkipTargetAtLocalPosition = Future<void> Function({
  required Offset localPosition,
  required Size size,
  required int rows,
  required double durationSec,
});

typedef CollectMusicRunsForRow = List<({int startBar, int endBar})> Function({
  required int row,
  required int barsPerRow,
  required double secPerBar,
});

Widget buildPlayerSeekTimeline({
  required String? currentFilePath,
  required List<double> waveformLevels,
  required double totalDurationSec,
  required double seekBarValue,
  required List<double> silenceTriggersSec,
  required bool isPremiumUser,
  required Set<int> skipTargetChapters,
  required bool isAnalyzingSilence,
  required String Function(double sec) formatTimelineTime,
  required Future<void> Function() onRegisterTapOpportunity,
  required PreviewSeekFromLocalPosition onPreviewSeek,
  required Future<void> Function() onCommitSeek,
  required VoidCallback onSeekPanCancel,
  required ToggleSkipTargetAtLocalPosition onToggleSkipTarget,
  required double Function(int barIndex, int totalBars) waveformLevelForBar,
  required CollectMusicRunsForRow collectMusicRunsForRow,
  required String Function(double maxWidth) buildMusicNotesText,
}) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double labelColumnWidth = 52;
          const double targetRowHeight = 44;
          final dynamicRows = (constraints.maxHeight / targetRowHeight).floor();
          final rows = dynamicRows.clamp(3, 12).toInt();
          final barsAreaWidth =
              (constraints.maxWidth - labelColumnWidth - 8).clamp(60.0, double.infinity);
          final dynamicBarsPerRow = (barsAreaWidth / 6).floor();
          final barsPerRow = dynamicBarsPerRow.clamp(8, 300).toInt();
          final hasWaveform = currentFilePath != null && waveformLevels.isNotEmpty;
          final rowSpanSec = totalDurationSec > 0 ? totalDurationSec / rows : 0.0;
          final effectiveDurationSec = totalDurationSec > 0 ? totalDurationSec : rows * 30.0;
          final seekProgressSec = seekBarValue.clamp(0.0, effectiveDurationSec);
          final totalBars = rows * barsPerRow;
          final secPerBar = effectiveDurationSec / totalBars;
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
                        unawaited(onRegisterTapOpportunity());
                        onPreviewSeek(
                          localPosition: details.localPosition,
                          size: barSize,
                          rows: rows,
                          durationSec: effectiveDurationSec,
                        );
                        unawaited(onCommitSeek());
                      },
                      onPanStart: (details) {
                        onPreviewSeek(
                          localPosition: details.localPosition,
                          size: barSize,
                          rows: rows,
                          durationSec: effectiveDurationSec,
                        );
                      },
                      onPanUpdate: (details) {
                        onPreviewSeek(
                          localPosition: details.localPosition,
                          size: barSize,
                          rows: rows,
                          durationSec: effectiveDurationSec,
                        );
                      },
                      onPanEnd: (_) {
                        unawaited(onCommitSeek());
                      },
                      onPanCancel: onSeekPanCancel,
                      onLongPressStart: (details) {
                        unawaited(
                          onToggleSkipTarget(
                            localPosition: details.localPosition,
                            size: barSize,
                            rows: rows,
                            durationSec: effectiveDurationSec,
                          ),
                        );
                      },
                      child: Column(
                        children: List.generate(rows, (row) {
                          final musicRuns = collectMusicRunsForRow(
                            row: row,
                            barsPerRow: barsPerRow,
                            secPerBar: secPerBar,
                          );

                          return Expanded(
                            child: Stack(
                              children: [
                                Row(
                                  children: List.generate(barsPerRow, (i) {
                                    final flatIndex = (row * barsPerRow) + i;
                                    final waveformLevel =
                                        waveformLevelForBar(flatIndex, totalBars);
                                    final barSec = (flatIndex + 1) * secPerBar;
                                    final double renderedHeight = hasWaveform
                                        ? (waveformLevel >= 0
                                            ? 4.0 + (waveformLevel * 41.0)
                                            : 0.0)
                                        : (currentFilePath == null ? 45.0 : 3.0);
                                    final isPlayed = barSec <= seekProgressSec;
                                    final chapterIndex = chapterIndexForSec(
                                      silenceTriggersSec: silenceTriggersSec,
                                      sec: barSec,
                                    );
                                    final isSkipTarget =
                                        isPremiumUser && skipTargetChapters.contains(chapterIndex);
                                    final displayedBarColor = isSkipTarget
                                        ? Colors.black
                                        : (isAnalyzingSilence
                                            ? (isPlayed
                                                ? chapterColorForIndex(chapterIndex, true)
                                                : Colors.blueGrey.shade300)
                                            : chapterColorForIndex(
                                                chapterIndex,
                                                isPlayed,
                                              ));

                                    return Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1,
                                        ),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Align(
                                              alignment: Alignment.bottomCenter,
                                              child: Container(
                                                height: renderedHeight,
                                                color: displayedBarColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                if (musicRuns.isNotEmpty)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: Stack(
                                        children: musicRuns.map((run) {
                                          final startBar = run.startBar;
                                          final endBar = run.endBar;
                                          final runBars = (endBar - startBar) + 1;
                                          final widthFactor = runBars / barsPerRow;
                                          final centerFactor =
                                              (startBar + (runBars / 2)) / barsPerRow;
                                          final alignX = (centerFactor * 2) - 1;

                                          return Align(
                                            alignment: Alignment(
                                              alignX,
                                              0,
                                            ),
                                            child: FractionallySizedBox(
                                              widthFactor: widthFactor,
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Center(
                                                    child: LayoutBuilder(
                                                      builder: (
                                                        context,
                                                        runConstraints,
                                                      ) {
                                                        final notes = buildMusicNotesText(
                                                          runConstraints.maxWidth,
                                                        );
                                                        return ClipRect(
                                                          child: Align(
                                                            alignment:
                                                                Alignment.centerLeft,
                                                            child: Text(
                                                              notes,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow.clip,
                                                              softWrap: false,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 11,
                                                                height: 1.0,
                                                                letterSpacing: -0.35,
                                                                color: Colors.black,
                                                                fontWeight:
                                                                    FontWeight.w900,
                                                                shadows: [
                                                                  Shadow(
                                                                    color:
                                                                        Colors.black54,
                                                                    blurRadius: 2,
                                                                    offset: Offset(
                                                                      0,
                                                                      1,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 0,
                                                    top: 0,
                                                    bottom: 0,
                                                    child: Container(
                                                      width: 2,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    right: 0,
                                                    top: 0,
                                                    bottom: 0,
                                                    child: Container(
                                                      width: 2,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(growable: false),
                                      ),
                                    ),
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
  );
}