import 'dart:math' as math;
import 'dart:typed_data';

import 'package:radio_player_simple/player/model/music_interval.dart';
import 'package:radio_player_simple/player/model/player_constants.dart';

List<MusicInterval> detectMusicIntervalsFromPcm({
  required Uint8List pcmBytes,
  required double totalDurationSec,
}) {
  const sampleRate = 8000.0;
  final totalSamples = pcmBytes.length ~/ 2;
  if (totalSamples <= 0) return const [];

  final durationFromPcm = totalSamples / sampleRate;
  final resolvedDurationSec = math.max(totalDurationSec, durationFromPcm);
  if (resolvedDurationSec <= 0) return const [];

  final data = ByteData.sublistView(pcmBytes);
  final windows = <({double start, double end, bool music})>[];

  var startSec = 0.0;
  while (startSec < resolvedDurationSec) {
    final endSec =
        math.min(startSec + PlayerConstants.musicWindowSec, resolvedDurationSec);
    final durationSec = endSec - startSec;
    if (durationSec < 2.0) break;

    final startSample = (startSec * sampleRate).floor().clamp(0, totalSamples);
    final endSample = (endSec * sampleRate).floor().clamp(0, totalSamples);
    if (endSample - startSample < (sampleRate * 2).floor()) {
      startSec += PlayerConstants.musicHopSec;
      continue;
    }

    final isMusic = isLikelyMusicFromSamples(
      data: data,
      startSample: startSample,
      endSample: endSample,
      durationSec: durationSec,
    );
    windows.add((start: startSec, end: endSec, music: isMusic));
    startSec += PlayerConstants.musicHopSec;
  }

  if (windows.isEmpty) return const [];

  final merged = <MusicInterval>[];
  double? currentStart;
  double? currentEnd;

  for (final window in windows) {
    if (!window.music) {
      if (currentStart != null && currentEnd != null) {
        final length = currentEnd - currentStart;
        if (length >= PlayerConstants.musicMinIntervalSec) {
          merged.add(MusicInterval(startSec: currentStart, endSec: currentEnd));
        }
      }
      currentStart = null;
      currentEnd = null;
      continue;
    }

    if (currentStart == null) {
      currentStart = window.start;
      currentEnd = window.end;
      continue;
    }

    if (window.start <= currentEnd! + 0.8) {
      currentEnd = math.max(currentEnd, window.end);
    } else {
      final length = currentEnd - currentStart;
      if (length >= PlayerConstants.musicMinIntervalSec) {
        merged.add(MusicInterval(startSec: currentStart, endSec: currentEnd));
      }
      currentStart = window.start;
      currentEnd = window.end;
    }
  }

  if (currentStart != null && currentEnd != null) {
    final length = currentEnd - currentStart;
    if (length >= PlayerConstants.musicMinIntervalSec) {
      merged.add(MusicInterval(startSec: currentStart, endSec: currentEnd));
    }
  }

  return merged;
}

bool isLikelyMusicFromSamples({
  required ByteData data,
  required int startSample,
  required int endSample,
  required double durationSec,
}) {
  final sampleCount = endSample - startSample;
  if (sampleCount <= 1) return false;

  const targetPoints = 160000;
  final step = sampleCount > targetPoints ? (sampleCount ~/ targetPoints) : 1;

  var crossings = 0;
  var active = 0;
  var count = 0;
  var sumSq = 0.0;
  var prevSample = data.getInt16(startSample * 2, Endian.little);

  for (var i = startSample; i < endSample; i += step) {
    final sample = data.getInt16(i * 2, Endian.little);
    final absSample = sample.abs();
    if ((sample >= 0) != (prevSample >= 0)) {
      crossings++;
    }
    if (absSample >= 655) {
      active++;
    }
    sumSq += sample * sample;
    count++;
    prevSample = sample;
  }

  if (count <= 1) return false;

  final rms = math.sqrt(sumSq / count) / 32768.0;
  final activeRatio = active / count;
  final zcr = crossings / (count - 1);

  var score = 0.0;
  if (rms >= 0.05) {
    score += 1.0;
  } else if (rms < 0.02) {
    score -= 1.0;
  }

  if (activeRatio >= 0.78) {
    score += 1.0;
  } else if (activeRatio < 0.55) {
    score -= 1.0;
  }

  if (zcr >= 0.025 && zcr <= 0.16) {
    score += 0.5;
  } else if (zcr < 0.01 || zcr > 0.22) {
    score -= 0.5;
  }

  if (durationSec >= 20.0) {
    score += 0.5;
  }

  return score >= 1.5;
}