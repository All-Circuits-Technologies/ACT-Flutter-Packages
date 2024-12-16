// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';

/// Defines the HALO service type
enum HaloServiceType {
  attribute,
  instantData,
  recordData,
  request,
  unknown,
}

/// Extension of the [HaloServiceType]
extension HaloServiceTypeExtension on HaloServiceType {
  /// Returns the hex value linked to the enum
  int get hexValue {
    switch (this) {
      case HaloServiceType.attribute:
        return HaloServiceTypeHelper._attributeValue;
      case HaloServiceType.instantData:
        return HaloServiceTypeHelper._instantDataValue;
      case HaloServiceType.recordData:
        return HaloServiceTypeHelper._recordDataValue;
      case HaloServiceType.request:
        return HaloServiceTypeHelper._requestValue;
      case HaloServiceType.unknown:
        return HaloServiceTypeHelper._unknownValue;
    }
  }
}

/// Helpful class to manage [HaloServiceType] enum
class HaloServiceTypeHelper {
  /// This defines the attribute hex value
  static const int _attributeValue = 0x00;

  /// This defines the instant data hex value
  static const int _instantDataValue = 0x01;

  /// This defines the record data hex value
  static const int _recordDataValue = 0x02;

  /// This defines the request hex value
  static const int _requestValue = 0x03;

  /// This defines the unknown value
  static const int _unknownValue = ByteUtility.maxInt64;

  /// Parse the hex value given and returns the [HaloServiceType] enum linked, if the value isn't
  /// known, the method returns [HaloServiceType.unknown]
  static HaloServiceType parseValue(int typeValue) {
    for (final service in HaloServiceType.values) {
      if (service.hexValue == typeValue) {
        return service;
      }
    }

    return HaloServiceType.unknown;
  }
}
