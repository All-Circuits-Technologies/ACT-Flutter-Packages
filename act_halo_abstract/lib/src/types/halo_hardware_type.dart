// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/src/abstract_halo_hardware.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

/// This defines the kind of supported hardware layer
class HaloHardwareType<T> extends Equatable {
  /// The type of hardware
  final T type;

  /// The hardware layer
  final AbstractHaloHardware haloHardware;

  /// Class constructor
  const HaloHardwareType({
    required this.type,
    required this.haloHardware,
  });

  @override
  List<Object?> get props => [type, haloHardware];
}

/// Helpful class to manage [HaloHardwareType] enum
abstract class AbstractHaloHwTypeHelper<T> {
  /// The list of hardware services
  final Map<T, HaloHardwareType<T>> hardwareServices;

  /// Class constructor
  AbstractHaloHwTypeHelper({
    required this.hardwareServices,
  });

  /// Manage the close of all the resources at the end of the class
  /// Need to be called by the owner of the class
  /// It closes all the hardware services
  @mustCallSuper
  Future<void> close() async {
    final futures = <Future>[];

    for (final service in hardwareServices.values) {
      futures.add(service.haloHardware.close());
    }

    await Future.wait(futures);
  }
}
