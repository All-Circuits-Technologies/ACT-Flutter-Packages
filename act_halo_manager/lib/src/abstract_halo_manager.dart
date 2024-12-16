// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_manager/src/features/halo_request_to_device_feature.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';

/// The HALO manager builder
abstract class AbstractHaloBuilder<T extends AbstractHaloManager>
    extends ManagerBuilder<T> {
  /// The class constructor
  AbstractHaloBuilder(super.factory);

  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// The HALO manager to override in order to specify the implementation of the protocol
/// The MaterialType template can be enum which list all the material layer which can be used to
/// exchange information with the device
abstract class AbstractHaloManager<MaterialType> extends AbstractManager {
  /// The config needed by the HALO manager
  late final HaloManagerConfig<MaterialType>? haloManagerConfig;

  /// The request to device feature
  late final HaloRequestToDeviceFeature<MaterialType>? requestToDeviceFeature;

  /// Class constructor
  AbstractHaloManager() : super();

  /// The init manager, the [initHaloManagerConfig] and [createRequestToDeviceFeature] are called
  /// in it
  @override
  Future<void> initManager() async {
    haloManagerConfig = await initHaloManagerConfig();

    if (haloManagerConfig == null) {
      appLogger().w(
          "A problem occurred when initializing the HALO manager and trying to get the "
          "configuration");
      return;
    }

    requestToDeviceFeature = await createRequestToDeviceFeature(
      haloManagerConfig: haloManagerConfig!,
    );
  }

  /// This method is helpful to define the Halo Manager config, if a problem occurred, the method
  /// has to return null
  @protected
  Future<HaloManagerConfig<MaterialType>?> initHaloManagerConfig();

  /// This method may be overridden to define a derived Request to Device feature (in the case, you
  /// define default request method)
  @protected
  Future<HaloRequestToDeviceFeature<MaterialType>>
      createRequestToDeviceFeature({
    required HaloManagerConfig<MaterialType> haloManagerConfig,
  }) async =>
          HaloRequestToDeviceFeature<MaterialType>(
            haloManagerConfig: haloManagerConfig,
          );

  /// To call to dispose the manager
  @override
  Future<void> dispose() async {
    await super.dispose();

    final futures = <Future>[];

    if (haloManagerConfig != null) {
      futures.add(haloManagerConfig!.materialLayer.close());
    }

    await Future.wait(futures);
  }
}

/// Helpful class to define all the needed configs for the HALO manager
class HaloManagerConfig<MaterialType> extends Equatable {
  /// The default value for [retryNbBeforeReturningError], if nothing else is given
  static const defaultRetryNumber = 2;

  /// The helper with all the material layers
  final AbstractHaloMaterialTypeHelper<MaterialType> materialLayer;

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
    required this.materialLayer,
    required this.requestIdHelper,
    this.retryNbBeforeReturningError = defaultRetryNumber,
  }) : actionMutex = Mutex();

  @override
  List<Object?> get props => [materialLayer, requestIdHelper];
}
