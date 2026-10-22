// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:typed_data';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/src/characteristics/abstract_halo_characteristic.dart';
import 'package:act_halo_ble_layer/src/halo_ble_companion.dart';
import 'package:mutex/mutex.dart';

/// This is the BLE hardware layer for managing attributes
///
/// The commands are written on the characteristic B as `[CMD_ID, VALUE_NB, ATTR_ID]`, the device
/// answers on B as `[ERROR_ENUM, VALUE_NB, ATTR_ID]` and the values go through the characteristic C.
/// The characteristic A notifies the flags of the attributes which changed.
class HaloBleAttributeHardware extends AbstractHaloAttributeHardware {
  /// The size of the commands and of the results on the characteristic B
  static const int _cmdSize = 3;

  /// The most values an attribute holds, `VALUE_NB` being an U1
  static const int _maxValueNb = 255;

  /// The ble companion to use in order to exchange
  final HaloBleCompanion _bleCompanion;

  /// Mutex which keeps the steps of two exchanges from mixing on the characteristics B and C
  final Mutex _exchangeMutex;

  /// The subscription to the flags notified on the characteristic A
  late final StreamSubscription<Uint8List> _flagsSubscription;

  /// Class constructor
  HaloBleAttributeHardware({required HaloBleCompanion bleCompanion})
    : _bleCompanion = bleCompanion,
      _exchangeMutex = Mutex() {
    _flagsSubscription = _bleCompanion.haloBleConfig.charAAttrNotify.notificationStream.listen(
      _onFlags,
    );
  }

  /// This method allows to write a specific attribute value to the device
  ///
  /// The frame is cut in packets of the size of the companion, each one is acknowledged by the
  /// device
  @override
  Future<HaloErrorType> writeAttribute({required HaloPacket packet}) =>
      _exchangeMutex.protect(() async {
        final id = packet.dataId.id;
        final valueNb = packet.payload.elementsNb;

        if (valueNb == 0 || valueNb > _maxValueNb) {
          appLogger().w("The attribute $id can't be written with $valueNb values");
          return HaloErrorType.formatError;
        }

        final (error, _) = await _sendCmd(cmdId: HaloCmdId.write, valueNb: valueNb, id: id);

        if (error != HaloErrorType.noError) {
          appLogger().w("The device refused to write the attribute: $id");
          return error;
        }

        var lastError = HaloErrorType.noError;
        for (final data in packet.payload.getDataToSend(maxPacketSize: _bleCompanion.packetSize)) {
          // The device acknowledges every packet, the last one with the result of the write
          (lastError, _) = await _writeAndWaitResult(
            char: _bleCompanion.haloBleConfig.charCAttrTmp,
            data: data,
            id: id,
          );

          if (lastError != HaloErrorType.noError) {
            appLogger().w("A problem occurred when writing the attribute: $id");
            return lastError;
          }
        }

        return lastError;
      });

  /// This method allows to read a specific attribute value from the device and thanks to the
  /// [HaloDataId] given
  @override
  Future<(HaloErrorType, HaloPacket?)> readAttribute({required HaloDataId dataId}) =>
      _exchangeMutex.protect(() => _unsafeReadAttribute(dataId));

  /// Reads the attribute [dataId], the caller holds the [_exchangeMutex]
  Future<(HaloErrorType, HaloPacket?)> _unsafeReadAttribute(HaloDataId dataId) async {
    final id = dataId.id;
    final (error, _) = await _sendCmd(cmdId: HaloCmdId.read, valueNb: 0, id: id);

    if (error != HaloErrorType.noError) {
      appLogger().w("A problem occurred when asking to read the attribute: $id");
      return (error, null);
    }

    final packets = <Uint8List>[];
    var isLast = false;

    while (!isLast) {
      final (readError, data) = await _bleCompanion.writeAndWaitNotifResult(
        toWriteInto: _bleCompanion.haloBleConfig.charBAttrCmd,
        dataToWrite: _cmd(cmdId: HaloCmdId.readReady, valueNb: 0, id: id),
        toWaitNotifyFrom: _bleCompanion.haloBleConfig.charCAttrTmp,
      );

      if (readError != HaloErrorType.noError) {
        appLogger().w("A problem occurred when reading the values of the attribute: $id");
        return (readError, null);
      }

      var cleaned = data!;
      final last = HaloPayloadPacket.isLastElementPacket(cleaned);

      if (last == null) {
        // A device which pads the last packet with 0x00 is tolerated, as for the requests
        final tmp = HaloPayloadPacket.tryToCleanLastElementPacket(cleaned);

        if (tmp == null) {
          appLogger().w("The packet received for the attribute: $id is malformed");
          return (HaloErrorType.formatError, null);
        }

        cleaned = tmp;
      }

      isLast = last ?? true;
      packets.add(cleaned);
    }

    final payload = HaloPayloadPacket.fromDevice(packets);

    if (payload == null) {
      appLogger().w("The values received for the attribute: $id can't be parsed");
      return (HaloErrorType.formatError, null);
    }

    return (HaloErrorType.noError, HaloPacket(dataId: dataId, payload: payload));
  }

