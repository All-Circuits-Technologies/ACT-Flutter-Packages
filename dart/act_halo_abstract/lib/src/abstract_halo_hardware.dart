// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_halo_abstract/src/hardware_layer/abstract_halo_attribute_hardware.dart';
import 'package:act_halo_abstract/src/hardware_layer/abstract_halo_component_hardware.dart';
import 'package:act_halo_abstract/src/hardware_layer/abstract_halo_instant_data_hardware.dart';
import 'package:act_halo_abstract/src/hardware_layer/abstract_halo_record_data_hardware.dart';
import 'package:act_halo_abstract/src/hardware_layer/abstract_halo_request_from_device_hardware.dart';
import 'package:act_halo_abstract/src/hardware_layer/abstract_halo_request_to_device_hardware.dart';

/// This class defines what a HALO hardware layer must contain and overrides
abstract class AbstractHaloHardware extends AbstractHaloComponentHardware {
  /// Defines how to manage attributes in the hardware layer
  final AbstractHaloAttributeHardware attributeHardware;

  /// Defines how to manage instant data in the hardware layer
  final AbstractHaloInstantDataHardware instantDataHardware;

  /// Defines how to manage record data in the hardware layer
  final AbstractHaloRecordDataHardware recordDataHardware;

  /// Defines how to manage requests (which are called from the device, to be executed in the
  /// client) in the hardware layer
  final AbstractHaloRequestFromDeviceHardware requestFromDeviceHardware;

  /// Defines how to manage requests (which are called from the client, to be executed in the
  /// device) in the hardware layer
  final AbstractHaloRequestToDeviceHardware requestToDeviceHardware;

  /// Class constructor with how the hardware layer is defined
  AbstractHaloHardware({
    required this.attributeHardware,
    required this.instantDataHardware,
    required this.recordDataHardware,
    required this.requestFromDeviceHardware,
    required this.requestToDeviceHardware,
  });

  /// Manage the close of all the resources at the end of the class
  /// Need to be called by the owner of the class
  @override
  Future<void> close() async {
    final futures = <Future>[
      attributeHardware.close(),
      instantDataHardware.close(),
      recordDataHardware.close(),
      requestFromDeviceHardware.close(),
      requestToDeviceHardware.close(),
    ];

    await Future.wait(futures);
  }
}
