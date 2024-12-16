// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The HALO request type
enum HaloRequestType with MixinHaloType {
  function(rawValue: 0x00),
  procedure(rawValue: 0x01),
  order(rawValue: 0x02),
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
