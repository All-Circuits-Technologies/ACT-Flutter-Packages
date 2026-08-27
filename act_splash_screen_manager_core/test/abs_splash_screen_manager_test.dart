// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_splash_screen_manager_core/act_splash_screen_manager_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("AbsSplashScreenManager", () {
    test("is a manager which follows the life cycle of the views", () {
      expect(_SplashScreenManagerUnderTest(), isA<AbsWithLifeCycleAndUi>());
    });

    testWidgets("holds the first frame back when it is initialized", (tester) async {
      final manager = _SplashScreenManagerUnderTest();

      await manager.initLifeCycle();

      expect(tester.binding.sendFramesToEngine, isFalse);

      await manager.initAfterView(_aContext(tester));
    });

    testWidgets("lets the frames through once the first view is built", (tester) async {
      final manager = _SplashScreenManagerUnderTest();
      await manager.initLifeCycle();

      await manager.initAfterView(_aContext(tester));

      expect(tester.binding.sendFramesToEngine, isTrue);
    });

    testWidgets("removes the splash screen of the platform once the first view is built", (
      tester,
    ) async {
      final manager = _SplashScreenManagerUnderTest();
      await manager.initLifeCycle();

      expect(manager.hideCalls, 0);

      await manager.initAfterView(_aContext(tester));

      expect(manager.hideCalls, 1);
    });

    testWidgets("accepts to be initialized after the view without holding anything back", (
      tester,
    ) async {
      final manager = _SplashScreenManagerUnderTest();

      await expectLater(manager.initAfterView(_aContext(tester)), completes);
      expect(tester.binding.sendFramesToEngine, isTrue);
      expect(manager.hideCalls, 1);
    });
  });

  group("AbsSplashScreenBuilder", () {
    test("depends on the logger manager", () {
      expect(const _SplashScreenBuilderUnderTest().dependsOn(), [LoggerManager]);
    });

    test("builds the manager it is given", () {
      expect(const _SplashScreenBuilderUnderTest().factory(), isA<AbsSplashScreenManager>());
    });
  });
}

/// Manager counting how many times the splash screen of the platform has been removed.
class _SplashScreenManagerUnderTest extends AbsSplashScreenManager {
  /// Number of times [hideNativeSplashScreen] has been called.
  int hideCalls = 0;

  @override
  Future<void> hideNativeSplashScreen() async => hideCalls++;
}

/// Builder of the manager the tests are run on.
class _SplashScreenBuilderUnderTest extends AbsSplashScreenBuilder {
  const _SplashScreenBuilderUnderTest() : super(_SplashScreenManagerUnderTest.new);
}

/// Builds a view and returns its context.
BuildContext _aContext(WidgetTester tester) {
  tester.binding.attachRootWidget(const SizedBox());

  return tester.binding.rootElement!;
}