  /// This method allows to subscribe to the modification of a specific attribute thanks to the
  /// [HaloDataId] given
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the attributes to send update
  @override
  Future<HaloErrorType> subAttribute({required HaloDataId dataId}) =>
      _sendCmdProtected(cmdId: HaloCmdId.sub, id: dataId.id);

  /// This method allows to unsubscribe from the modification of a specific attribute thanks to the
  /// [HaloDataId] given
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the attributes to send update
  @override
  Future<HaloErrorType> unSubAttribute({required HaloDataId dataId}) =>
      _sendCmdProtected(cmdId: HaloCmdId.unSub, id: dataId.id);

  /// Sends the command [cmdId] which has no values, for the attribute [id]
  Future<HaloErrorType> _sendCmdProtected({required HaloCmdId cmdId, required int id}) =>
      _exchangeMutex.protect(() async {
        final (error, _) = await _sendCmd(cmdId: cmdId, valueNb: 0, id: id);

        return error;
      });

  /// Called when the device notifies the [flags] of the changed attributes on the characteristic A
  ///
  /// The flags are little endian, of any length from 2 bytes, bit `n` being the ID `n`. Each
  /// attribute whose flag is raised is read (which clears its flag in the device) and its new value
  /// is sent on the stream.
  Future<void> _onFlags(Uint8List flags) async {
    if (flags.length < 2) {
      appLogger().w("The attribute flags received are too short: ${flags.length} byte(s)");
      return;
    }

    for (var id = 0; id <= _maxValueNb && (id ~/ 8) < flags.length; ++id) {
      if ((flags[id ~/ 8] >> (id % 8)) & 1 == 0) {
        continue;
      }

      // The device knows the attribute by its ID alone, the upper layer maps it to its own value
      final (error, packet) = await _exchangeMutex.protect(
        () => _unsafeReadAttribute(HaloDataId<int>(id: id, value: id)),
      );

      if (error != HaloErrorType.noError) {
        appLogger().w("The attribute: $id has changed but we couldn't read it: $error");
      } else if (!attributeNewValueCtrl.isClosed) {
        attributeNewValueCtrl.add(packet!);
      }
    }
  }

  /// Builds the command `[CMD_ID, VALUE_NB, ATTR_ID]`
  Uint8List _cmd({required HaloCmdId cmdId, required int valueNb, required int id}) =>
      Uint8List.fromList([cmdId.rawValue, valueNb, id]);

  /// Writes the command to the device and returns its result: the error and the `VALUE_NB`
  Future<(HaloErrorType, int)> _sendCmd({
    required HaloCmdId cmdId,
    required int valueNb,
    required int id,
  }) => _writeAndWaitResult(
    char: _bleCompanion.haloBleConfig.charBAttrCmd,
    data: _cmd(cmdId: cmdId, valueNb: valueNb, id: id),
    id: id,
  );

  /// Writes the [data] in the characteristic [char] and waits for the result on the characteristic
  /// B, which has to be for the attribute [id]
  Future<(HaloErrorType, int)> _writeAndWaitResult({
    required AbstractHaloCharacteristic char,
    required Uint8List data,
    required int id,
  }) async {
    final (error, result) = await _bleCompanion.writeAndWaitNotifResult(
      toWriteInto: char,
      dataToWrite: data,
      toWaitNotifyFrom: _bleCompanion.haloBleConfig.charBAttrCmd,
    );

    if (error != HaloErrorType.noError) {
      return (error, 0);
    }

    if (result!.length != _cmdSize || result[2] != id) {
      appLogger().w("The result received for the attribute: $id is malformed: $result");
      return (HaloErrorType.formatError, 0);
    }

    return (HaloErrorType.parseValue(result[0]), result[1]);
  }

  /// Manage the close of all the resources at the end of the class
  /// Need to be called by the owner of the class
  @override
  Future<void> close() async {
    await _flagsSubscription.cancel();
    await super.close();
  }
}
