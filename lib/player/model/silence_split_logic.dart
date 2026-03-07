class ParsedSilenceEvent {
  const ParsedSilenceEvent({
    required this.silenceEndSec,
    required this.silenceDurationSec,
  });

  final double silenceEndSec;
  final double silenceDurationSec;
}

final RegExp _silenceEndPattern = RegExp(
  r'silence_end:\s*([0-9]+(?:\.[0-9]+)?)\s*\|\s*silence_duration:\s*([0-9]+(?:\.[0-9]+)?)',
);

ParsedSilenceEvent? parseSilenceDetectLogLine(String line) {
  final match = _silenceEndPattern.firstMatch(line);
  if (match == null) return null;
  final endRaw = match.group(1);
  final durationRaw = match.group(2);
  final silenceEndSec = double.tryParse(endRaw ?? '');
  final silenceDurationSec = double.tryParse(durationRaw ?? '');
  if (silenceEndSec == null || silenceDurationSec == null) return null;
  if (!silenceEndSec.isFinite || silenceEndSec <= 0) return null;
  return ParsedSilenceEvent(
    silenceEndSec: silenceEndSec,
    silenceDurationSec: silenceDurationSec,
  );
}

bool shouldCreateChapterSplit({
  required double silenceDurationSec,
  required double segmentLenSec,
  required double chapterUnitSec,
  required double hardMinChapterSec,
  required double fixedMinSegmentSecForSilenceSplit,
  required double fixedMaxSegmentSecWithoutSplit,
}) {
  if (segmentLenSec < hardMinChapterSec) return false;
  return ((silenceDurationSec > chapterUnitSec &&
          segmentLenSec > fixedMinSegmentSecForSilenceSplit) ||
      segmentLenSec > fixedMaxSegmentSecWithoutSplit);
}

bool isDuplicateSplitTrigger(
  List<double> splitTriggers,
  double silenceEndSec, {
  double tolerance = 0.001,
}) {
  if (splitTriggers.isEmpty) return false;
  return (silenceEndSec - splitTriggers.last).abs() < tolerance;
}