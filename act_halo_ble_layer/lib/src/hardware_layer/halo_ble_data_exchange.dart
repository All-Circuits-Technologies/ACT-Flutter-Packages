// SPDX-FileCopyrightText: 2026 Damien Manceau <damien.manceau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/src/characteristics/mix_char_notification.dart';
import 'package:act_halo_ble_layer/src/halo_ble_companion.dart';
import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';

/// The exchanges of a service of data of the device (attributes, instant data or historical data)
/// over BLE
///
/// The commands are written on the command characteristic as `[CMD_ID, VALUE_NB, ID...]`, the
/// device answers on it as `[ERROR_ENUM, VALUE_NB, ID...]` and the values go through the exchange
/// characteristic. The ID is one byte for an attribute or an instant data, two bytes (the key,
/// LSB first) for a historical data. For the first ones the flags characteristic notifies the
/// flags of the data which changed.
class HaloBleDataExchange {
  /// The size of the commands and of the results without their ID
  static const int _cmdHeaderSize = 2;

  /// The most values a data holds, `VALUE_NB` being an U1
  static const int _maxValueNb = 255;

  /// The ble companion to use in order to exchange
  final HaloBleCompanion _bleCompanion;

  /// What the service exchanges, for the logs
  final String _label;

  /// The characteristic of the commands and of their results (B or E)
  final MixCharNotification _cmdChar;

  /// The characteristic of the exchange area (C or F)
  final MixCharNotification _tmpChar;

  /// Mutex which keeps the steps of two exchanges from mixing on the characteristics B and C
  final Mutex _exchangeMutex;

  /// The subscription to the flags notified on the characteristic A
  late final StreamSubscription<Uint8List>? _flagsSubscription;

  /// Class constructor
  ///
  /// The [flags] are given by the services which have flags: the characteristic which notifies
  /// them and what is called with the new value of every data whose flag was raised
  HaloBleDataExchange({
    required HaloBleCompanion bleCompanion,
    required String label,
    required MixCharNotification cmdChar,
    required MixCharNotification tmpChar,
    ({MixCharNotification char, void Function(HaloPacket packet) onNewValue})? flags,
  }) : _bleCompanion = bleCompanion,
       _label = label,
       _cmdChar = cmdChar,
       _tmpChar = tmpChar,
       _exchangeMutex = Mutex() {
    _flagsSubscription = flags?.char.notificationStream.listen(
      (value) => _onFlags(value, flags.onNewValue),
    );
  }

  /// Writes the [packet] to the device
  ///
  /// The frame is cut in packets of the size of the companion, each one is acknowledged by the
  /// device
  Future<HaloErrorType> write({required HaloPacket packet}) => _exchangeMutex.protect(() async {
    final id = [packet.dataId.id];
    final valueNb = packet.payload.elementsNb;

    if (valueNb == 0 || valueNb > _maxValueNb) {
      appLogger().w("The $_label $id can't be written with $valueNb values");
      return HaloErrorType.formatError;
    }

    final (error, _) = await _sendCmd(cmdId: HaloCmdId.write, valueNb: valueNb, id: id);

    if (error != HaloErrorType.noError) {
      appLogger().w("The device refused to write the $_label: $id");
      return error;
    }

    var lastError = HaloErrorType.noError;
    for (final data in packet.payload.getDataToSend(maxPacketSize: _bleCompanion.packetSize)) {
      // The device acknowledges every packet, the last one with the result of the write
      (lastError, _) = await _writeAndWaitResult(char: _tmpChar, data: data, id: id);

      if (lastError != HaloErrorType.noError) {
        appLogger().w("A problem occurred when writing the $_label: $id");
        return lastError;
      }
    }

    return lastError;
  });

  /// Reads the value of [dataId] from the device
  Future<(HaloErrorType, HaloPacket?)> read({required HaloDataId dataId}) =>
      _exchangeMutex.protect(() => _unsafeRead(dataId));

  /// Reads [dataId], the caller holds the [_exchangeMutex]
  Future<(HaloErrorType, HaloPacket?)> _unsafeRead(HaloDataId dataId) async {
    final (error, packets) = await _unsafeReadPackets([dataId.id]);

    if (error != HaloErrorType.noError) {
      return (error, null);
    }

    final payload = HaloPayloadPacket.fromDevice(packets!);

    if (payload == null) {
      appLogger().w("The values received for the $_label: ${dataId.id} can't be parsed");
      return (HaloErrorType.formatError, null);
    }

    return (HaloErrorType.noError, HaloPacket(dataId: dataId, payload: payload));
  }

  /// Reads the packets which hold the frame of [id], as the device sends them
  Future<(HaloErrorType, List<Uint8List>?)> readPackets({required List<int> id}) =>
      _exchangeMutex.protect(() => _unsafeReadPackets(id));

