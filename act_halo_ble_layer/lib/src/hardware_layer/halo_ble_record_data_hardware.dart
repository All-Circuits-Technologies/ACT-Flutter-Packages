// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:typed_data';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/src/halo_ble_companion.dart';
import 'package:act_halo_ble_layer/src/hardware_layer/halo_ble_data_exchange.dart';

/// This is the BLE hardware layer for managing record data
///
/// It is the attribute service where an archive is identified by its key, an U2 sent LSB first
/// (the unique index, then the ID of the data): the commands go through the characteristic H, the
/// archives through the characteristic I and the characteristic G notifies the keys waiting to be
/// read (see [HaloBleDataExchange]).
class HaloBleRecordDataHardware extends AbstractHaloRecordDataHardware {
  /// The start and the end of a frame
  static const int _startByte = 0xC0;
  static const int _endByte = 0xC1;

  /// Marks an escaped byte, which is the following byte XOR [_escapeMask]
  static const int _escapeByte = 0x7D;
  static const int _escapeMask = 0x20;

  /// The size of a key on the wire
  static const int _keySize = 2;

  /// The exchanges of the record data service
  late final HaloBleDataExchange _exchange;

  /// The subscription to the keys notified on the characteristic G
  late final StreamSubscription<Uint8List> _keysSubscription;

  /// Class constructor
  HaloBleRecordDataHardware({required HaloBleCompanion bleCompanion}) {
    final config = bleCompanion.haloBleConfig;
    _exchange = HaloBleDataExchange(
      bleCompanion: bleCompanion,
      label: "record data",
      cmdChar: config.charHRecordCmd,
      tmpChar: config.charIRecordTmp,
    );
    _keysSubscription = config.charGRecordNotify.notificationStream.listen(_onKeys);
  }

  /// This method allows to acknowledge the reception of a record data and its storage (in order to
  /// authorize the device to free the resource linked to this record data).
  @override
  Future<HaloErrorType> ackRecordData({required HaloRecordKey recordKey}) =>
      _exchange.sendCmdNoValue(cmdId: HaloCmdId.ack, id: _wire(recordKey));

  /// This method allows to get all the record data linked to the [HaloDataId] given
  @override
  Future<(HaloErrorType, List<HaloRecordKey>?)> getAllRecordDataKeys({
    required HaloDataId dataId,
  }) async {
    final (error, packets) = await _exchange.readPackets(
      id: _wire(HaloRecordKey.getAll(dataId: dataId)),
    );

    if (error != HaloErrorType.noError) {
      return (error, null);
    }

    final keys = _parseKeys(Uint8List.fromList(packets!.expand((packet) => packet).toList()));

    if (keys == null || keys.any((key) => key.$2 != dataId.id)) {
      appLogger().w("The list of the keys of the record data ${dataId.id} is malformed");
      return (HaloErrorType.formatError, null);
    }

    return (
      HaloErrorType.noError,
      [for (final (index, _) in keys) HaloRecordKey<dynamic>(dataId: dataId, uniqueIndex: index)],
    );
  }

  /// This method allows to read a specific record data from the device and thanks to the
  /// [HaloRecordKey] given
  @override
  Future<(HaloErrorType, HaloRecordPacket?)> readRecordData({
    required HaloRecordKey recordKey,
  }) async {
    final (error, packets) = await _exchange.readPackets(id: _wire(recordKey));

    if (error != HaloErrorType.noError) {
      return (error, null);
    }

    final payload = HaloPayloadPacket.fromDevice(packets!);

    if (payload == null) {
      appLogger().w("The values received for the record ${recordKey.uniqueIndex} can't be parsed");
      return (HaloErrorType.formatError, null);
    }

    return (HaloErrorType.noError, HaloRecordPacket(recordKey: recordKey, payload: payload));
  }

  /// This method allows to subscribe to the modification of a specific kind of record data thanks
  /// to the [HaloDataId] given
  /// [onlyNotifyKey] is ignored: over BLE the device only notifies the keys
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the king of record data to send update
  @override
  Future<HaloErrorType> subRecordData({required HaloDataId dataId, bool onlyNotifyKey = false}) =>
      _exchange.sendCmdNoValue(
        cmdId: HaloCmdId.sub,
        id: _wire(HaloRecordKey.getAll(dataId: dataId)),
      );

  /// This method allows to unsubscribe from the modification of a specific kind of record data
  /// thanks to the [HaloDataId] given
  @override
  Future<HaloErrorType> unSubRecordData({required HaloDataId dataId}) => _exchange.sendCmdNoValue(
    cmdId: HaloCmdId.unSub,
    id: _wire(HaloRecordKey.getAll(dataId: dataId)),
  );

  /// The [key] as the device knows it: its unique index, then the ID of its data
  List<int> _wire(HaloRecordKey key) => [key.uniqueIndex, key.dataId.id];

  /// Cuts the [keys] into (unique index, ID of the data), two bytes each
  ///
  /// Returns null if the last key is cut
  List<(int, int)>? _splitKeys(Uint8List keys) {
    if (keys.length % _keySize != 0) {
      return null;
    }

    return [for (var idx = 0; idx < keys.length; idx += _keySize) (keys[idx], keys[idx + 1])];
  }

  /// Extracts the keys of the [frame] the device sends on I for a list of keys: `C0`, the keys end
  /// to end with the escaped bytes, `C1`
  ///
  /// Returns null if the frame is malformed
  List<(int, int)>? _parseKeys(Uint8List frame) {
    if (frame.length < 2 || frame.first != _startByte || frame.last != _endByte) {
      return null;
    }

    final keys = <int>[];

    for (var idx = 1; idx < frame.length - 1; ++idx) {
      if (frame[idx] != _escapeByte) {
        keys.add(frame[idx]);
      } else if (idx + 1 < frame.length - 1) {
        keys.add(frame[++idx] ^ _escapeMask);
      } else {
        return null;
      }
    }

    return _splitKeys(Uint8List.fromList(keys));
  }

  /// Called when the device notifies the keys waiting to be read on the characteristic G
  ///
  /// The keys are raw, without frame, oldest first; each one is given to the owner, who reads and
  /// acknowledges them. The device notifies an empty value when nothing is waiting.
  void _onKeys(Uint8List keys) {
    final split = _splitKeys(keys);

    if (split == null) {
      appLogger().w("The keys notified by the device are cut: ${keys.length} byte(s)");
      return;
    }

    for (final (index, id) in split) {
      if (!recordKeysNewValueCtrl.isClosed) {
        recordKeysNewValueCtrl.add(
          HaloRecordKey<dynamic>(
            dataId: HaloDataId<int>(id: id, value: id),
            uniqueIndex: index,
          ),
        );
      }
    }
  }

  /// Manage the close of all the resources at the end of the class
  /// Need to be called by the owner of the class
  @override
  Future<void> close() async {
    await _keysSubscription.cancel();
    await _exchange.close();
    await super.close();
  }
}
