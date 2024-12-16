// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';

/// The HALO request type
enum HaloRequestType {
  function,
  procedure,
  order,
  unknown,
}

/// Extension of the [HaloRequestType]
extension HaloRequestTypeExtension on HaloRequestType {
  /// Returns the hex value linked to the enum
  int get hexValue {
    switch (this) {
      case HaloRequestType.function:
        return HaloRequestTypeHelper._functionValue;
      case HaloRequestType.procedure:
        return HaloRequestTypeHelper._procedureValue;
      case HaloRequestType.order:
        return HaloRequestTypeHelper._orderValue;
      case HaloRequestType.unknown:
        return HaloRequestTypeHelper._unknownValue;
    }
  }
}

/// Helpful class to manage [HaloRequestTypeHelper] enum
class HaloRequestTypeHelper {
  /// This defines the function hex value
  static const int _functionValue = 0x00;

  /// This defines the procedure hex value
  static const int _procedureValue = 0x01;

  /// This defines the order hex value
  static const int _orderValue = 0x02;

  /// This defines the unknown value
  static const int _unknownValue = ByteUtility.maxInt64;

  /// Parse the hex value given and returns the [HaloRequestType] enum linked, if the value isn't
  /// known, the method returns [HaloRequestType.unknown]
  static HaloRequestType parseValue(int hexValue) {
    for (final functionType in HaloRequestType.values) {
      if (functionType.hexValue == hexValue) {
        return functionType;
      }
    }

    return HaloRequestType.unknown;
  }
}
