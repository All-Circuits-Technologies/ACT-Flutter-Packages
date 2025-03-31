// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The message halo error type
enum HaloErrorType with MixinHaloType {
  /// Means everything went well and there are no errors
  noError(rawValue: 0x00),

  /// Means that the previous message did not respect the expected format
  formatError(rawValue: 0x01),

  /// Means that the previous message is inconsistent with the protocol and the current state of the
  /// exchanges
  protocolError(rawValue: 0x02),

  /// Means that the service is already in use by another device
  serviceBusyError(rawValue: 0x03, isMakingSensToRetry: true),

  /// Means that the service, request, etc. has not been implemented yet
  notImplementedYet(rawValue: 0xFD),

  /// Means the message could not be sent due to a communication error in the hardware layer
  commError(rawValue: 0xFE, isMakingSensToRetry: true),

  /// Means that an error has occurred without it being able to be qualified
  genericError(rawValue: 0xFF, isMakingSensToRetry: true),

  /// This means that the error is unknown.
  ///
  /// This value can't be sent to/by the Firmware
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
