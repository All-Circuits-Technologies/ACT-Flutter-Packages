// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("Environment.fromString", () {
    test("returns the environment which the given string targets", () {
      expect(Environment.fromString("DEV"), Environment.development);
      expect(Environment.fromString("QUALIF"), Environment.qualification);
      expect(Environment.fromString("PROD"), Environment.production);
    });

    test("ignores the case of the given string", () {
      expect(Environment.fromString("prod"), Environment.production);
      expect(Environment.fromString("Qualif"), Environment.qualification);
    });

    test("falls back on the development environment when the string is unknown", () {
      expect(Environment.fromString("STAGING"), Environment.development);
    });

    test("falls back on the development environment when the string is empty", () {
      expect(Environment.fromString(""), Environment.development);
    });

    test("refuses to target an environment which has no name to be built with", () {
      expect(Environment.fromString("local"), Environment.development);
      expect(Environment.fromString("default"), Environment.development);
    });
  });

  group("Environment", () {
    test("names the file of every environment after it", () {
      expect(Environment.local.fileName, "local");
      expect(Environment.defaultEnv.fileName, "default");
      expect(Environment.development.fileName, "development");
      expect(Environment.qualification.fileName, "qualification");
      expect(Environment.production.fileName, "production");
    });

    test("only lets the three environments of an application be targeted at build time", () {
      final targetable = Environment.values
          .where((env) => env.parsedString != null)
          .toList(growable: false);

      expect(targetable, [
        Environment.development,
        Environment.qualification,
        Environment.production,
      ]);
    });

    test("reads the targeted environment from the ENV variable", () {
      expect(Environment.envType, "ENV");
    });
  });
}
