List<String> buildPcmMono8000Args({
  required String audioPath,
  required String outputPath,
}) {
  return <String>[
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
    outputPath,
  ];
}

List<String> buildSilenceDetectArgs({
  required String audioPath,
  required double silenceNoiseDb,
  required double silenceDetectWindowSec,
}) {
  return <String>[
    '-hide_banner',
    '-i',
    audioPath,
    '-af',
    'silencedetect=noise=${silenceNoiseDb.toStringAsFixed(1)}dB:d=$silenceDetectWindowSec',
    '-f',
    'null',
    '-',
  ];
}