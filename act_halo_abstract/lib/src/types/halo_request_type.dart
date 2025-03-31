// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The HALO request type
enum HaloRequestType with MixinHaloType {
  /// Designates a request for which an acknowledgment and one or more return values are expected
  function(rawValue: 0x00),

  /// Designates a request for which an acknowledgment is expected and which has no return value
  procedure(rawValue: 0x01),

  /// Designates a request for which no acknowledgment or return value is expected
  order(rawValue: 0x02),

  /// This means that the request is unknown.
  ///
  /// This value can't be sent to/by the Firmware
  unknown(rawValue: ByteUtility.maxInt64);

  /// The raw value linked to the enum
  @override
  final int rawValue;

  /// Enum constructor
  const HaloRequestType({required this.rawValue});

  /// Parse the raw value given and returns the [HaloRequestType] enum linked, if the value isn't
  /// known, the method returns [HaloRequestType.unknown]
  static HaloRequestType parseValue(int rawValue) {
    for (final functionType in HaloRequestType.values) {
      if (functionType.rawValue == rawValue) {
        return functionType;
      }
    }

    return HaloRequestType.unknown;
  }
}
