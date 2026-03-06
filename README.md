# radiaudio

A new Flutter project.

## Platform Support Policy

- Android: `minSdk 24` (Android 7.0+), target SDK follows Flutter default (`36` currently).
- iOS: `iOS 13.0+`.
- Windows: `Windows 10/11` (desktop).

Runtime notes:

- Android: external `ffmpeg` install is not required.
- iOS: external `ffmpeg` install is not required.
- Windows: `ffmpeg.exe` must be resolvable from `PATH` for silence/waveform analysis features.
	Playback itself works without it, but analysis-driven features are limited.

Build environment notes:

- Android build: Windows/macOS/Linux + Flutter SDK + Android SDK + JDK 17.
- Windows build: Windows + Flutter SDK + Visual Studio C++ toolchain.
- iOS build: macOS + Flutter SDK + Xcode (cannot be built on Windows host).

Source of truth:

- Android min/target SDK are inherited from Flutter defaults via `android/app/build.gradle.kts` (`flutter.minSdkVersion`, `flutter.targetSdkVersion`).
- Current Flutter SDK default values are `minSdkVersion=24`, `targetSdkVersion=36` (`C:\flutter\packages\flutter_tools\gradle\src\main\kotlin\FlutterExtension.kt`).
- iOS deployment target is `13.0` (`ios/Runner.xcodeproj/project.pbxproj`) and `MinimumOSVersion` is `13.0` (`ios/Flutter/AppFrameworkInfo.plist`).
- Windows compatibility is declared for Windows 10/11 (`windows/runner/runner.exe.manifest`).

## Verification Status (2026-03-06)

- `flutter analyze`: passed.
- `flutter build windows`: passed (`build/windows/x64/runner/Release/radiaudio.exe`).
- `flutter build apk --debug`: passed (`build/app/outputs/flutter-apk/app-debug.apk`).
- iOS build cannot be executed on this Windows host with current Flutter toolchain (no iOS build subcommand available here).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
