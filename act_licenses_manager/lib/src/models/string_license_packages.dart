// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_licenses_manager/src/models/abs_license_packages.dart';
import 'package:flutter/foundation.dart';

/// {@macro act_licenses_manager.AbsLicensePackages}
///
/// This class is a concrete implementation of [AbsLicensePackages] with a string loaded in memory.
class StringLicensePackages extends AbsLicensePackages {
  /// The text of the license.
  final String licenseText;

  /// Class constructor
  const StringLicensePackages({
    required super.licenseKey,
    required super.packageNames,
    required this.licenseText,
  });

  /// {@macro act_licenses_manager.abs_license_packages.paragraphs_loader}
  @override
  Future<LicenseEntry?> paragraphsLoader() async =>
      LicenseEntryWithLineBreaks(packageNames, licenseText);

  /// {@macro act_licenses_manager.AbsLicensePackages.props}
  @override
  List<Object?> get props => [...super.props, licenseText];
}
