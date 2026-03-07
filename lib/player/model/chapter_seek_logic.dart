class ChapterSeekResolution {
  const ChapterSeekResolution({
    required this.targetSec,
    this.failureLocalizationKey,
  });

  final double? targetSec;
  final String? failureLocalizationKey;
}

ChapterSeekResolution resolveChapterSeekTarget({
  required bool forward,
  required List<double> silenceTriggersSec,
  required double currentSec,
  int backwardSteps = 1,
  double seekToleranceSec = 0.02,
  double rewindToStartThresholdSec = 0.2,
}) {
  double? targetSec;

  if (forward) {
    for (final triggerSec in silenceTriggersSec) {
      if (triggerSec > currentSec + seekToleranceSec) {
        targetSec = triggerSec;
        break;
      }
    }
    if (targetSec == null) {
      return const ChapterSeekResolution(
        targetSec: null,
        failureLocalizationKey: 'lastChapter',
      );
    }
    return ChapterSeekResolution(targetSec: targetSec);
  }

  final stepsToMove = backwardSteps < 1 ? 1 : backwardSteps;
  var matchedCount = 0;
  for (var i = silenceTriggersSec.length - 1; i >= 0; i--) {
    final triggerSec = silenceTriggersSec[i];
    if (triggerSec < currentSec - seekToleranceSec) {
      matchedCount++;
      if (matchedCount >= stepsToMove) {
        targetSec = triggerSec;
        break;
      }
    }
  }

  if (targetSec == null) {
    if (currentSec > rewindToStartThresholdSec) {
      targetSec = 0;
    } else {
      return const ChapterSeekResolution(
        targetSec: null,
        failureLocalizationKey: 'firstChapter',
      );
    }
  }
  return ChapterSeekResolution(targetSec: targetSec);
}