// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_splash_screen_manager/act_splash_screen_manager.dart';
import 'package:act_splash_screen_manager/src/platforms/desktop_splash_screen_manager.dart';
import 'package:act_splash_screen_manager/src/platforms/mobile_splash_screen_manager.dart';
import 'package:act_splash_screen_manager/src/platforms/web_splash_screen_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("SplashScreenBuilder", () {
    test("depends on the logger manager", () {
      expect(const SplashScreenBuilder().dependsOn(), [LoggerManager]);
    });

    test("builds the manager the platform of the application needs", () {
      expect(
        SplashScreenBuilder.managerForPlatform(const _APlatform(isLinux: true)),
        isA<DesktopSplashScreenManager>(),
      );
    });
  });

  group("SplashScreenBuilder.managerForPlatform", () {
    test("asks the page on the web", () {
      expect(
        SplashScreenBuilder.managerForPlatform(const _APlatform(isWeb: true)),
        isA<WebSplashScreenManager>(),
      );
    });

    test("asks the runner on Linux and on Windows", () {
      expect(
        SplashScreenBuilder.managerForPlatform(const _APlatform(isLinux: true)),
        isA<DesktopSplashScreenManager>(),
      );
      expect(
        SplashScreenBuilder.managerForPlatform(const _APlatform(isWindows: true)),
        isA<DesktopSplashScreenManager>(),
      );
    });

    test("asks nothing on Android and on iOS, where the platform removes its splash screen", () {
      expect(
        SplashScreenBuilder.managerForPlatform(const _APlatform(isAndroid: true)),
        isA<MobileSplashScreenManager>(),
      );
      expect(
        SplashScreenBuilder.managerForPlatform(const _APlatform(isIos: true)),
        isA<MobileSplashScreenManager>(),
      );
    });

    test("asks nothing on the platforms which draw no splash screen", () {
      expect(
        SplashScreenBuilder.managerForPlatform(const _APlatform(isMacOS: true)),
        isA<MobileSplashScreenManager>(),
      );
      expect(
        SplashScreenBuilder.managerForPlatform(const _APlatform(isFuchsia: true)),
        isA<MobileSplashScreenManager>(),
      );
    });
  });
}

/// Platform the tests choose, instead of the one they run on.
class _APlatform with MixinActPlatforms {
  @override
  final bool isAndroid;

  @override
  final bool isFuchsia;

  @override
  final bool isIos;

  @override
  final bool isLinux;

  @override
  final bool isMacOS;

  @override
  final bool isWeb;

  @override
  final bool isWindows;

  @override
  Map<String, String> get environment => const {};

  /// Class constructor
  const _APlatform({
    this.isAndroid = false,
    this.isFuchsia = false,
    this.isIos = false,
    this.isLinux = false,
    this.isMacOS = false,
    this.isWeb = false,
    this.isWindows = false,
  });
}
