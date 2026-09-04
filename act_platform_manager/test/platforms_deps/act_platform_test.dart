// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ActPlatform.instance", () {
    test("always returns the same instance", () {
      expect(ActPlatform.instance, same(ActPlatform.instance));
    });
  });

  group("ActPlatform", () {
    test("reports exactly one platform", () {
      final platform = ActPlatform.instance;
      final reported = [
        platform.isAndroid,
        platform.isIos,
        platform.isFuchsia,
        platform.isLinux,
        platform.isMacOS,
        platform.isWindows,
        platform.isWeb,
      ].where((isCurrent) => isCurrent);

      expect(reported.length, 1);
    });

    test("reports the platform the tests run on", () {
      // The tests run on the host, through the io implementation of the platform.
      expect(ActPlatform.instance.isLinux, Platform.isLinux);
      expect(ActPlatform.instance.isMacOS, Platform.isMacOS);
      expect(ActPlatform.instance.isWindows, Platform.isWindows);
    });

    test("does not report the web when it runs on a host", () {
      expect(ActPlatform.instance.isWeb, isFalse);
    });

    test("returns the environment of the platform", () {
      expect(ActPlatform.instance.environment, Platform.environment);
    });
  });
}
