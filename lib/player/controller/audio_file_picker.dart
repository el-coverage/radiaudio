import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:radio_player_simple/player/model/player_constants.dart';
import 'package:radio_player_simple/player/utils/path_utils.dart';

Future<XFile?> pickAudioFile({
  String? initialDirectory,
}) {
  const audioTypeGroup = XTypeGroup(
    label: 'audio',
    extensions: ['mp3', 'wav', 'm4a', 'aac', 'flac', 'ogg', 'opus'],
  );

  return openFile(
    acceptedTypeGroups: [audioTypeGroup],
    initialDirectory: initialDirectory,
  );
}

Future<List<String>> loadAudioFilesInSameFolder(String selectedPath) async {
  final folderPath = directoryPathFromPath(selectedPath);
  if (folderPath == null) return [selectedPath];

  if (Platform.isAndroid || Platform.isIOS) {
    return [selectedPath];
  }

  final directory = Directory(folderPath);
  if (!await directory.exists()) return [selectedPath];

  final files = <String>[];
  await for (final entity in directory.list(followLinks: false)) {
    if (entity is! File) continue;
    final path = entity.path;
    if (!_isAudioFilePath(path)) continue;
    files.add(path);
  }

  files.sort((a, b) {
    final aName = fileNameFromPath(a).toLowerCase();
    final bName = fileNameFromPath(b).toLowerCase();
    return aName.compareTo(bName);
  });

  if (files.isEmpty) {
    return [selectedPath];
  }
  return files;
}

bool _isAudioFilePath(String path) {
  final fileName = fileNameFromPath(path);
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex < 0 || dotIndex == fileName.length - 1) return false;
  final ext = fileName.substring(dotIndex + 1).toLowerCase();
  return PlayerConstants.audioExtensions.contains(ext);
}