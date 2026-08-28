// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_splash_screen_manager/act_splash_screen_manager.dart';
import 'package:act_splash_screen_manager_mobile/act_splash_screen_manager_mobile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("SplashScreenBuilder", () {
    test("depends on the logger manager", () {
      expect(const SplashScreenBuilder().dependsOn(), [LoggerManager]);
    });

    test("builds the manager of the mobile applications", () {
      expect(const SplashScreenBuilder().factory(), isA<MobileSplashScreenManager>());
    });
  });
}
