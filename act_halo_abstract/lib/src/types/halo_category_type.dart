// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_halo_abstract/src/types/halo_service_type.dart';

/// The message category type
enum HaloCategoryType {
  data,
  notifFlags,
  keys,
  unknown,
}

/// Extension of the [HaloCategoryType]
extension HaloCategoryTypeExtension on HaloCategoryType {
  /// Returns the hex value linked to the enum
  int get hexValue {
    switch (this) {
      case HaloCategoryType.data:
        return HaloCategoryTypeHelper._dataValue;
      case HaloCategoryType.notifFlags:
      case HaloCategoryType.keys:
        return HaloCategoryTypeHelper._notifFlagsKeysValue;
      case HaloCategoryType.unknown:
        return HaloCategoryTypeHelper._unknownValue;
    }
  }
}

/// Helpful class to manage [HaloCategoryType] enum
class HaloCategoryTypeHelper {
  /// This defines the data hex value
  static const int _dataValue = 0x00;

  /// This defines the notification flags and keys hex value
  static const int _notifFlagsKeysValue = 0x01;

  /// This defines the unknown value
  static const int _unknownValue = ByteUtility.maxInt64;

  /// Parse the hex value given and returns the [HaloCategoryType] enum linked, if the value isn't
  /// known, the method returns [HaloCategoryType.unknown]
  static HaloCategoryType parseValue(
    int hexValue, {
    HaloServiceType serviceType = HaloServiceType.unknown,
  }) {
    if (hexValue == HaloCategoryTypeHelper._notifFlagsKeysValue) {
      switch (serviceType) {
        case HaloServiceType.attribute:
        case HaloServiceType.instantData:
          return HaloCategoryType.notifFlags;
        case HaloServiceType.recordData:
          return HaloCategoryType.keys;
        default:
          return HaloCategoryType.unknown;
      }
    }

    for (final category in HaloCategoryType.values) {
      if (category.hexValue == hexValue) {
        return category;
      }
    }

    return HaloCategoryType.unknown;
  }
}
