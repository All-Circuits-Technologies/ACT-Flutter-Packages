// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// This class represents the information of an element (which can be a package, an image, the
/// application, a font, etc.), it contains the name of the elements and its license keys.
class ElementLicensesKeysModel extends Equatable {
  /// The name of the package.
  final String packageName;

  /// The license keys of the package.
  final List<String> licenseKeys;

  /// Class constructor
  const ElementLicensesKeysModel({required this.packageName, required this.licenseKeys});

  /// This method creates a copy of the current instance with the given parameters.
  ElementLicensesKeysModel copyWith({String? packageName, List<String>? licenseKeys}) =>
      ElementLicensesKeysModel(
        packageName: packageName ?? this.packageName,
        licenseKeys: licenseKeys ?? this.licenseKeys,
      );

  /// Class properties
  @override
  List<Object?> get props => [packageName, licenseKeys];
}
