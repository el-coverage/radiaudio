import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const RadioMockApp());
}

class RadioMockApp extends StatelessWidget {
  const RadioMockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const PlayerScreen(),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  String currentTitle =
      "これはとても長いラジオ番組タイトルのサンプルです。高齢者でも読みやすいように3行固定表示します。256文字程度を想定しています。";

  int currentIndex = 1;
  int totalCount = 10;

  double currentPositionSec = 120;
  double totalDurationSec = 600;

  bool isPlaying = false;
  double playbackSpeed = 1.0;
  double defaultPlaybackSpeed = 1.0;
  String defaultMusicFolderPath = "";

  final Random _random = Random();

  void increaseSpeed() {
    setState(() {
      playbackSpeed += 0.25;
      if (playbackSpeed > 3.0) playbackSpeed = 0.25;
    });
  }

  /// チャプター移動 (前:forward=false, 次:forward=true)
  void skipChapter(bool forward) {
    setState(() {
      if (forward) {
        if (currentIndex < totalCount) currentIndex++;
      } else {
        if (currentIndex > 1) currentIndex--;
      }
      // reset position for demo purposes
      currentPositionSec = 0;
    });
    final text = forward ? '次チャプター' : '前チャプター';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  /// 曲移動 (長押し時に呼ばれる、前/次)
  void skipTrack(bool forward) {
    setState(() {
      // 本来はプレイリストやファイルリストを管理する
      if (forward) {
        if (currentIndex < totalCount) currentIndex++;
      } else {
        if (currentIndex > 1) currentIndex--;
      }
      currentPositionSec = 0;
    });
    final text = forward ? '次曲' : '前曲';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  void decreaseSpeed() {
    setState(() {
      playbackSpeed -= 0.25;
      if (playbackSpeed < 0.25) playbackSpeed = 3.0;
    });
  }

  void showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double tempDefaultSpeed = defaultPlaybackSpeed;
        String tempFolderPath = defaultMusicFolderPath;

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text("設定"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text("デフォルト音楽ファイルパス"),
                      subtitle: Text(
                        tempFolderPath.isEmpty ? "未選択" : tempFolderPath,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: () {
                          // TODO: file_selectorを使ってフォルダ選択
                          dialogSetState(() {
                            tempFolderPath = "/path/to/music"; // サンプル
                          });
                        },
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("デフォルト再生速度"),
                        Text("${tempDefaultSpeed.toStringAsFixed(2)}x"),
                      ],
                    ),
                    Slider(
                      min: 0.25,
                      max: 3.0,
                      divisions: 11,
                      value: tempDefaultSpeed,
                      onChanged: (v) {
                        dialogSetState(() => tempDefaultSpeed = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("キャンセル"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      defaultPlaybackSpeed = tempDefaultSpeed;
                      defaultMusicFolderPath = tempFolderPath;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("保存"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String formatTime(double sec) {
    int s = sec.toInt();
    int minutes = s ~/ 60;
    int seconds = s % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: Column(
            children: [

            // ===== タイトル + 設定 =====
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル（3行固定）
                  Expanded(
                    child: Text(
                      currentTitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),

                  // 設定ボタン
                  IconButton(
                    iconSize: 32,
                    onPressed: showSettingsDialog,
                    icon: const Icon(Icons.settings),
                  )
                ],
              ),
            ),

            // ===== シークバー領域 =====
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double width = constraints.maxWidth;
                    int barsPerRow = (width / 6).floor();
                    int rows = 6;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(rows, (row) {
                        return Expanded(
                          child: Row(
                            children: List.generate(barsPerRow, (i) {
                              double height =
                                  _random.nextDouble() * 40 + 5;

                              return Expanded(
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: height,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),

            // ===== インデックス + 時間 =====
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "$currentIndex/$totalCount    "
                "${formatTime(currentPositionSec)}/${formatTime(totalDurationSec)}",
                style: const TextStyle(fontSize: 18),
              ),
            ),

            // ===== 再生ボタン群 =====
            SizedBox(
              height: 70,
              child: Row(
                children: [
                  Expanded(
                    flex: 25,
                    child: Tooltip(
                      message: '前チャプター\n(長押しで前曲)',
                      child: ElevatedButton(
                        onPressed: () => skipChapter(false),
                        onLongPress: () => skipTrack(false),
                        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Icon(Icons.skip_previous, size: 40),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isPlaying = !isPlaying;
                        });
                      },
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: Colors.yellow.shade600),
                      child: Icon(
                        isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 50,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 25,
                    child: Tooltip(
                      message: '次チャプター\n(長押しで次曲)',
                      child: ElevatedButton(
                        onPressed: () => skipChapter(true),
                        onLongPress: () => skipTrack(true),
                        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Icon(Icons.skip_next, size: 40),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===== 速度 + 開く =====
            SizedBox(
              height: 60,
              child: Row(
                children: [
                  Expanded(
                    flex: 50,
                    child: Tooltip(
                      message: '+0.25x (長押しで-0.25x)',
                      child: ElevatedButton(
                        onPressed: increaseSpeed,
                        onLongPress: decreaseSpeed,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size.fromHeight(60),
                        ),
                        child: Text(
                          "${playbackSpeed.toStringAsFixed(2)}x",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size.fromHeight(60),
                      ),
                      child: const Icon(Icons.folder_open, size: 40),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}