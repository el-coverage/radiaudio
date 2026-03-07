import 'dart:ui';

double seekSecFromLocalPosition({
  required Offset localPosition,
  required Size size,
  required int rows,
  required double durationSec,
}) {
  final safeWidth = size.width <= 0 ? 1.0 : size.width;
  final safeHeight = size.height <= 0 ? 1.0 : size.height;
  final x = localPosition.dx.clamp(0.0, safeWidth);
  final y = localPosition.dy.clamp(0.0, safeHeight);

  final rowHeight = safeHeight / rows;
  final rowIndex = (y / rowHeight).floor().clamp(0, rows - 1);
  final rowProgress = (x / safeWidth).clamp(0.0, 1.0);
  final rowSpanSec = durationSec / rows;
  final seekSec = (rowIndex * rowSpanSec) + (rowProgress * rowSpanSec);
  return seekSec.clamp(0.0, durationSec);
}
