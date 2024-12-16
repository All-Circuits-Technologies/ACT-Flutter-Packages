// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';

/// The HALO cmd id
enum HaloCmdId {
  read,
  pull,
  readReady,
  sub,
  write,
  push,
  call,
  reset,
  unSub,
  ack,
  result,
  unknown,
}

/// Extension of the [HaloCmdId]
extension HaloCmdIdExtension on HaloCmdId {
  int get hexValue {
    switch (this) {
      case HaloCmdId.read:
      case HaloCmdId.pull:
        return HaloCmdIdHelper._readPullValue;
      case HaloCmdId.readReady:
        return HaloCmdIdHelper._readReadyValue;
      case HaloCmdId.sub:
        return HaloCmdIdHelper._subValue;
      case HaloCmdId.write:
      case HaloCmdId.push:
      case HaloCmdId.call:
        return HaloCmdIdHelper._writePushCallValue;
      case HaloCmdId.reset:
        return HaloCmdIdHelper._resetValue;
      case HaloCmdId.unSub:
        return HaloCmdIdHelper._unSubValue;
      case HaloCmdId.ack:
        return HaloCmdIdHelper._ackValue;
      case HaloCmdId.result:
        return HaloCmdIdHelper._resultValue;
      case HaloCmdId.unknown:
        return HaloCmdIdHelper._unknownValue;
    }
  }
}

/// Helpful class to manage [HaloCmdId] enum
class HaloCmdIdHelper {
  /// This defines the read pull cmd hex value
  static const int _readPullValue = 0x00;

  /// This defines the read ready cmd hex value
  static const int _readReadyValue = 0x01;

  /// This defines the write, push or call cmd hex value
  static const int _writePushCallValue = 0x02;

  /// This defines the reset cmd hex value
  static const int _resetValue = 0x03;

  /// This defines the subscribe cmd hex value
  static const int _subValue = 0x04;

  /// This defines the unsubscribe cmd hex value
  static const int _unSubValue = 0x05;

  /// This defines the ack cmd hex value
  static const int _ackValue = 0x06;

  /// This defines the result cmd hex value
  static const int _resultValue = 0x07;

  /// This defines the unknown value
  static const int _unknownValue = ByteUtility.maxInt64;

  /// Parse the hex value given and returns the [HaloCmdId] enum linked, if the value isn't
  /// known, the method returns [HaloCmdId.unknown]
  static HaloCmdId parseValue(
    int hexValue, {
    bool isParsingReadWrite = true,
    bool isParsingRequest = false,
  }) {
    if (hexValue == HaloCmdIdHelper._readPullValue) {
      return isParsingReadWrite ? HaloCmdId.read : HaloCmdId.pull;
    }

    if (hexValue == HaloCmdIdHelper._writePushCallValue) {
      HaloCmdId enumCmdId;
      if (isParsingReadWrite) {
        enumCmdId = HaloCmdId.write;
      } else if (isParsingRequest) {
        enumCmdId = HaloCmdId.call;
      } else {
        enumCmdId = HaloCmdId.push;
      }

      return enumCmdId;
    }

    for (final cmdId in HaloCmdId.values) {
      if (cmdId.hexValue == hexValue) {
        return cmdId;
      }
    }

    return HaloCmdId.unknown;
  }
}
