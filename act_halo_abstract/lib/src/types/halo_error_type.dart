// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';

/// The message halo error type
enum HaloErrorType {
  noError,
  formatError,
  protocolError,
  serviceBusyError,
  genericError,
  commError,
  unknown,
}

/// Extension of the [HaloErrorType]
extension HaloErrorTypeExtension on HaloErrorType {
  /// Returns the hex value linked to the enum
  int get hexValue {
    switch (this) {
      case HaloErrorType.noError:
        return HaloErrorTypeHelper._noErrorValue;
      case HaloErrorType.formatError:
        return HaloErrorTypeHelper._formatErrorValue;
      case HaloErrorType.protocolError:
        return HaloErrorTypeHelper._protocolErrorValue;
      case HaloErrorType.serviceBusyError:
        return HaloErrorTypeHelper._serviceBusyErrorValue;
      case HaloErrorType.commError:
        return HaloErrorTypeHelper._communicationErrorValue;
      case HaloErrorType.genericError:
        return HaloErrorTypeHelper._genericErrorValue;
      case HaloErrorType.unknown:
        return HaloErrorTypeHelper._unknownValue;
    }
  }

  /// Returns true if it's making sens to retry to do what we were trying to do, according to the
  /// error received
  bool get isMakingSensToRetry {
    switch (this) {
      case HaloErrorType.noError:
      case HaloErrorType.unknown:
      case HaloErrorType.formatError:
      case HaloErrorType.protocolError:
        return false;
      case HaloErrorType.commError:
      case HaloErrorType.genericError:
      case HaloErrorType.serviceBusyError:
        return true;
    }
  }
}

/// Helpful class to manage [HaloErrorType] enum
class HaloErrorTypeHelper {
  /// There is no error
  static const int _noErrorValue = 0x00;

  /// This is a problem with a message sent or received: it is not well formatted
  static const int _formatErrorValue = 0x01;

  /// A protocol problem occurred: the message previously received doesn't make sens in what we are
  /// trying to achieve
  static const int _protocolErrorValue = 0x02;

  /// This error occurred when we are trying to send messages with a busy device (already connected
  /// to another client)
  static const int _serviceBusyErrorValue = 0x03;

  /// This error occurred when a packet hasn't been sent because a communication error occurred over
  /// the material layer
  static const int _communicationErrorValue = 0xFE;

  /// This is a generic error
  static const int _genericErrorValue = 0xFF;

  /// This defines the unknown value
  static const int _unknownValue = ByteUtility.maxInt64;

  /// Parse the hex value given and returns the [HaloErrorType] enum linked, if the value isn't
  /// known, the method returns [HaloErrorType.unknown]
  static HaloErrorType parseValue(int hexValue) {
    for (final error in HaloErrorType.values) {
      if (error.hexValue == hexValue) {
        return error;
      }
    }

    return HaloErrorType.unknown;
  }
}
