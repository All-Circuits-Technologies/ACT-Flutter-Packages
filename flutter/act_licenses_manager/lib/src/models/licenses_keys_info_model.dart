// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_licenses_manager/src/models/element_licenses_model.dart';
import 'package:equatable/equatable.dart';

/// This class represents the information of a license, it contains the name of the package and the
/// license key.
class LicensesKeysInfoModel extends Equatable {
  /// The licenses of elements (which can be packages, images, the application, fonts, etc.)
  final Map<String, ElementLicensesKeysModel> packageLicenses;

  /// Class constructor
  const LicensesKeysInfoModel({required this.packageLicenses});

  /// This constructor creates an empty instance of the class.
  const LicensesKeysInfoModel.empty() : packageLicenses = const {};

  /// This method creates a copy of the current instance with the given parameters.
  LicensesKeysInfoModel copyWith({Map<String, ElementLicensesKeysModel>? packageLicenses}) =>
      LicensesKeysInfoModel(packageLicenses: packageLicenses ?? this.packageLicenses);

  /// This method creates an instance of the class from a json object
  static LicensesKeysInfoModel fromJson(Map<String, dynamic> json) {
    final logger = appLogger();
    final packageLicenses = <String, ElementLicensesKeysModel>{};

    for (final entry in json.entries) {
      final key = entry.key;

      final tmpLicenses = JsonUtility.getNotNullPrimaryElementsList<String>(
        json: json,
        key: key,
        logger: logger,
      );

      if (tmpLicenses == null) {
        logger.w("The licenses of the package $key are not valid, skipping it.");
        continue;
      }

      packageLicenses[key] = ElementLicensesKeysModel(packageName: key, licenseKeys: tmpLicenses);
    }

    return LicensesKeysInfoModel(packageLicenses: packageLicenses);
  }

  /// Class properties
  @override
  List<Object?> get props => [packageLicenses];
}
