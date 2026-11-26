// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// {@template act_licenses_manager.AbsLicensePackages}
/// This class represents the information of a license, it contains the license key and the list of
/// package names that use this license.
/// {@endtemplate}
abstract class AbsLicensePackages extends Equatable {
  /// The key of the license.
  final String licenseKey;

  /// The list of package names that use this license.
  final List<String> packageNames;

  /// Class constructor
  const AbsLicensePackages({required this.licenseKey, required this.packageNames});

  /// {@template act_licenses_manager.abs_license_packages.paragraphs_loader}
  /// This method should load the license text and return a [LicenseEntry] with the license key, the
  /// package names and the license text.
  /// {@endtemplate}
  Future<LicenseEntry?> paragraphsLoader();

  /// {@template act_licenses_manager.AbsLicensePackages.props}
  /// The properties of the class for the license packages
  /// {@endtemplate}
  @override
  @mustCallSuper
  List<Object?> get props => [licenseKey, packageNames];
}
