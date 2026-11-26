// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_licenses_manager/act_licenses_manager.dart';
import 'package:act_licenses_manager/src/models/asset_licence_packages.dart';
import 'package:act_licenses_manager/src/models/element_licenses_model.dart';
import 'package:act_licenses_manager/src/models/string_license_packages.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
  });

  tearDown(FakeAssets.stop);

  group("LicensesKeysInfoModel.fromJson", () {
    test("reads the licenses of every element", () {
      final model = LicensesKeysInfoModel.fromJson(const {
        "MyApp": ["MIT", "Apache-2.0"],
        "Roboto": ["OFL-1.1"],
      });

      expect(model.packageLicenses.keys, ["MyApp", "Roboto"]);
      expect(model.packageLicenses["MyApp"]?.licenseKeys, ["MIT", "Apache-2.0"]);
    });

    test("names each element after the key it is declared under", () {
      final model = LicensesKeysInfoModel.fromJson(const {
        "MyApp": ["MIT"],
      });

      expect(model.packageLicenses["MyApp"]?.packageName, "MyApp");
    });

    test("skips an element whose licenses are not a list of names", () {
      final model = LicensesKeysInfoModel.fromJson(const {"MyApp": 42});

      expect(model.packageLicenses, isEmpty);
    });

    test("warns about the element it skips", () {
      LicensesKeysInfoModel.fromJson(const {"MyApp": 42});

      expect(logger.recordsAtLevel(LogsLevel.warn), isNotEmpty);
    });

    test("keeps the elements which are valid alongside the one it skips", () {
      final model = LicensesKeysInfoModel.fromJson(const {
        "MyApp": 42,
        "Roboto": ["OFL-1.1"],
      });

      expect(model.packageLicenses.keys, ["Roboto"]);
    });

    test("reads no element from an empty object", () {
      expect(LicensesKeysInfoModel.fromJson(const {}).packageLicenses, isEmpty);
    });
  });

  group("LicensesKeysInfoModel", () {
    test("carries no element when it is empty", () {
      expect(const LicensesKeysInfoModel.empty().packageLicenses, isEmpty);
    });

    test("replaces the elements it is copied with", () {
      const model = LicensesKeysInfoModel.empty();

      final copy = model.copyWith(
        packageLicenses: const {
          "MyApp": ElementLicensesKeysModel(packageName: "MyApp", licenseKeys: ["MIT"]),
        },
      );

      expect(copy.packageLicenses.keys, ["MyApp"]);
    });

    test("keeps the elements it is copied without", () {
      const model = LicensesKeysInfoModel(
        packageLicenses: {
          "MyApp": ElementLicensesKeysModel(packageName: "MyApp", licenseKeys: ["MIT"]),
        },
      );

      expect(model.copyWith(), model);
    });
  });

  group("LicensesTextModel.fromJson", () {
    test("reads the text of every license", () {
      final model = LicensesTextModel.fromJson(const {"MIT": "the text of the MIT license"});

      expect(model.licensesText, {"MIT": "the text of the MIT license"});
    });

    test("skips a license whose text is not one", () {
      final model = LicensesTextModel.fromJson(const {"MIT": 42});

      expect(model.licensesText, isEmpty);
    });

    test("warns about the license it skips", () {
      LicensesTextModel.fromJson(const {"MIT": 42});

      expect(logger.recordsAtLevel(LogsLevel.warn), isNotEmpty);
    });

    test("carries no text when it is empty", () {
      expect(const LicensesTextModel.empty().licensesText, isEmpty);
    });

    test("keeps the texts it is copied without", () {
      const model = LicensesTextModel(licensesText: {"MIT": "a text"});

      expect(model.copyWith(), model);
    });
  });

  group("ElementLicensesKeysModel", () {
    test("equals another element which carries the same name and the same licenses", () {
      expect(
        const ElementLicensesKeysModel(packageName: "MyApp", licenseKeys: ["MIT"]),
        const ElementLicensesKeysModel(packageName: "MyApp", licenseKeys: ["MIT"]),
      );
    });

    test("replaces the licenses it is copied with", () {
      const model = ElementLicensesKeysModel(packageName: "MyApp", licenseKeys: ["MIT"]);

      expect(model.copyWith(licenseKeys: ["Apache-2.0"]).licenseKeys, ["Apache-2.0"]);
    });
  });

  group("StringLicensePackages.paragraphsLoader", () {
    test("returns the text it carries, for the elements which use it", () async {
      const packages = StringLicensePackages(
        licenseKey: "MIT",
        packageNames: ["MyApp"],
        licenseText: "a paragraph\n\nanother paragraph",
      );

      final entry = await packages.paragraphsLoader();

      expect(entry?.packages, ["MyApp"]);
      expect(entry?.paragraphs.map((paragraph) => paragraph.text).toList(), [
        "a paragraph",
        "another paragraph",
      ]);
    });
  });

  group("AssetLicensePackages.paragraphsLoader", () {
    test("returns the text of the file it points at", () async {
      FakeAssets.serve({"LICENSES/MIT.txt": "the text of the MIT license"});
      const packages = AssetLicensePackages(
        licenseKey: "MIT",
        packageNames: ["MyApp"],
        licensePath: "LICENSES/MIT.txt",
      );

      final entry = await packages.paragraphsLoader();

      expect(entry?.paragraphs.map((paragraph) => paragraph.text).toList(), [
        "the text of the MIT license",
      ]);
    });

    test("returns nothing when the file is missing", () async {
      FakeAssets.serve(const {});
      const packages = AssetLicensePackages(
        licenseKey: "MIT",
        packageNames: ["MyApp"],
        licensePath: "LICENSES/MIT.txt",
      );

      expect(await packages.paragraphsLoader(), isNull);
    });

    test("warns about the file it cannot read", () async {
      FakeAssets.serve(const {});

      await const AssetLicensePackages(
        licenseKey: "MIT",
        packageNames: ["MyApp"],
        licensePath: "LICENSES/MIT.txt",
      ).paragraphsLoader();

      expect(logger.recordsAtLevel(LogsLevel.warn), isNotEmpty);
    });
  });

  group("AbsLicensePackages", () {
    test("equals another one which carries the same key, elements and text", () {
      expect(
        const StringLicensePackages(
          licenseKey: "MIT",
          packageNames: ["MyApp"],
          licenseText: "a text",
        ),
        const StringLicensePackages(
          licenseKey: "MIT",
          packageNames: ["MyApp"],
          licenseText: "a text",
        ),
      );
    });

    test("differs from one which points at a file rather than carrying a text", () {
      expect(
        const StringLicensePackages(
          licenseKey: "MIT",
          packageNames: ["MyApp"],
          licenseText: "a text",
        ),
        isNot(
          const AssetLicensePackages(
            licenseKey: "MIT",
            packageNames: ["MyApp"],
            licensePath: "LICENSES/MIT.txt",
          ),
        ),
      );
    });
  });
}