  /// Reads the packets of [id], the caller holds the [_exchangeMutex]
  Future<(HaloErrorType, List<Uint8List>?)> _unsafeReadPackets(List<int> id) async {
    final (error, _) = await _sendCmd(cmdId: HaloCmdId.read, valueNb: 0, id: id);

    if (error != HaloErrorType.noError) {
      appLogger().w("A problem occurred when asking to read the $_label: $id");
      return (error, null);
    }

    final packets = <Uint8List>[];
    var isLast = false;

    while (!isLast) {
      final (readError, data) = await _bleCompanion.writeAndWaitNotifResult(
        toWriteInto: _cmdChar,
        dataToWrite: _cmd(cmdId: HaloCmdId.readReady, valueNb: 0, id: id),
        toWaitNotifyFrom: _tmpChar,
      );

      if (readError != HaloErrorType.noError) {
        appLogger().w("A problem occurred when reading the values of the $_label: $id");
        return (readError, null);
      }

      var cleaned = data!;
      final last = HaloPayloadPacket.isLastElementPacket(cleaned);

      if (last == null) {
        // A device which pads the last packet with 0x00 is tolerated, as for the requests
        final tmp = HaloPayloadPacket.tryToCleanLastElementPacket(cleaned);

        if (tmp == null) {
          appLogger().w("The packet received for the $_label: $id is malformed");
          return (HaloErrorType.formatError, null);
        }

        cleaned = tmp;
      }

      isLast = last ?? true;
      packets.add(cleaned);
    }

    return (HaloErrorType.noError, packets);
  }

  /// Sends the command [cmdId] which has no values, for [id], and returns its result
  Future<HaloErrorType> sendCmdNoValue({required HaloCmdId cmdId, required List<int> id}) =>
      _exchangeMutex.protect(() async {
        final (error, _) = await _sendCmd(cmdId: cmdId, valueNb: 0, id: id);

        return error;
      });

  /// Called when the device notifies the [flags] of the changed data on the flags characteristic
  ///
  /// The flags are little endian, of any length from 2 bytes, bit `n` being the ID `n`. Each data
  /// whose flag is raised is read (which clears its flag in the device) and its new value is given
  /// to [onNewValue]. A read which fails is logged and the next flag is handled.
  Future<void> _onFlags(Uint8List flags, void Function(HaloPacket packet) onNewValue) async {
    if (flags.length < 2) {
      appLogger().w("The $_label flags received are too short: ${flags.length} byte(s)");
      return;
    }

    for (var id = 0; id <= _maxValueNb && (id ~/ 8) < flags.length; ++id) {
      if ((flags[id ~/ 8] >> (id % 8)) & 1 == 0) {
        continue;
      }

      try {
        // The device knows the data by its ID alone, the upper layer maps it to its own value
        final (error, packet) = await _exchangeMutex.protect(
          () => _unsafeRead(HaloDataId<int>(id: id, value: id)),
        );

        if (error != HaloErrorType.noError) {
          appLogger().w("The $_label: $id has changed but we couldn't read it: $error");
        } else {
          onNewValue(packet!);
        }
      } catch (e) {
        // A failing read must neither stop the other ones nor the listening of the flags
        appLogger().w("The $_label: $id has changed but reading it threw: $e");
      }
    }
  }

  /// Builds the command `[CMD_ID, VALUE_NB, ID...]`
  Uint8List _cmd({required HaloCmdId cmdId, required int valueNb, required List<int> id}) =>
      Uint8List.fromList([cmdId.rawValue, valueNb, ...id]);

  /// Writes the command to the device and returns its result: the error and the `VALUE_NB`
  Future<(HaloErrorType, int)> _sendCmd({
    required HaloCmdId cmdId,
    required int valueNb,
    required List<int> id,
  }) => _writeAndWaitResult(
    char: _cmdChar,
    data: _cmd(cmdId: cmdId, valueNb: valueNb, id: id),
    id: id,
  );

  /// Writes the [data] in the characteristic [char] and waits for the result on the characteristic
  /// B, which has to be for [id]
  Future<(HaloErrorType, int)> _writeAndWaitResult({
    required MixCharNotification char,
    required Uint8List data,
    required List<int> id,
  }) async {
    final (error, result) = await _bleCompanion.writeAndWaitNotifResult(
      toWriteInto: char,
      dataToWrite: data,
      toWaitNotifyFrom: _cmdChar,
    );

    if (error != HaloErrorType.noError) {
      return (error, 0);
    }

    if (result!.length != _cmdHeaderSize + id.length ||
        !listEquals(result.sublist(_cmdHeaderSize), id)) {
      appLogger().w("The result received for the $_label: $id is malformed: $result");
      return (HaloErrorType.formatError, 0);
    }

    return (HaloErrorType.parseValue(result[0]), result[1]);
  }

  /// Stops listening to the flags, to call by the owner of the class when it closes
  Future<void> close() async => _flagsSubscription?.cancel();
}
