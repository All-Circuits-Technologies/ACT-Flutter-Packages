// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(FakeAssets.stop);

  group("FakeAssets.serve", () {
    test("gives the content it serves for a key", () async {
      FakeAssets.serve({"assets/config/default.yaml": "logs:\n  level: warning"});

      final content = await rootBundle.loadString("assets/config/default.yaml");

      expect(content, "logs:\n  level: warning");
    });

    test("reports a key it does not serve as missing", () async {
      FakeAssets.serve({"assets/config/default.yaml": "a: 1"});

      expect(
        () => rootBundle.loadString("assets/config/local.yaml"),
        throwsA(isA<FlutterError>()),
      );
    });

    test("replaces the contents of a previous call", () async {
      FakeAssets.serve({"assets/first.yaml": "a: 1"});

      FakeAssets.serve({"assets/second.yaml": "b: 2"});

      expect(await rootBundle.loadString("assets/second.yaml"), "b: 2");
      expect(() => rootBundle.loadString("assets/first.yaml"), throwsA(isA<FlutterError>()));
    });

    test("serves the new content of a key which has already been read", () async {
      FakeAssets.serve({"assets/config.yaml": "a: 1"});
      await rootBundle.loadString("assets/config.yaml");

      FakeAssets.serve({"assets/config.yaml": "a: 2"});

      expect(await rootBundle.loadString("assets/config.yaml"), "a: 2");
    });
  });

  group("FakeAssets.stop", () {
    test("stops serving the assets of the test", () async {
      FakeAssets.serve({"assets/config.yaml": "a: 1"});
      await rootBundle.loadString("assets/config.yaml");

      FakeAssets.stop();

      expect(() => rootBundle.loadString("assets/config.yaml"), throwsA(isA<FlutterError>()));
    });
  });
}
