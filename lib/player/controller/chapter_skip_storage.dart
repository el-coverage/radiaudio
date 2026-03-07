import 'package:radio_player_simple/player/model/player_constants.dart';
import 'package:radio_player_simple/player/utils/path_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

String buildSkipTargetStorageKey({
  required String filePath,
  required double chapterUnitSec,
}) {
  final normalizedUnit = chapterUnitSec.toStringAsFixed(1);
  return '${PlayerConstants.prefSkipTargetPrefix}${normalizedPathKey(filePath)}::u=$normalizedUnit';
}

Future<Set<int>> loadSkipTargetChaptersForTrack({
  required String filePath,
  required double chapterUnitSec,
  required int maxChapterIndex,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final key = buildSkipTargetStorageKey(
    filePath: filePath,
    chapterUnitSec: chapterUnitSec,
  );
  final rawList = prefs.getStringList(key) ?? const <String>[];
  return rawList
      .map((value) => int.tryParse(value))
      .whereType<int>()
      .where((index) => index >= 0 && index <= maxChapterIndex)
      .toSet();
}

Future<void> saveSkipTargetChaptersForTrack({
  required String filePath,
  required double chapterUnitSec,
  required Set<int> skipTargetChapters,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final key = buildSkipTargetStorageKey(
    filePath: filePath,
    chapterUnitSec: chapterUnitSec,
  );
  final values = skipTargetChapters.toList(growable: false)..sort();
  await prefs.setStringList(
    key,
    values.map((value) => value.toString()).toList(growable: false),
  );
}
