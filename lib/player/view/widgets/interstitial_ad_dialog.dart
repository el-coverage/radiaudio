import 'package:flutter/material.dart';

Future<void> showInterstitialAdDialog({
  required BuildContext context,
  required String source,
  required String Function(String, [Map<String, String>]) tr,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog.fullscreen(
        child: SafeArea(
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                const Spacer(),
                Text(
                  tr('adLabel'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tr('interstitialAdPlaceholder', {'source': source}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(tr('closeAd')),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}