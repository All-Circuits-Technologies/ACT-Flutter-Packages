// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_splash_screen_manager/act_splash_screen_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("SplashScreenManager", () {
    test("is a manager which follows the life cycle of the views", () {
      expect(SplashScreenManager(), isA<AbsWithLifeCycleAndUi>());
    });

    testWidgets("holds the first frame back when it is initialized", (tester) async {
      final manager = SplashScreenManager();

      await manager.initLifeCycle();

      expect(tester.binding.sendFramesToEngine, isFalse);

      await manager.initAfterView(_aContext(tester));
    });

    testWidgets("lets the frames through once the first view is built", (tester) async {
      final manager = SplashScreenManager();
      await manager.initLifeCycle();

      await manager.initAfterView(_aContext(tester));

      expect(tester.binding.sendFramesToEngine, isTrue);
    });

    testWidgets("accepts to be initialized after the view without holding anything back", (
      tester,
    ) async {
      final manager = SplashScreenManager();

      await expectLater(manager.initAfterView(_aContext(tester)), completes);
      expect(tester.binding.sendFramesToEngine, isTrue);
    });
  });

  group("SplashScreenBuilder", () {
    test("depends on the logger manager", () {
      expect(SplashScreenBuilder().dependsOn(), [LoggerManager]);
    });

    test("builds a splash screen manager", () {
      expect(SplashScreenBuilder().factory(), isA<SplashScreenManager>());
    });
  });
}

/// Builds a view and returns its context.
BuildContext _aContext(WidgetTester tester) {
  tester.binding.attachRootWidget(const SizedBox());

  return tester.binding.rootElement!;
}
