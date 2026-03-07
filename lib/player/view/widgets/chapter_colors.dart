import 'package:flutter/material.dart';

Color chapterColorForIndex(int chapterIndex, bool isPlayed) {
  const baseColors = <Color>[
    Color(0xFF1976D2),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFEF6C00),
    Color(0xFF00838F),
    Color(0xFFAD1457),
  ];
  final base = baseColors[chapterIndex % baseColors.length];
  return isPlayed ? base : Color.lerp(base, Colors.white, 0.45)!;
}
