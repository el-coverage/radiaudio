String formatTime(double sec) {
  final wholeSeconds = sec.toInt();
  final minutes = wholeSeconds ~/ 60;
  final seconds = wholeSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String formatTimelineTime(double sec) {
  final safeSec = sec.isFinite ? sec : 0;
  final totalSeconds = safeSec < 0 ? 0 : safeSec.floor();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
