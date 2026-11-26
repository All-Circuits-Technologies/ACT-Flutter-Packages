// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_firebase_crash/act_firebase_crash.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("FirebaseCrashDebugConfig", () {
    test("keeps the warnings and what is worse when no level is given", () {
      const config = FirebaseCrashDebugConfig(identifier: "anId");

      expect(config.level, LogsLevel.warn);
    });

    test("is the same as a config which holds the same identifier and the same level", () {
      const config = FirebaseCrashDebugConfig(identifier: "anId", level: LogsLevel.info);
      const same = FirebaseCrashDebugConfig(identifier: "anId", level: LogsLevel.info);

      expect(config, same);
    });

    test("differs from a config which holds another identifier", () {
      const config = FirebaseCrashDebugConfig(identifier: "anId");
      const other = FirebaseCrashDebugConfig(identifier: "anotherId");

      expect(config, isNot(other));
    });

    test("differs from a config which holds another level", () {
      const config = FirebaseCrashDebugConfig(identifier: "anId", level: LogsLevel.info);
      const other = FirebaseCrashDebugConfig(identifier: "anId", level: LogsLevel.error);

      expect(config, isNot(other));
    });
  });
}
