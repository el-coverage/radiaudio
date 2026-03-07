import 'package:radio_player_simple/player/model/music_interval.dart';

double waveformLevelForBar({
  required List<double> waveformLevels,
  required int barIndex,
  required int totalBars,
}) {
  if (waveformLevels.isEmpty || totalBars <= 0) return -1;
  final mappedIndex =
      ((barIndex / totalBars) * waveformLevels.length).floor().clamp(0, waveformLevels.length - 1);
  return waveformLevels[mappedIndex];
}

List<({int startBar, int endBar})> collectMusicRunsForRow({
  required int row,
  required int barsPerRow,
  required double secPerBar,
  required List<MusicInterval> musicIntervals,
}) {
  final runs = <({int startBar, int endBar})>[];
  int? runStartBar;

  for (var i = 0; i < barsPerRow; i++) {
    final flatIndex = (row * barsPerRow) + i;
    final barCenterSec = (flatIndex + 0.5) * secPerBar;
    final isMusicAtBar = _isInMusicInterval(
      sec: barCenterSec,
      musicIntervals: musicIntervals,
    );
    if (isMusicAtBar) {
      runStartBar ??= i;
    } else if (runStartBar != null) {
      runs.add((startBar: runStartBar, endBar: i - 1));
      runStartBar = null;
    }
  }

  if (runStartBar != null) {
    runs.add((startBar: runStartBar, endBar: barsPerRow - 1));
  }
  return runs;
}

String buildMusicNotesText(double maxWidth) {
  final noteCount = (maxWidth / 12).ceil().clamp(1, 22);
  return List.generate(
    noteCount,
    (index) => index.isEven ? '♪' : '♫',
  ).join();
}

bool _isInMusicInterval({
  required double sec,
  required List<MusicInterval> musicIntervals,
}) {
  for (final interval in musicIntervals) {
    if (sec >= interval.startSec && sec <= interval.endSec) {
      return true;
    }
  }
  return false;
}