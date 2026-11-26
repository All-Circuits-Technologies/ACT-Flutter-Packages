// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/src/hardware_layer/abstract_halo_component_hardware.dart';

/// This defines an abstract class for the request received from the device and to be executed in
/// this app.
// TODO(brolandeau): The method or elements of this class has to be defined
abstract class AbstractHaloRequestFromDeviceHardware extends AbstractHaloComponentHardware {
  /// Manage the close of all the resources at the end of the class
  /// Need to be called by the owner of the class
  @override
  Future<void> close() async {}
}
