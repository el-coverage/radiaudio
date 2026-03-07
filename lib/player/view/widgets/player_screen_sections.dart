import 'package:flutter/material.dart';

Widget buildPlayerTitleHeaderWithIndex({
  required String displayTitle,
  required VoidCallback onOpenSettings,
  required int currentIndex,
  required int totalCount,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$currentIndex/$totalCount',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            displayTitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ),
        IconButton(
          iconSize: 32,
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings),
        ),
      ],
    ),
  );
}


Widget buildPlayerTitleHeader({
  required String displayTitle,
  required VoidCallback onOpenSettings,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            displayTitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ),
        IconButton(
          iconSize: 32,
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings),
        ),
      ],
    ),
  );
}

Widget buildPlayerCenterStatus({
  required String compactFileInfo,
  required Color chapterColor,
  required String silenceInfo,
  required String compactVolumeInfo,
}) {
  return Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            compactFileInfo,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: chapterColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            silenceInfo,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            compactVolumeInfo,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    ),
  );
}
