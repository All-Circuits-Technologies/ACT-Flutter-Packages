// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_splash_screen_manager_core/act_splash_screen_manager_core.dart';
import 'package:act_splash_screen_manager_desktop/act_splash_screen_manager_desktop.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("DesktopSplashScreenManager", () {
    test("is a splash screen manager", () {
      expect(DesktopSplashScreenManager(), isA<AbsSplashScreenManager>());
    });

    testWidgets("asks the runner of the application to remove the splash screen", (tester) async {
      final calls = <String>[];
      _answerTheRunner(tester, calls.add);
      final manager = DesktopSplashScreenManager(logger: const SilentLogger());
      await manager.initLifeCycle();

      await manager.initAfterView(_aContext(tester));

      expect(calls, ["hide"]);
      expect(tester.binding.sendFramesToEngine, isTrue);
    });

    testWidgets("starts the application anyway when the runner draws no splash screen", (
      tester,
    ) async {
      _answerTheRunner(tester, null);
      final logger = FakeLogger();
      final manager = DesktopSplashScreenManager(logger: logger);
      await manager.initLifeCycle();

      await expectLater(manager.initAfterView(_aContext(tester)), completes);

      expect(tester.binding.sendFramesToEngine, isTrue);
      expect(logger.records.map((record) => record.level), [LogsLevel.warn]);
    });
  });

  group("DesktopSplashScreenBuilder", () {
    test("depends on the logger manager", () {
      expect(const DesktopSplashScreenBuilder().dependsOn(), [LoggerManager]);
    });

    test("builds the manager of the desktop applications", () {
      expect(const DesktopSplashScreenBuilder().factory(), isA<DesktopSplashScreenManager>());
    });
  });
}

/// Answers the calls of the manager as the runner of the application would.
///
/// A null listener answers as a runner which draws no splash screen does: the call reaches nobody.
void _answerTheRunner(WidgetTester tester, void Function(String)? listener) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    DesktopSplashScreenManager.channel,
    (call) async {
      if (listener == null) {
        throw MissingPluginException();
      }

      listener(call.method);

      return null;
    },
  );
}

/// Builds a view and returns its context.
BuildContext _aContext(WidgetTester tester) {
  tester.binding.attachRootWidget(const SizedBox());

  return tester.binding.rootElement!;
}
