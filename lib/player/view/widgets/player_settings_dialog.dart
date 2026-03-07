// ...existing code...
import 'package:flutter/material.dart';
import 'package:radio_player_simple/player/model/player_settings_actions.dart';
import 'package:radio_player_simple/player/model/player_settings_model.dart';

Future<void> showPlayerSettingsDialog({
  required BuildContext context,
  required String Function(String, [Map<String, String>]) tr,
  required PlayerSettingsModel settings,
  required PlayerSettingsActions actions,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      String tempFolderPath = settings.defaultMusicFolderPath;
      double tempDefaultSpeed = settings.defaultPlaybackSpeed;
      double tempChapterUnitSec = settings.chapterUnitSec;
      String tempLanguageCode = settings.selectedLanguageCode;
      bool tempPreventAutoSleepDuringPlayback =
          settings.preventAutoSleepDuringPlayback;
      bool tempPremium = settings.isPremiumUser;
      DateTime? tempAdsDisabledUntil = settings.adsDisabledUntil;

      return StatefulBuilder(
        builder: (context, dialogSetState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tr('settings'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: tr('closeSettings'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(tr('language')),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: tempLanguageCode,
                          onChanged: (value) async {
                            if (value == null) return;
                            dialogSetState(() {
                              tempLanguageCode = value;
                            });
                            await actions.onLanguageChanged(value);
                          },
                          items: settings.supportedLanguageCodes
                              .map(
                                (code) => DropdownMenuItem<String>(
                                  value: code,
                                  child: Text(
                                    settings.languageDisplayNames[code] ?? code,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(tr('defaultFolder')),
                    subtitle: Text(
                      tempFolderPath.isEmpty
                          ? tr('unselected')
                          : tempFolderPath,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: () async {
                        final selectedPath =
                            await actions.onPickDefaultFolder(tempFolderPath);
                        if (selectedPath == null || selectedPath.isEmpty) {
                          return;
                        }
                        dialogSetState(() {
                          tempFolderPath = selectedPath;
                        });
                        await actions.onDefaultFolderChanged(selectedPath);
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr('defaultPlaybackSpeed')),
                      Text('${tempDefaultSpeed.toStringAsFixed(2)}x'),
                    ],
                  ),
                  Slider(
                    min: 0.25,
                    max: 3.0,
                    divisions: 11,
                    value: tempDefaultSpeed,
                    onChanged: (v) {
                      dialogSetState(() => tempDefaultSpeed = v);
                      actions.onDefaultSpeedChanged(v);
                    },
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(tr('chapterSplitSilenceLabel')),
                      ),
                      Text(
                        tr(
                          'secondsSuffix',
                          {'value': tempChapterUnitSec.toStringAsFixed(1)},
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    min: settings.minChapterUnitSec,
                    max: settings.maxChapterUnitSec,
                    divisions: ((settings.maxChapterUnitSec -
                                settings.minChapterUnitSec) *
                            10)
                        .round(),
                    value: tempChapterUnitSec,
                    onChanged: (v) {
                      dialogSetState(() => tempChapterUnitSec = v);
                      actions.onChapterUnitChanged(v);
                    },
                    onChangeEnd: (_) {
                      actions.onChapterUnitChangeEnd();
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('preventAutoSleepDuringPlaybackTitle')),
                    subtitle:
                        Text(tr('preventAutoSleepDuringPlaybackSubtitle')),
                    value: tempPreventAutoSleepDuringPlayback,
                    onChanged: (value) {
                      dialogSetState(() {
                        tempPreventAutoSleepDuringPlayback = value;
                      });
                      actions.onPreventAutoSleepChanged(value);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('premiumNoAdsTitle')),
                    subtitle: Text(tr('premiumNoAdsSubtitle')),
                    value: tempPremium,
                    onChanged: (value) async {
                      await actions.onPremiumChanged(value);
                      dialogSetState(() {
                        tempPremium = actions.getIsPremiumUser();
                        tempAdsDisabledUntil = actions.getAdsDisabledUntil();
                      });
                    },
                  ),
                  if (!settings.usesMockPremiumBilling)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          await actions.onRestorePremiumPurchases();
                          dialogSetState(() {
                            tempPremium = actions.getIsPremiumUser();
                            tempAdsDisabledUntil = actions.getAdsDisabledUntil();
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Restore purchases'),
                      ),
                    ),
                  if (!tempPremium)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tempAdsDisabledUntil != null &&
                                DateTime.now().isBefore(tempAdsDisabledUntil!)
                            ? tr('adFreeUntil', {
                                'until': '${tempAdsDisabledUntil!.toLocal()}',
                              })
                            : tr('adFreeRewardInactive'),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  if (!tempPremium)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          await actions.onWatchRewardAd();
                          dialogSetState(() {
                            tempAdsDisabledUntil = actions.getAdsDisabledUntil();
                          });
                        },
                        icon: const Icon(Icons.ondemand_video),
                        label: Text(tr('watchRewardAdLabel')),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
