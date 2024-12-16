// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';

/// Defines the HALO service type
enum HaloServiceType with MixinHaloType {
  attribute(rawValue: 0x00),
  instantData(rawValue: 0x01),
  recordData(rawValue: 0x02),
  request(rawValue: 0x03),
  unknown(rawValue: ByteUtility.maxInt64);

  /// Returns the raw value linked to the enum
  @override
  final int rawValue;

  /// Enum constructor
  const HaloServiceType({required this.rawValue});

  /// Parse the raw value given and returns the [HaloServiceType] enum linked, if the value isn't
  /// known, the method returns [HaloServiceType.unknown]
  static HaloServiceType parseValue(int typeValue) {
    for (final service in HaloServiceType.values) {
      if (service.rawValue == typeValue) {
        return service;
      }
    }

    return HaloServiceType.unknown;
  }
}
