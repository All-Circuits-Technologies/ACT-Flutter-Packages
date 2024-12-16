// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_halo_abstract/src/material_layer/abstract_halo_component_material.dart';
import 'package:act_halo_abstract/src/models/halo_data_id.dart';
import 'package:act_halo_abstract/src/models/halo_packet.dart';
import 'package:act_halo_abstract/src/types/halo_error_type.dart';
import 'package:flutter/foundation.dart';

/// This defines an abstract class for the attributes part of the material layer
abstract class AbstractHaloAttributeMaterial
    extends AbstractHaloComponentMaterial {
  /// This is the stream controller to manage new value received from the device
  final StreamController<HaloPacket> _attributeNewValueCtrl;

  /// This stream push new events when the device sends updated attribute value to the client
  Stream<HaloPacket> get attrNewValueStream => _attributeNewValueCtrl.stream;

  /// This allows the derived classes to send updated attribute values to upper classes
  @protected
  StreamController<HaloPacket> get attributeNewValueCtrl =>
      _attributeNewValueCtrl;

  /// Class constructor
  AbstractHaloAttributeMaterial()
      : _attributeNewValueCtrl = StreamController<HaloPacket>.broadcast();

  /// This method allows to write a specific attribute value to the device
  Future<HaloErrorType> writeAttribute({required HaloPacket packet});

  /// This method allows to read a specific attribute value from the device and thanks to the
  /// [HaloDataId] given
  Future<(HaloErrorType, HaloPacket?)> readAttribute(
      {required HaloDataId dataId});

  /// This method allows to subscribe to the modification of a specific attribute thanks to the
  /// [HaloDataId] given
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the attributes to send update
  Future<HaloErrorType> subAttribute({required HaloDataId dataId});

  /// This method allows to unsubscribe from the modification of a specific attribute thanks to the
  /// [HaloDataId] given
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the attributes to send update
  Future<HaloErrorType> unSubAttribute({required HaloDataId dataId});

  /// Manage the close of all the resources at the end of the class
  /// Need to be called by the owner of the class
  @override
  Future<void> close() async {
    final futures = <Future>[
      _attributeNewValueCtrl.close(),
    ];

    await Future.wait(futures);
  }
}
