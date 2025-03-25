// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:equatable/equatable.dart';
import 'package:mutex/mutex.dart';

/// Helpful class to define all the needed configs for the HALO manager
class HaloManagerConfig<HardwareType> extends Equatable {
  /// The default value for [retryNbBeforeReturningError], if nothing else is given
  static const defaultRetryNumber = 2;

  /// The helper with all the hardware layers
  final AbstractHaloHwTypeHelper<HardwareType> hardwareLayer;

  /// The helper for the request ids
  final AbstractHaloRequestIdHelper requestIdHelper;

  /// Defines the number of time we retry to do things before considering that a problem occurred
  final int retryNbBeforeReturningError;

  /// This is the action mutex for all the activities done with the device via HALO
  /// A device can't do parallel task, you have to wait a finished process before beginning a new
  /// one. This mutex is helpful for that.
  final Mutex actionMutex;

  /// Class constructor
  HaloManagerConfig({
    required this.hardwareLayer,
    required this.requestIdHelper,
    this.retryNbBeforeReturningError = defaultRetryNumber,
  }) : actionMutex = Mutex();

  @override
  List<Object?> get props => [hardwareLayer, requestIdHelper];
}
