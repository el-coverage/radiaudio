import 'package:flutter/material.dart';

Widget buildAdBannerPlaceholder({
  required String placeholderText,
}) {
  return SafeArea(
    top: false,
    child: Container(
      height: 56,
      color: Colors.grey.shade900,
      alignment: Alignment.center,
      child: Text(
        placeholderText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}