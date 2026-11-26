// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/utilities/assets_config_reader.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(FakeAssets.stop);

  const reader = AssetsConfigReader(configPath: "assets/config/");

  group("AssetsConfigReader.locate", () {
    test("gives the asset key of the file in the config folder", () {
      expect(reader.locate("default.yaml"), "assets/config/default.yaml");
    });
  });

  group("AssetsConfigReader.readRaw", () {
    test("returns the content of the asset", () async {
      FakeAssets.serve({"assets/config/default.yaml": "logs:\n  level: warning"});

      expect(await reader.readRaw("assets/config/default.yaml"), "logs:\n  level: warning");
    });

    test("returns null when the asset doesn't exist", () async {
      FakeAssets.serve({});

      expect(await reader.readRaw("assets/config/default.yaml"), isNull);
    });

    test("returns an empty content for an empty asset", () async {
      FakeAssets.serve({"assets/config/.env": ""});

      expect(await reader.readRaw("assets/config/.env"), "");
    });
  });
}
