// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_halo_abstract/src/material_layer/abstract_halo_attribute_material.dart';
import 'package:act_halo_abstract/src/material_layer/abstract_halo_component_material.dart';
import 'package:act_halo_abstract/src/material_layer/abstract_halo_instant_data_material.dart';
import 'package:act_halo_abstract/src/material_layer/abstract_halo_record_data_material.dart';
import 'package:act_halo_abstract/src/material_layer/abstract_halo_request_from_device_material.dart';
import 'package:act_halo_abstract/src/material_layer/abstract_halo_request_to_device_material.dart';

/// This class defines what a HALO material layer must contain and overrides
abstract class AbstractHaloMaterial extends AbstractHaloComponentMaterial {
  /// Defines how to manage attributes in the material layer
  final AbstractHaloAttributeMaterial attributeMaterial;

  /// Defines how to manage instant data in the material layer
  final AbstractHaloInstantDataMaterial instantDataMaterial;

  /// Defines how to manage record data in the material layer
  final AbstractHaloRecordDataMaterial recordDataMaterial;

  /// Defines how to manage requests (which are called from the device, to be executed in the
  /// client) in the material layer
  final AbstractHaloRequestFromDeviceMaterial requestFromDeviceMaterial;

  /// Defines how to manage requests (which are called from the client, to be executed in the
  /// device) in the material layer
  final AbstractHaloRequestToDeviceMaterial requestToDeviceMaterial;

  /// Class constructor with how the material layer is defined
  AbstractHaloMaterial({
    required this.attributeMaterial,
    required this.instantDataMaterial,
    required this.recordDataMaterial,
    required this.requestFromDeviceMaterial,
    required this.requestToDeviceMaterial,
  });

  /// Manage the close of all the resources at the end of the class
  /// Need to be called by the owner of the class
  @override
  Future<void> close() async {
    final futures = <Future>[
      attributeMaterial.close(),
      instantDataMaterial.close(),
      recordDataMaterial.close(),
      requestFromDeviceMaterial.close(),
      requestToDeviceMaterial.close(),
    ];

    await Future.wait(futures);
  }
}
