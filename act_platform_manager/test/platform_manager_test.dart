// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("PlatformManager", () {
    test("is a manager with a life cycle", () {
      expect(PlatformManager(), isA<AbsWithLifeCycle>());
    });

    test("reports the same platform as the platform singleton", () {
      final manager = PlatformManager();
      final platform = ActPlatform.instance;

      expect(manager.isAndroid, platform.isAndroid);
      expect(manager.isIos, platform.isIos);
      expect(manager.isFuchsia, platform.isFuchsia);
      expect(manager.isLinux, platform.isLinux);
      expect(manager.isMacOS, platform.isMacOS);
      expect(manager.isWindows, platform.isWindows);
      expect(manager.isWeb, platform.isWeb);
    });

    test("returns the environment of the platform", () {
      expect(PlatformManager().environment, ActPlatform.instance.environment);
    });
  });

  group("PlatformManager.isMobile", () {
    test("gathers the two mobile platforms", () {
      final manager = PlatformManager();

      expect(manager.isMobile, manager.isAndroid || manager.isIos);
    });

    test("is false on a desktop platform", () {
      final manager = PlatformManager();

      expect(manager.isDesktop && manager.isMobile, isFalse);
    });
  });

  group("PlatformManager.isDesktop", () {
    test("gathers the three desktop platforms", () {
      final manager = PlatformManager();

      expect(manager.isDesktop, manager.isLinux || manager.isMacOS || manager.isWindows);
    });
  });

  group("PlatformManager.version", () {
    test("is unknown before the initialisation", () {
      expect(PlatformManager().version, isNull);
    });

    test("stays unknown on a platform which has no SDK version to read", () async {
      final manager = PlatformManager();

      if (manager.isMobile) {
        // The version is read from a native plugin, which is out of reach here.
        return;
      }

      await manager.initLifeCycle();

      expect(manager.version, isNull);
    });
  });

  group("PlatformBuilder", () {
    test("depends on no other manager", () {
      expect(const PlatformBuilder().dependsOn(), isEmpty);
    });

    test("builds a platform manager", () {
      expect(const PlatformBuilder().factory(), isA<PlatformManager>());
    });

    test("builds a new manager at every call", () {
      const builder = PlatformBuilder();

      expect(builder.factory(), isNot(same(builder.factory())));
    });
  });
}
