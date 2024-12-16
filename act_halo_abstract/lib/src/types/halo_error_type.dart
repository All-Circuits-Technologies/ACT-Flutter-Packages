// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The message halo error type
enum HaloErrorType with MixinHaloType {
  noError(rawValue: 0x00),
  formatError(rawValue: 0x01),
  protocolError(rawValue: 0x02),
  serviceBusyError(rawValue: 0x03, isMakingSensToRetry: true),
  notImplementedYet(rawValue: 0xFD),
  commError(rawValue: 0xFE, isMakingSensToRetry: true),
  genericError(rawValue: 0xFF, isMakingSensToRetry: true),
  unknown(rawValue: ByteUtility.maxInt64);

  /// The raw value linked to the enum
  @override
  final int rawValue;

  /// True if it's making sens to retry to do what we were trying to do, according to the error
  /// received
  final bool isMakingSensToRetry;

  /// Enum constructor
  const HaloErrorType({
    required this.rawValue,
    this.isMakingSensToRetry = false,
  });

  /// Parse the raw value given and returns the [HaloErrorType] enum linked, if the value isn't
  /// known, the method returns [HaloErrorType.unknown]
  static HaloErrorType parseValue(int rawValue) {
    for (final error in HaloErrorType.values) {
      if (error.rawValue == rawValue) {
        return error;
      }
    }

    return HaloErrorType.unknown;
  }
}
