import 'dart:math' as math;
import 'dart:typed_data';

List<double> extractAmplitudeLevelsFromPcm(
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