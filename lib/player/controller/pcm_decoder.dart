import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:radio_player_simple/player/controller/ffmpeg_args_builder.dart';
import 'package:radio_player_simple/player/controller/windows_ffmpeg_helper.dart';

Future<Uint8List?> decodeAudioToPcmMono8000(String audioPath) async {
  final pcmFile = File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}radiaudio_music_${audioPath.hashCode.abs()}.pcm',
  );

  try {
    final args = buildPcmMono8000Args(
      audioPath: audioPath,
      outputPath: pcmFile.path,
    );
    if (Platform.isWindows) {
      final windowsFfmpegPath = await ensureWindowsBundledFfmpeg();
      if (windowsFfmpegPath != null) {
        await Process.run(windowsFfmpegPath, args);
      } else {
        final session = await FFmpegKit.executeWithArguments(args);
        final returnCode = await session.getReturnCode();
        if (returnCode != null && !ReturnCode.isSuccess(returnCode)) {
          return null;
        }
      }
    } else {
      final session = await FFmpegKit.executeWithArguments(args);
      final returnCode = await session.getReturnCode();
      if (returnCode != null && !ReturnCode.isSuccess(returnCode)) {
        return null;
      }
    }

    if (!await pcmFile.exists()) return null;
    return await pcmFile.readAsBytes();
  } catch (_) {
    return null;
  } finally {
    if (await pcmFile.exists()) {
      await pcmFile.delete();
    }
  }
}
