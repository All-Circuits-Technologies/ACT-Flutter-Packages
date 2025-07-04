// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The message category type
enum HaloCategoryType with MixinHaloType {
  /// This means that the message is linked to the attribute data
  data(rawValue: 0x00),

  /// This means that the message is related to the notification FLAGS
  notifFlags(rawValue: _notifFlagsKeysValue),

  /// This means that the message is related to the archive keys of the historical data
  keys(rawValue: _notifFlagsKeysValue),

  /// This means that the category is unknown.
  ///
  /// This value can't be sent to/by the Firmware
  unknown(rawValue: ByteUtility.maxInt32);

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
