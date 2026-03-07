import 'package:radio_player_simple/player/model/silence_split_logic.dart';

class SilenceSplitCollector {
  SilenceSplitCollector({
    required this.chapterUnitSec,
    required this.hardMinChapterSec,
    required this.fixedMinSegmentSecForSilenceSplit,
    required this.fixedMaxSegmentSecWithoutSplit,
  });

  final double chapterUnitSec;
  final double hardMinChapterSec;
  final double fixedMinSegmentSecForSilenceSplit;
  final double fixedMaxSegmentSecWithoutSplit;

  final List<double> _splitTriggers = <double>[];
  double _termStartSec = 0.0;

  List<double> get splitTriggers => _splitTriggers;

  bool processLogLine(String line) {
    final parsed = parseSilenceDetectLogLine(line);
    if (parsed == null) return false;
    final silenceEndSec = parsed.silenceEndSec;
    final silenceDurationSec = parsed.silenceDurationSec;

    final segmentLenSec = silenceEndSec - _termStartSec;
    final shouldSplit = shouldCreateChapterSplit(
      silenceDurationSec: silenceDurationSec,
      segmentLenSec: segmentLenSec,
      chapterUnitSec: chapterUnitSec,
      hardMinChapterSec: hardMinChapterSec,
      fixedMinSegmentSecForSilenceSplit: fixedMinSegmentSecForSilenceSplit,
      fixedMaxSegmentSecWithoutSplit: fixedMaxSegmentSecWithoutSplit,
    );
    if (!shouldSplit) return false;

    if (isDuplicateSplitTrigger(_splitTriggers, silenceEndSec)) {
      return false;
    }

    _splitTriggers.add(silenceEndSec);
    _termStartSec = silenceEndSec;
    return true;
  }
}
