// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_licenses_manager/act_licenses_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_licenses_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FakeGlobalManager.install();
    // The registry is the one of the application, and it is shared by the whole test file
    LicenseRegistry.reset();
  });

  tearDown(FakeAssets.stop);

  /// Builds the manager of an application whose configuration is [licenses], and initializes it.
  Future<ActLicensesManager> aManager(
    String licenses, {
    Map<String, String> assets = const {},
  }) async {
    final config = await FakeLicensesConfig.build(licenses, assets: assets);
    addTearDown(config.disposeLifeCycle);

    final manager = ActLicensesManager(configGetter: () => config);
    await manager.initLifeCycle();

    return manager;
  }

  /// The licenses the application would display, in the order they are collected.
  Future<List<LicenseEntry>> displayedLicenses() => LicenseRegistry.licenses.toList();

  group("ActLicensesBuilder", () {
    test("depends on the logger manager and on the configuration", () {
      expect(ActLicensesBuilder<FakeLicensesConfig>().dependsOn(), [
        LoggerManager,
        FakeLicensesConfig,
      ]);
    });

  });

  group("ActLicensesManager", () {
    test("adds the licenses of the configuration to the ones the application displays", () async {
      await aManager('''
licenses:
  extraElements:
    MyApp:
      - MIT
  texts:
    MIT: the text of the MIT license
''');

      final entries = await displayedLicenses();
      expect(entries.map((entry) => entry.packages).expand((packages) => packages), ["MyApp"]);
    });

    test("adds the licenses whose text is a file of the assets", () async {
      await aManager(
        '''
licenses:
  extraElements:
    Roboto:
      - OFL-1.1
  assetsFolders:
    - LICENSES
''',
        assets: {"LICENSES/OFL-1.1.txt": "the text of the OFL license"},
      );

      final entries = await displayedLicenses();
      expect(
        entries.expand((entry) => entry.paragraphs).map((paragraph) => paragraph.text),
        contains("the text of the OFL license"),
      );
    });

    test("adds nothing when the application declares no element", () async {
      await aManager("logs:\n  level: warning");

      expect(await displayedLicenses(), isEmpty);
    });

    test("waits for the licenses to be read before it hands any of them over", () async {
      // The initialization of the manager does not wait for the licenses to be read, so asking
      // for them right after it is what an application which opens its licenses page does
      await aManager('''
licenses:
  extraElements:
    MyApp:
      - MIT
  texts:
    MIT: the text of the MIT license
''');

      expect(await displayedLicenses(), hasLength(1));
    });
  });
}
