import 'dart:io';

import 'package:ffmpeg_helper/ffmpeg_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<String?> ensureWindowsBundledFfmpeg() async {
  if (!Platform.isWindows) return null;
  try {
    await FFMpegHelper.instance.initialize();
    final isPresent = await FFMpegHelper.instance.isFFMpegPresent();
    if (!isPresent) {
      final setupOk = await FFMpegHelper.instance.setupFFMpegOnWindows();
      if (!setupOk) return null;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final appDocDir = await getApplicationDocumentsDirectory();
    final ffmpegPath = path.join(
      appDocDir.path,
      packageInfo.appName,
      'ffmpeg',
      'ffmpeg-master-latest-win64-gpl',
      'bin',
      'ffmpeg.exe',
    );
    final ffmpegFile = File(ffmpegPath);
    if (!await ffmpegFile.exists()) {
      return null;
    }
    return ffmpegPath;
  } catch (_) {
    return null;
  }
}
