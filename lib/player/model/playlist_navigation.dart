import 'package:radio_player_simple/player/utils/path_utils.dart';

enum TrackSkipMessage {
  nextTrack,
  prevTrack,
  firstFile,
  lastFile,
}

String trackSkipMessageLocalizationKey(TrackSkipMessage message) {
  switch (message) {
    case TrackSkipMessage.nextTrack:
      return 'nextTrack';
    case TrackSkipMessage.prevTrack:
      return 'prevTrack';
    case TrackSkipMessage.firstFile:
      return 'firstFile';
    case TrackSkipMessage.lastFile:
      return 'lastFile';
  }
}

class TrackSkipDecision {
  const TrackSkipDecision({
    required this.moved,
    required this.message,
    required this.updatedCurrentIndex,
    required this.updatedTotalCount,
    this.nextFilePath,
    this.nextTitle,
  });

  final bool moved;
  final TrackSkipMessage message;
  final int updatedCurrentIndex;
  final int updatedTotalCount;
  final String? nextFilePath;
  final String? nextTitle;
}

TrackSkipDecision decideTrackSkip({
  required bool forward,
  required List<String> folderAudioFiles,
  required String? currentFilePath,
  required int currentIndex,
  required int totalCount,
}) {
  final defaultMessage =
      forward ? TrackSkipMessage.nextTrack : TrackSkipMessage.prevTrack;

  if (folderAudioFiles.isNotEmpty && currentFilePath != null) {
    final currentPathLower = normalizedPathKey(currentFilePath);
    final currentPos = folderAudioFiles.indexWhere(
      (path) => normalizedPathKey(path) == currentPathLower,
    );

    if (currentPos >= 0) {
      if (forward && currentPos >= folderAudioFiles.length - 1) {
        return TrackSkipDecision(
          moved: false,
          message: TrackSkipMessage.lastFile,
          updatedCurrentIndex: currentIndex,
          updatedTotalCount: totalCount,
        );
      }
      if (!forward && currentPos <= 0) {
        return TrackSkipDecision(
          moved: false,
          message: TrackSkipMessage.firstFile,
          updatedCurrentIndex: currentIndex,
          updatedTotalCount: totalCount,
        );
      }

      final nextPos = forward ? currentPos + 1 : currentPos - 1;
      final nextPath = folderAudioFiles[nextPos];
      return TrackSkipDecision(
        moved: true,
        message: defaultMessage,
        updatedCurrentIndex: nextPos + 1,
        updatedTotalCount: folderAudioFiles.length,
        nextFilePath: nextPath,
        nextTitle: fileNameFromPath(nextPath),
      );
    }

    return TrackSkipDecision(
      moved: false,
      message: defaultMessage,
      updatedCurrentIndex: currentIndex,
      updatedTotalCount: totalCount,
    );
  }

  var nextCurrentIndex = currentIndex;
  if (forward) {
    if (nextCurrentIndex < totalCount) nextCurrentIndex++;
  } else {
    if (nextCurrentIndex > 1) nextCurrentIndex--;
  }

  final message = nextCurrentIndex == currentIndex
      ? (forward ? TrackSkipMessage.lastFile : TrackSkipMessage.firstFile)
      : defaultMessage;

  return TrackSkipDecision(
    moved: false,
    message: message,
    updatedCurrentIndex: nextCurrentIndex,
    updatedTotalCount: totalCount,
  );
}

class SelectedTrackResolution {
  const SelectedTrackResolution({
    required this.resolvedIndex,
    required this.resolvedPath,
    required this.resolvedTitle,
  });

  final int resolvedIndex;
  final String resolvedPath;
  final String resolvedTitle;
}

SelectedTrackResolution resolveSelectedTrackInFolder({
  required List<String> files,
  required String selectedPath,
}) {
  final selectedPathLower = normalizedPathKey(selectedPath);
  final selectedIndex = files.indexWhere(
    (path) => normalizedPathKey(path) == selectedPathLower,
  );
  final resolvedIndex = selectedIndex >= 0 ? selectedIndex : 0;
  final resolvedPath = files[resolvedIndex];
  return SelectedTrackResolution(
    resolvedIndex: resolvedIndex,
    resolvedPath: resolvedPath,
    resolvedTitle: fileNameFromPath(resolvedPath),
  );
}
