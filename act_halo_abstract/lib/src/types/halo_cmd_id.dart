// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';

/// The HALO cmd id
enum HaloCmdId with MixinHaloType {
  /// This command allows the client to read data stored on the device
  read(rawValue: _readPullValue),

  /// This command allows the client to ask the device to send the stored data
  pull(rawValue: _readPullValue),

  /// This command allows the client to inform the device that it wishes to receive a packet from
  /// the exchange area
  readReady(rawValue: 0x01),

  /// This command allows the client to write data to the device
  write(rawValue: _writePushCallValue),

  /// This command allows the client to write data to the device or the device to send the data to
  /// the client
  push(rawValue: _writePushCallValue),

  /// This command allows you to call queries
  call(rawValue: _writePushCallValue),

  /// This command allows the client to inform the device that it wishes to restart exchanges from
  /// scratch, regardless of the current state.
  reset(rawValue: 0x03),

  /// This command allows the client to inform the device that it wishes to be notified when data is
  /// updated on the device
  sub(rawValue: 0x04),

  /// This command allows the client to inform the device that it no longer wishes to be notified
  /// when data is updated on the device
  unSub(rawValue: 0x05),

  /// This command allows the client to specifically acknowledge certain IDs to validate that they
  /// have been processed correctly.
  ack(rawValue: 0x06),

  /// This command returns a result to the requester.
  result(rawValue: 0x07),

  /// This means that the command is unknown.
  ///
  /// This value can't be sent to/by the Firmware
  unknown(rawValue: ByteUtility.maxInt32);

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
