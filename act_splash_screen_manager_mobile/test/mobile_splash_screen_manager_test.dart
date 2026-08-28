// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_splash_screen_manager_core/act_splash_screen_manager_core.dart';
import 'package:act_splash_screen_manager_mobile/act_splash_screen_manager_mobile.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("MobileSplashScreenManager", () {
    test("is a splash screen manager", () {
      expect(MobileSplashScreenManager(), isA<AbsSplashScreenManager>());
    });

    testWidgets("holds the first frame back until the first view is built", (tester) async {
      final manager = MobileSplashScreenManager();

      await manager.initLifeCycle();

      expect(tester.binding.sendFramesToEngine, isFalse);

      await manager.initAfterView(_aContext(tester));

      expect(tester.binding.sendFramesToEngine, isTrue);
    });
  });

  group("MobileSplashScreenBuilder", () {
    test("depends on the logger manager", () {
      expect(const MobileSplashScreenBuilder().dependsOn(), [LoggerManager]);
    });

    test("builds the manager of the mobile applications", () {
      expect(const MobileSplashScreenBuilder().factory(), isA<MobileSplashScreenManager>());
    });
  });
}

/// Builds a view and returns its context.
BuildContext _aContext(WidgetTester tester) {
  tester.binding.attachRootWidget(const SizedBox());

  return tester.binding.rootElement!;
}
