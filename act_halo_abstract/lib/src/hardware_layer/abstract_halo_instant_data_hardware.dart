// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_halo_abstract/src/hardware_layer/abstract_halo_component_hardware.dart';
import 'package:act_halo_abstract/src/models/halo_data_id.dart';
import 'package:act_halo_abstract/src/models/halo_packet.dart';
import 'package:act_halo_abstract/src/types/halo_error_type.dart';
import 'package:flutter/foundation.dart';

/// This defines an abstract class for the instant data part of the hardware layer
abstract class AbstractHaloInstantDataHardware extends AbstractHaloComponentHardware {
  /// This is the stream controller to manage new value received from the device
  final StreamController<HaloPacket> _instantDataNewValueCtrl;

  /// This stream push new events when the device sends updated instant data value to the client
  Stream<HaloPacket> get instDataNewValueStream => _instantDataNewValueCtrl.stream;

  /// This allows the derived classes to send updated instant data values to upper classes
  @protected
  StreamController<HaloPacket> get instantDataNewValueCtrl => _instantDataNewValueCtrl;

  /// Class constructor
  AbstractHaloInstantDataHardware()
      : _instantDataNewValueCtrl = StreamController<HaloPacket>.broadcast();

  /// This method allows to write a specific instant data value to the device
  Future<HaloErrorType> writeInstantData({required HaloPacket packet});

  /// This method allows to read a specific instant data value from the device and thanks to the
  /// [HaloDataId] given
  Future<(HaloErrorType, HaloPacket?)> readInstantData({required HaloDataId dataId});

  /// This method allows to subscribe to the modification of a specific instant data thanks to the
  /// [HaloDataId] given
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the instant data to send update
  Future<HaloErrorType> subInstantData({required HaloDataId dataId});

  /// This method allows to unsubscribe from the modification of a specific instant data thanks to
  /// the [HaloDataId] given
  /// For performance issues, it's better if the device already knows (by hardcoded configs in
  /// the Firmware) what are the instant data to send update
  Future<HaloErrorType> unSubInstantData({required HaloDataId dataId});

  /// Manage the close of all the resources at the end of the class
  /// Need to be called by the owner of the class
  @override
  Future<void> close() async {
    final futures = <Future>[
      _instantDataNewValueCtrl.close(),
    ];

    await Future.wait(futures);
  }
}
