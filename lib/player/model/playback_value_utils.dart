int increaseVolumeLevel(
  int current, {
  required int min,
  required int max,
}) {
  if (current >= max) return max;
  final next = current + 1;
  if (next < min) return min;
  if (next > max) return max;
  return next;
}

int decreaseVolumeLevel(
  int current, {
  required int min,
  required int max,
}) {
  if (current <= min) return min;
  final next = current - 1;
  if (next < min) return min;
  if (next > max) return max;
  return next;
}

double increasePlaybackSpeedCycle(
  double current, {
  double min = 0.25,
  double max = 3.0,
  double step = 0.25,
}) {
  final next = current + step;
  if (next > max) return min;
  return next;
}

double decreasePlaybackSpeedCycle(
  double current, {
  double min = 0.25,
  double max = 3.0,
  double step = 0.25,
}) {
  final next = current - step;
  if (next < min) return max;
  return next;
}
