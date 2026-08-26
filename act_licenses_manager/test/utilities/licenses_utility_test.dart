// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_licenses_manager/src/models/asset_licence_packages.dart';
import 'package:act_licenses_manager/src/models/string_license_packages.dart';
import 'package:act_licenses_manager/src/utilities/licenses_utility.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_licenses_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeExternalLogger logs;

  setUp(() {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
  });

  tearDown(FakeAssets.stop);

  /// Reads the licenses of an application whose configuration is [licenses].
  Future<List<Object>> parse(String licenses, {Map<String, String> assets = const {}}) async {
    final config = await FakeLicensesConfig.build(licenses, assets: assets);
    addTearDown(config.disposeLifeCycle);

    return LicensesUtility.parseLicensePackages(
      config: config,
      logger: logs.buildHelper(category: "licenses"),
    );
  }

  group("LicensesUtility.parseLicensePackages", () {
    test("returns nothing when the application declares no element", () async {
      expect(await parse("logs:\n  level: warning"), isEmpty);
    });

    test("returns a license whose text is written in the configuration", () async {
      final packages = await parse('''
licenses:
  extraElements:
    MyApp:
      - MIT
  texts:
    MIT: the text of the MIT license
''');

      expect(packages, [
        const StringLicensePackages(
          licenseKey: "MIT",
          packageNames: ["MyApp"],
          licenseText: "the text of the MIT license",
        ),
      ]);
    });

    test("gathers under one license every element which uses it", () async {
      final packages = await parse('''
licenses:
  extraElements:
    MyApp:
      - MIT
    Roboto:
      - MIT
  texts:
    MIT: the text of the MIT license
''');

      expect((packages.single as StringLicensePackages).packageNames, ["MyApp", "Roboto"]);
    });

    test("returns one entry per license of an element", () async {
      final packages = await parse('''
licenses:
  extraElements:
    MyApp:
      - MIT
      - Apache-2.0
  texts:
    MIT: the text of the MIT license
    Apache-2.0: the text of the Apache license
''');

      expect(packages.length, 2);
    });

    test("returns a license whose text is a file of the assets", () async {
      final packages = await parse(
        '''
licenses:
  extraElements:
    MyApp:
      - MIT
  assetsFolders:
    - LICENSES
''',
        assets: {"LICENSES/MIT.txt": "the text of the MIT license"},
      );

      expect(packages, [
        const AssetLicensePackages(
          licenseKey: "MIT",
          packageNames: ["MyApp"],
          licensePath: "LICENSES/MIT.txt",
        ),
      ]);
    });

    test("looks for a license file in every folder the configuration lists", () async {
      final packages = await parse(
        '''
licenses:
  extraElements:
    MyApp:
      - MIT
  assetsFolders:
    - LICENSES
    - actlibs/LICENSES
''',
        assets: {"actlibs/LICENSES/MIT.txt": "the text of the MIT license"},
      );

      expect(
        (packages.single as AssetLicensePackages).licensePath,
        "actlibs/LICENSES/MIT.txt",
      );
    });

    test("stops at the first folder which has the license file", () async {
      final packages = await parse(
        '''
licenses:
  extraElements:
    MyApp:
      - MIT
  assetsFolders:
    - LICENSES
    - actlibs/LICENSES
''',
        assets: {
          "LICENSES/MIT.txt": "the text of the MIT license",
          "actlibs/LICENSES/MIT.txt": "another text of the MIT license",
        },
      );

      expect((packages.single as AssetLicensePackages).licensePath, "LICENSES/MIT.txt");
    });

    test("prefers the text of the configuration over the file of the assets", () async {
      final packages = await parse(
        '''
licenses:
  extraElements:
    MyApp:
      - MIT
  assetsFolders:
    - LICENSES
  texts:
    MIT: the text of the configuration
''',
        assets: {"LICENSES/MIT.txt": "the text of the assets"},
      );

      expect(packages, [
        const StringLicensePackages(
          licenseKey: "MIT",
          packageNames: ["MyApp"],
          licenseText: "the text of the configuration",
        ),
      ]);
    });

    test("skips a license whose text is nowhere to be found", () async {
      expect(
        await parse('''
licenses:
  extraElements:
    MyApp:
      - MIT
'''),
        isEmpty,
      );
    });

    test("warns about the licenses it skips", () async {
      await parse('''
licenses:
  extraElements:
    MyApp:
      - MIT
      - Apache-2.0
''');

      expect(logs.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("warns about nothing when every license has a text", () async {
      await parse('''
licenses:
  extraElements:
    MyApp:
      - MIT
  texts:
    MIT: the text of the MIT license
''');

      expect(logs.recordsAtLevel(LogsLevel.warn), isEmpty);
    });
  });
}
