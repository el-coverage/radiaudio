int chapterCountFromTriggers(List<double> silenceTriggersSec) {
  return silenceTriggersSec.isEmpty ? 1 : silenceTriggersSec.length + 1;
}

int chapterIndexForSec({
  required List<double> silenceTriggersSec,
  required double sec,
}) {
  var chapterIndex = 0;
  for (final triggerSec in silenceTriggersSec) {
    if (sec >= triggerSec) {
      chapterIndex++;
    } else {
      break;
    }
  }
  return chapterIndex;
}

double chapterStartSec({
  required List<double> silenceTriggersSec,
  required int chapterIndex,
  required double fallbackTotalDurationSec,
}) {
  if (chapterIndex <= 0) return 0.0;
  final triggerIndex = chapterIndex - 1;
  if (triggerIndex >= 0 && triggerIndex < silenceTriggersSec.length) {
    return silenceTriggersSec[triggerIndex];
  }
  return fallbackTotalDurationSec;
}
