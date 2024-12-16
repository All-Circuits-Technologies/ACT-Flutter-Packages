// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_halo_abstract/src/material_layer/abstract_halo_component_material.dart';
import 'package:act_halo_abstract/src/models/halo_data_id.dart';
import 'package:act_halo_abstract/src/models/halo_record_key.dart';
import 'package:act_halo_abstract/src/models/halo_record_packet.dart';
import 'package:act_halo_abstract/src/types/halo_error_type.dart';
import 'package:flutter/foundation.dart';

/// This defines an abstract class for the record data part of the material layer
abstract class AbstractHaloRecordDataMaterial
    extends AbstractHaloComponentMaterial {
  /// This is the stream controller to manage new value received from the device
  final StreamController<HaloRecordPacket> _recordDataNewValueCtrl;

  /// This stream push new events when the device sends updated record data value to the client
  Stream<HaloRecordPacket> get recordDataNewValueStream =>
      _recordDataNewValueCtrl.stream;

  /// This allows the derived classes to send updated record data values to upper classes
  @protected
  StreamController<HaloRecordPacket> get recordDataNewValueCtrl =>
      _recordDataNewValueCtrl;

  /// This is the stream controller to manage new keys received from the device
  final StreamController<HaloRecordKey> _recordKeysNewValueCtrl;

  /// This stream push new events when the device sends updated record key to the client
  Stream<HaloRecordKey> get recordKeysNewValueStream =>
      _recordKeysNewValueCtrl.stream;

  /// This allows the derived classes to send updated record key to upper classes
  @protected
  StreamController<HaloRecordKey> get recordKeysNewValueCtrl =>
      _recordKeysNewValueCtrl;

  /// Class constructor
  AbstractHaloRecordDataMaterial()
      : _recordDataNewValueCtrl =
            StreamController<HaloRecordPacket>.broadcast(),
        _recordKeysNewValueCtrl = StreamController<HaloRecordKey>.broadcast();

  /// This method allows to subscribe to the modification of a specific kind of record data thanks
  /// to the [HaloDataId] given
  /// [onlyNotifyKey] allows to specify if the device send the complete value when a new record
  /// appears or only its key.
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the king of record data to send update
  Future<HaloErrorType> subRecordData(
      {required HaloDataId dataId, bool onlyNotifyKey = false});

  /// This method allows to unsubscribe from the modification of a specific kind of record data
  /// thanks to the [HaloDataId] given
  /// [onlyNotifyKey] allows to specify if the device send the complete value when a new record
  /// appears or only its key.
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the king of record data to send update
  Future<HaloErrorType> unSubRecordData({required HaloDataId dataId});

  /// This method allows to read a specific record data from the device and thanks to the
  /// [HaloRecordKey] given
  Future<(HaloErrorType, HaloRecordPacket?)> readRecordData({
    required HaloRecordKey recordKey,
  });

  /// This method allows to get all the record data linked to the [HaloDataId] given
  Future<(HaloErrorType, List<HaloRecordKey>?)> getAllRecordDataKeys({
    required HaloDataId dataId,
  });

  /// This method allows to acknowledge the reception of a record data and its storage (in order to
  /// authorize the device to free the resource linked to this record data).
  Future<HaloErrorType> ackRecordData({required HaloRecordKey recordKey});

  /// Manage the close of all the resources at the end of the class
  /// Need to be called by the owner of the class
  @override
  Future<void> close() async {
    final futures = <Future>[
      _recordDataNewValueCtrl.close(),
      _recordKeysNewValueCtrl.close(),
    ];

    await Future.wait(futures);
  }
}
