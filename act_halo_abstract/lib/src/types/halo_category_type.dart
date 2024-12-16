// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The message category type
enum HaloCategoryType with MixinHaloType {
  data(rawValue: 0x00),
  notifFlags(rawValue: _notifFlagsKeysValue),
  keys(rawValue: _notifFlagsKeysValue),
  unknown(rawValue: ByteUtility.maxInt64);

  /// This defines the notification flags and keys raw value
  static const int _notifFlagsKeysValue = 0x01;

  /// Returns the raw value linked to the enum
  @override
  final int rawValue;

  /// Enum constructor
  const HaloCategoryType({required this.rawValue});

  /// Parse the raw value given and returns the [HaloCategoryType] enum linked, if the value isn't
  /// known, the method returns [HaloCategoryType.unknown]
  static HaloCategoryType parseValue(
    int rawValue, {
    HaloServiceType serviceType = HaloServiceType.unknown,
  }) {
    if (rawValue == _notifFlagsKeysValue) {
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
      if (category.rawValue == rawValue) {
        return category;
      }
    }

    return HaloCategoryType.unknown;
  }
}
