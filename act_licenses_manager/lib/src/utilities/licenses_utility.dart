// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_licenses_manager/src/managers/mixin_licenses_config.dart';
import 'package:act_licenses_manager/src/models/abs_license_packages.dart';
import 'package:act_licenses_manager/src/models/asset_licence_packages.dart';
import 'package:act_licenses_manager/src/models/licenses_keys_info_model.dart';
import 'package:act_licenses_manager/src/models/string_license_packages.dart';
import 'package:act_logger_manager/act_logger_manager.dart';

/// This class is a utility class for the licenses, it contains methods to parse the license info
/// from config
sealed class LicensesUtility {
  /// This method parses the license packages from the config and returns a list of
  /// [AbsLicensePackages].
  static Future<List<AbsLicensePackages>> parseLicensePackages({
    required MixinLicensesConfig config,
    required LogsHelper logger,
  }) async {
    final extraElements = config.licensesExtraElements.load();

    if (extraElements.packageLicenses.isEmpty) {
      // No need to go further
      return const [];
    }

    final tmpLicensesPackages = _convertToLicensesPackages(licensesKeysInfo: extraElements);
    final licensesPackagesList = _parseLicensesPackagesFromText(
      licensesPackages: tmpLicensesPackages,
      config: config,
    );

    final licensesPackagesFromAssets = await _parseLicensesPackagesFromAssets(
      licensesPackages: tmpLicensesPackages,
      config: config,
    );

    licensesPackagesList.addAll(licensesPackagesFromAssets);

    if (tmpLicensesPackages.isNotEmpty) {
      logger.w(
        "The licenses with keys: ${tmpLicensesPackages.keys.join(", ")}; have no text defined in "
        "the config, and no license file found in the assets folders; skipping them.",
      );
    }

    return licensesPackagesList;
  }

  /// This method converts the [LicensesKeysInfoModel] to a map with the licenses keys as keys and
  /// the list of package names as values.
  static Map<String, List<String>> _convertToLicensesPackages({
    required LicensesKeysInfoModel licensesKeysInfo,
  }) {
    final licensesPackages = <String, List<String>>{};

    for (final entry in licensesKeysInfo.packageLicenses.entries) {
      final packageName = entry.key;
      final licenseKeys = entry.value.licenseKeys;

      for (final licenseKey in licenseKeys) {
        if (licensesPackages.containsKey(licenseKey)) {
          licensesPackages[licenseKey]!.add(packageName);
        } else {
          licensesPackages[licenseKey] = [packageName];
        }
      }
    }

    return licensesPackages;
  }

  /// This method parses the licenses packages from the config and returns a list of
  /// [AbsLicensePackages].
  ///
  /// It removes the licenses managed by this method from the [licensesPackages] map.
  static List<AbsLicensePackages> _parseLicensesPackagesFromText({
    required Map<String, List<String>> licensesPackages,
    required MixinLicensesConfig config,
  }) {
    final licensesPackagesList = <AbsLicensePackages>[];
    final managedLicenses = <String>[];

    final licensesTexts = config.licensesTexts.load();

    for (final entry in licensesPackages.entries) {
      final licenseKey = entry.key;

      if (!licensesTexts.licensesText.containsKey(licenseKey)) {
        // No license text for this license key, skipping it
        continue;
      }

      licensesPackagesList.add(
        StringLicensePackages(
          licenseKey: licenseKey,
          packageNames: entry.value,
          licenseText: licensesTexts.licensesText[licenseKey]!,
        ),
      );
      managedLicenses.add(licenseKey);
    }

    licensesPackages.removeWhere((key, value) => managedLicenses.contains(key));

    return licensesPackagesList;
  }

  /// This method parses the licenses packages from the config and returns a list of
  /// [AbsLicensePackages].
  ///
  /// It removes the licenses managed by this method from the [licensesPackages] map.
  static Future<List<AbsLicensePackages>> _parseLicensesPackagesFromAssets({
    required Map<String, List<String>> licensesPackages,
    required MixinLicensesConfig config,
  }) async {
    final licensesPackagesList = <AbsLicensePackages>[];
    final managedLicenses = <String>[];

    final licensesAssetsFolders = config.licensesAssetsFolders.load();
    if (licensesAssetsFolders == null || licensesAssetsFolders.isEmpty) {
      // No licenses assets folders defined in config
      return [];
    }

    for (final entry in licensesPackages.entries) {
      final licenseKey = entry.key;

      for (final assetFolder in licensesAssetsFolders) {
        final licensePath = _buildAssetPath(folder: assetFolder, licenseKey: licenseKey);

        final assetBundle = await AssetsBundleUtility.loadStringFromAssetBundle(licensePath);
        if (assetBundle.status != AssetsBundleResult.ok || assetBundle.data == null) {
          // License file not found in this asset folder, skipping it
          continue;
        }

        licensesPackagesList.add(
          AssetLicensePackages(
            licenseKey: licenseKey,
            packageNames: entry.value,
            licensePath: licensePath,
          ),
        );
        managedLicenses.add(licenseKey);

        // No need to look for this license in the other asset folders
        break;
      }
    }

    licensesPackages.removeWhere((key, value) => managedLicenses.contains(key));

    return licensesPackagesList;
  }

  /// This method builds the asset path for a license key and an asset folder.
  static String _buildAssetPath({required String folder, required String licenseKey}) =>
      "$folder/$licenseKey.txt";
}
