// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_licenses_manager/src/models/abs_license_packages.dart';
import 'package:flutter/foundation.dart';

/// {@macro act_licenses_manager.AbsLicensePackages}
///
/// This class is a concrete implementation of [AbsLicensePackages] with a license loaded from an
/// asset file.
class AssetLicensePackages extends AbsLicensePackages {
  /// The path of the license file.
  final String licensePath;

  /// Class constructor
  const AssetLicensePackages({
    required super.licenseKey,
    required super.packageNames,
    required this.licensePath,
  });

  /// {@macro act_licenses_manager.abs_license_packages.paragraphs_loader}
  @override
  Future<LicenseEntry?> paragraphsLoader() async {
    final assetBundle = await AssetsBundleUtility.loadStringFromAssetBundle(
      licensePath,
      logger: appLogger(),
    );

    if (assetBundle.status != AssetsBundleResult.ok || assetBundle.data == null) {
      appLogger().w("The license file at path $licensePath could not be loaded, skipping it.");
      return null;
    }

    return LicenseEntryWithLineBreaks(packageNames, assetBundle.data!);
  }

  /// {@macro act_licenses_manager.AbsLicensePackages.props}
  @override
  List<Object?> get props => [...super.props, licensePath];
}
