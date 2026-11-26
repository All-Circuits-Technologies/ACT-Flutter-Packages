// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_splash_screen_manager/act_splash_screen_manager.dart';
import 'package:act_splash_screen_manager/src/platforms/web_splash_screen_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("WebSplashScreenManager", () {
    test("is a splash screen manager", () {
      expect(WebSplashScreenManager(), isA<AbsSplashScreenManager>());
    });

    testWidgets("holds the first frame back until the first view is built", (tester) async {
      final manager = WebSplashScreenManager();

      await manager.initLifeCycle();

      expect(tester.binding.sendFramesToEngine, isFalse);

      await manager.initAfterView(_aContext(tester));

      expect(tester.binding.sendFramesToEngine, isTrue);
    });
  });
}

/// Builds a view and returns its context.
BuildContext _aContext(WidgetTester tester) {
  tester.binding.attachRootWidget(const SizedBox());

  return tester.binding.rootElement!;
}
