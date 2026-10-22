// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_manager/src/models/halo_manager_config.dart';
import 'package:flutter/foundation.dart';

/// Defines the abstract for all HALO features
abstract class AbstractHaloFeature<HardwareType> {
  /// The expected HALO manager config
  final HaloManagerConfig<HardwareType> haloManagerConfig;

  /// Class constructor
  AbstractHaloFeature({required this.haloManagerConfig});

  /// Call a request and retry if an error occurred and if it makes sens to do it
  /// With [hardwareType] you specify through what material you want to request the device
  /// The [errorDefaultResult] is the default error value to return if an error occurred in the
  /// process
  /// The real request is done through the [callRequest] param given, and to test if we need to
  /// retry, we use [isMakingSensToRetry]
  ///
  /// To note that [HaloErrorType.noError] is considered has a non need of retry because we succeed
  @protected
  Future<T> callAndRetry<T>({
    required HardwareType hardwareType,
    required T errorDefaultResult,
    required Future<T> Function(AbstractHaloHardware) callRequest,
    required bool Function(T) isMakingSensToRetry,
  }) async {
    await haloManagerConfig.actionMutex.acquire();

    try {
      final service = haloManagerConfig.hardwareLayer.hardwareServices[hardwareType]?.haloHardware;

      if (service == null) {
        appLogger().w("The hardware layer is unknown, we can't call the device");
        return errorDefaultResult;
      }

      var result = errorDefaultResult;
      var nbTry = 0;

      while (isMakingSensToRetry(result) && nbTry < haloManagerConfig.retryNbBeforeReturningError) {
        result = await callRequest(service);
        nbTry++;
      }

      return result;
    } finally {
      haloManagerConfig.actionMutex.release();
    }
  }
}
