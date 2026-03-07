import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:radio_player_simple/player/controller/ffmpeg_args_builder.dart';
import 'package:radio_player_simple/player/controller/windows_ffmpeg_helper.dart';

class SilenceDetectRunResult {
  const SilenceDetectRunResult({
    required this.ffmpegKitSucceededOrCanceled,
  });

  final bool ffmpegKitSucceededOrCanceled;
}

Future<SilenceDetectRunResult> runSilenceDetectAndFeedLines({
  required String audioPath,
  required double silenceNoiseDb,
  required double silenceDetectWindowSec,
  required void Function(String line) onLogLine,
}) async {
  final args = buildSilenceDetectArgs(
    audioPath: audioPath,
    silenceNoiseDb: silenceNoiseDb,
    silenceDetectWindowSec: silenceDetectWindowSec,
  );

  if (Platform.isWindows) {
    final windowsFfmpegPath = await ensureWindowsBundledFfmpeg();
    var windowsProcessSuccess = false;
    if (windowsFfmpegPath != null) {
      try {
        final process = await Process.start(windowsFfmpegPath, args);

        final stderrTask = process.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach(onLogLine);
        final stdoutTask = process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach(onLogLine);

        await Future.wait([stderrTask, stdoutTask]);
        await process.exitCode;
        windowsProcessSuccess = true;
      } catch (_) {
        windowsProcessSuccess = false;
      }
    }

    if (windowsProcessSuccess) {
      return const SilenceDetectRunResult(
        ffmpegKitSucceededOrCanceled: true,
      );
    }
  }

  final session = await FFmpegKit.executeWithArgumentsAsync(
    args,
    null,
    (dynamic log) {
      final message = log?.getMessage()?.toString() ?? '';
      if (message.isEmpty) return;
      onLogLine(message);
    },
  );
  final returnCode = await session.getReturnCode();
  final successOrCanceled = returnCode == null ||
      ReturnCode.isSuccess(returnCode) ||
      ReturnCode.isCancel(returnCode);

  final output =
      (await session.getAllLogsAsString()) ?? (await session.getOutput()) ?? '';
  for (final line in output.split(RegExp(r'\r?\n'))) {
    onLogLine(line);
  }

  return SilenceDetectRunResult(
    ffmpegKitSucceededOrCanceled: successOrCanceled,
  );
}
