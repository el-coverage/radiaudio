import 'package:radio_player_simple/player/controller/pcm_decoder.dart';
import 'package:radio_player_simple/player/model/music_detection_logic.dart';
import 'package:radio_player_simple/player/model/music_interval.dart';
import 'package:radio_player_simple/player/model/waveform_logic.dart';

Future<List<double>?> analyzeWaveformLevels({
  required String audioPath,
  int targetBins = 2400,
}) async {
  final pcmBytes = await decodeAudioToPcmMono8000(audioPath);
  if (pcmBytes == null || pcmBytes.isEmpty) {
    return null;
  }

  return extractAmplitudeLevelsFromPcm(pcmBytes, targetBins: targetBins);
}

Future<List<MusicInterval>?> analyzeMusicIntervals({
  required String audioPath,
  required double totalDurationSec,
}) async {
  final pcmBytes = await decodeAudioToPcmMono8000(audioPath);
  if (pcmBytes == null || pcmBytes.isEmpty) {
    return null;
  }

  return detectMusicIntervalsFromPcm(
    pcmBytes: pcmBytes,
    totalDurationSec: totalDurationSec,
  );
}