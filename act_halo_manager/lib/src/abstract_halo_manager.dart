// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_manager/src/features/halo_request_to_device_feature.dart';
import 'package:act_halo_manager/src/models/halo_manager_config.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/foundation.dart';

/// The HALO manager builder
abstract class AbstractHaloBuilder<T extends AbstractHaloManager> extends AbsManagerBuilder<T> {
  /// The class constructor
  AbstractHaloBuilder(super.factory);

  /// {@macro act_abstract_manager.AbsManagerBuilder.dependsOn}
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// The HALO manager to override in order to specify the implementation of the protocol
/// The HardwareType template can be enum which list all the hardware layer which can be used to
/// exchange information with the device
abstract class AbstractHaloManager<HardwareType> extends AbsWithLifeCycle {
  /// The config needed by the HALO manager
  late final HaloManagerConfig<HardwareType>? haloManagerConfig;

  /// The request to device feature
  late final HaloRequestToDeviceFeature<HardwareType>? requestToDeviceFeature;

  /// Class constructor
  AbstractHaloManager() : super();

  /// The init manager, the [initHaloManagerConfig] and [createRequestToDeviceFeature] are called
  /// in it
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    haloManagerConfig = await initHaloManagerConfig();

    if (haloManagerConfig == null) {
      appLogger().w("A problem occurred when initializing the HALO manager and trying to get the "
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
  Future<HaloManagerConfig<HardwareType>?> initHaloManagerConfig();

  /// This method may be overridden to define a derived Request to Device feature (in the case, you
  /// define default request method)
  @protected
  Future<HaloRequestToDeviceFeature<HardwareType>> createRequestToDeviceFeature({
    required HaloManagerConfig<HardwareType> haloManagerConfig,
  }) async =>
      HaloRequestToDeviceFeature<HardwareType>(
        haloManagerConfig: haloManagerConfig,
      );

  /// To call to dispose the manager
  @override
  Future<void> disposeLifeCycle() async {
    final futures = <Future>[];

    if (haloManagerConfig != null) {
      futures.add(haloManagerConfig!.hardwareLayer.close());
    }

    await Future.wait(futures);
    await super.disposeLifeCycle();
  }
}
