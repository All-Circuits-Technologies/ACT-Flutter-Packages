// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/src/halo_ble_companion.dart';

/// This is the BLE hardware layer for managing record data
class HaloBleRecordDataHardware extends AbstractHaloRecordDataHardware {
  /// Class constructor
  HaloBleRecordDataHardware({
    // We keep the parameter for future, for now the class is only a pattern
    // ignore: avoid_unused_constructor_parameters
    required HaloBleCompanion bleCompanion,
  });

  /// This method allows to acknowledge the reception of a record data and its storage (in order to
  /// authorize the device to free the resource linked to this record data).
  @override
  Future<HaloErrorType> ackRecordData({required HaloRecordKey recordKey}) {
    // TODO(brolandeau): implement ackRecordData
    throw UnimplementedError();
  }

  /// This method allows to get all the record data linked to the [HaloDataId] given
  @override
  Future<(HaloErrorType, List<HaloRecordKey>?)> getAllRecordDataKeys({required HaloDataId dataId}) {
    // TODO(brolandeau): implement getAllRecordDataKeys
    throw UnimplementedError();
  }

  /// This method allows to read a specific record data from the device and thanks to the
  /// [HaloRecordKey] given
  @override
  Future<(HaloErrorType, HaloRecordPacket?)> readRecordData({required HaloRecordKey recordKey}) {
    // TODO(brolandeau): implement readRecordData
    throw UnimplementedError();
  }

  /// This method allows to subscribe to the modification of a specific kind of record data thanks
  /// to the [HaloDataId] given
  /// [onlyNotifyKey] allows to specify if the device send the complete value when a new record
  /// appears or only its key.
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the king of record data to send update
  @override
  Future<HaloErrorType> subRecordData({required HaloDataId dataId, bool onlyNotifyKey = false}) {
    // TODO(brolandeau): implement subRecordData
    throw UnimplementedError();
  }

  /// This method allows to unsubscribe from the modification of a specific kind of record data
  /// thanks to the [HaloDataId] given
  /// [onlyNotifyKey] allows to specify if the device send the complete value when a new record
  /// appears or only its key.
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the king of record data to send update
  @override
  Future<HaloErrorType> unSubRecordData({required HaloDataId dataId}) {
    // TODO(brolandeau): implement unSubRecordData
    throw UnimplementedError();
  }
}
