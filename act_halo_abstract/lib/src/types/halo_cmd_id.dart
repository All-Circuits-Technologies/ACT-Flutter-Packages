// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The HALO cmd id
enum HaloCmdId with MixinHaloType {
  read(rawValue: _readPullValue),
  pull(rawValue: _readPullValue),
  readReady(rawValue: 0x01),
  write(rawValue: _writePushCallValue),
  push(rawValue: _writePushCallValue),
  call(rawValue: _writePushCallValue),
  reset(rawValue: 0x03),
  sub(rawValue: 0x04),
  unSub(rawValue: 0x05),
  ack(rawValue: 0x06),
  result(rawValue: 0x07),
  unknown(rawValue: ByteUtility.maxInt64);

  /// This defines the read pull cmd raw value
  static const int _readPullValue = 0x00;

  /// This defines the write, push or call cmd raw value
  static const int _writePushCallValue = 0x02;

  /// Returns the raw value linked to the enum
  @override
  final int rawValue;

  /// Enum constructor
  const HaloCmdId({required this.rawValue});

  /// Parse the raw value given and returns the [HaloCmdId] enum linked, if the value isn't
  /// known, the method returns [HaloCmdId.unknown]
  static HaloCmdId parseValue(
    int rawValue, {
    bool isParsingReadWrite = true,
    bool isParsingRequest = false,
  }) {
    if (rawValue == _readPullValue) {
      return isParsingReadWrite ? HaloCmdId.read : HaloCmdId.pull;
    }

    if (rawValue == _writePushCallValue) {
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
      if (cmdId.rawValue == rawValue) {
        return cmdId;
      }
    }

    return HaloCmdId.unknown;
  }
}
