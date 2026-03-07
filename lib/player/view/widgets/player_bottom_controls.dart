import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Widget buildPlayerBottomControls({
  required String? currentFilePath,
  required ValueListenable<String> statusMessage,
  required String Function(String, [Map<String, String>]) tr,
  required String currentTimeText,
  required VoidCallback onDecreaseVolume,
  required VoidCallback onIncreaseVolume,
  required VoidCallback onPreviousChapterTap,
  required VoidCallback onSkipPreviousTrack,
  required VoidCallback onTogglePlayPause,
  required VoidCallback onStopPlayback,
  required VoidCallback onNextChapterTap,
  required VoidCallback onSkipNextTrack,
  required VoidCallback onIncreaseSpeed,
  required VoidCallback onDecreaseSpeed,
  required VoidCallback onOpenAudioFile,
  required bool isPlaying,
  required String speedLabel,
  required Widget Function() buildStatusContent,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              flex: 25,
              child: SizedBox(
                height: 60,
                child: Tooltip(
                  message: tr('volumeDown'),
                  child: ElevatedButton(
                    onPressed: onDecreaseVolume,
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Icon(Icons.volume_down, size: 38),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 50,
              child: SizedBox(
                height: 60,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      currentTimeText,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 25,
              child: SizedBox(
                height: 60,
                child: Tooltip(
                  message: tr('volumeUp'),
                  child: ElevatedButton(
                    onPressed: onIncreaseVolume,
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Icon(Icons.volume_up, size: 38),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(
        height: 22,
        child: ValueListenableBuilder<String>(
          valueListenable: statusMessage,
          builder: (context, _, __) {
            if (currentFilePath == null) {
              return Text(
                tr('pleaseSelectAudioFile'),
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              );
            }
            return buildStatusContent();
          },
        ),
      ),
      SizedBox(
        height: 70,
        child: Row(
          children: [
            Expanded(
              flex: 25,
              child: Tooltip(
                message: tr('chapterPrevTooltip'),
                child: ElevatedButton(
                  onPressed: onPreviousChapterTap,
                  onLongPress: onSkipPreviousTrack,
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Icon(Icons.skip_previous, size: 40),
                ),
              ),
            ),
            Expanded(
              flex: 50,
              child: Tooltip(
                message: tr('playTooltip'),
                child: ElevatedButton(
                  onPressed: onTogglePlayPause,
                  onLongPress: onStopPlayback,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.yellow.shade600,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 50,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 25,
              child: Tooltip(
                message: tr('chapterNextTooltip'),
                child: ElevatedButton(
                  onPressed: onNextChapterTap,
                  onLongPress: onSkipNextTrack,
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Icon(Icons.skip_next, size: 40),
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(
        height: 60,
        child: Row(
          children: [
            Expanded(
              flex: 50,
              child: Tooltip(
                message: tr('speedTooltip'),
                child: ElevatedButton(
                  onPressed: onIncreaseSpeed,
                  onLongPress: onDecreaseSpeed,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.fromHeight(60),
                  ),
                  child: Text(
                    speedLabel,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 50,
              child: ElevatedButton(
                onPressed: onOpenAudioFile,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size.fromHeight(60),
                ),
                child: const Icon(Icons.folder_open, size: 40),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}