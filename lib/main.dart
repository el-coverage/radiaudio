import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const RadioMockApp());
}

class RadioMockApp extends StatelessWidget {
  const RadioMockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
      locale: const Locale('ja', 'JP'),
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

  final Random _random = Random();

  void increaseSpeed() {
    setState(() {
      playbackSpeed += 0.25;
      if (playbackSpeed > 3.0) playbackSpeed = 0.25;
    });
  }

  void decreaseSpeed() {
    setState(() {
      playbackSpeed -= 0.25;
      if (playbackSpeed < 0.25) playbackSpeed = 3.0;
    });
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
                    onPressed: () {},
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
              height: 90,
              child: Row(
                children: [
                  Expanded(
                    flex: 25,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Icon(Icons.skip_previous, size: 40),
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
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Icon(Icons.skip_next, size: 40),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ===== 速度 + 開く =====
            SizedBox(
              height: 80,
              child: Row(
                children: [
                  Expanded(
                    flex: 50,
                    child: GestureDetector(
                      onTap: increaseSpeed,
                      onLongPress: decreaseSpeed,
                      child: Container(
                        alignment: Alignment.center,
                        color: Colors.orange.shade200,
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
                      child: const Icon(Icons.folder_open, size: 40),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}