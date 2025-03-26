// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_manager/src/features/abstract_halo_feature.dart';

/// Defines the wanted returned type when calling function
enum _OneReturnType {
  bool,
  string,
  uInt,
  int,
}

/// This is the definition of feature when calling the requests
class HaloRequestToDeviceFeature<HardwareType> extends AbstractHaloFeature<HardwareType> {
  /// Class constructor
  HaloRequestToDeviceFeature({
    required super.haloManagerConfig,
  });

  /// Call function in the device and wait for the result
  /// With [hardwareType] you specify through what hardware you want to request the device
  Future<HaloRequestResult> callFunction({
    required HardwareType hardwareType,
    required HaloRequestParamsPacket request,
    Duration? executionTimeout,
  }) =>
      _callAndRetryResult(
        requestId: request.requestId,
        hardwareType: hardwareType,
        callRequest: (service) => service.requestToDeviceHardware.callFunction(
          request: request,
          executionTimeout: _getExecutionTimeout(request.requestId, executionTimeout),
        ),
      );

  /// Call function with boolean return in the device and wait for the result
  /// With [hardwareType] you specify through what hardware you want to request the device
  Future<bool?> callBooleanFunction({
    required HardwareType hardwareType,
    required HaloRequestParamsPacket request,
    Duration? executionTimeout,
  }) async =>
      _callOneReturnFunction<bool>(
        hardwareType: hardwareType,
        request: request,
        type: _OneReturnType.bool,
        executionTimeout: executionTimeout,
      );

  /// Call function with string return in the device and wait for the result
  /// With [hardwareType] you specify through what hardware you want to request the device
  Future<String?> callStringFunction({
    required HardwareType hardwareType,
    required HaloRequestParamsPacket request,
    Duration? executionTimeout,
  }) async =>
      _callOneReturnFunction<String>(
        hardwareType: hardwareType,
        request: request,
        type: _OneReturnType.string,
        executionTimeout: executionTimeout,
      );

  /// Call function with signed integer return in the device and wait for the result
  /// With [hardwareType] you specify through what hardware you want to request the device
  Future<int?> callIntFunction({
    required HardwareType hardwareType,
    required HaloRequestParamsPacket request,
    Duration? executionTimeout,
  }) async =>
      _callOneReturnFunction<int>(
        hardwareType: hardwareType,
        request: request,
        type: _OneReturnType.int,
        executionTimeout: executionTimeout,
      );

  /// Call function with unsigned integer return in the device and wait for the result
  /// With [hardwareType] you specify through what hardware you want to request the device
  Future<int?> callUIntFunction({
    required HardwareType hardwareType,
    required HaloRequestParamsPacket request,
    Duration? executionTimeout,
  }) async =>
      _callOneReturnFunction<int>(
        hardwareType: hardwareType,
        request: request,
        type: _OneReturnType.uInt,
        executionTimeout: executionTimeout,
      );

  /// Call a function a specify the expected result type
  /// With [hardwareType] you specify through what hardware you want to request the device
  /// Be careful, the generic template has to match the [type] given
  Future<T?> _callOneReturnFunction<T>({
    required HardwareType hardwareType,
    required HaloRequestParamsPacket request,
    required _OneReturnType type,
    Duration? executionTimeout,
  }) async {
    final result = await callFunction(
      hardwareType: hardwareType,
      request: request,
      executionTimeout: executionTimeout,
    );

    if (result.error != HaloErrorType.noError) {
      appLogger().w("A problem occurred when calling the ${request.requestId} function, can't "
          "proceed");
      return null;
    }

    final resultPacket = result.result!;

    if (resultPacket.elementsNb != 1) {
      appLogger().w("The ${request.requestId} call hasn't returned the expected return");
      return null;
    }

    T? value;

    switch (type) {
      case _OneReturnType.bool:
        value = result.result!.getBoolean(0)?.$1 as T?;
        break;
      case _OneReturnType.string:
        value = result.result!.getString(0)?.$1 as T?;
        break;
      case _OneReturnType.int:
        value = result.result!.getInt(0)?.$1 as T?;
        break;
      case _OneReturnType.uInt:
        value = result.result!.getUInt(0)?.$1 as T?;
        break;
    }

    if (value == null) {
      appLogger().w("The ${request.requestId} returned value isn't a $type");
      return null;
    }

    return value;
  }

  /// Call procedure in the device and wait for the result
  /// With [hardwareType] you specify through what hardware you want to request the device
  Future<HaloErrorType> callProcedure({
    required HardwareType hardwareType,
    required HaloRequestParamsPacket request,
    Duration? executionTimeout,
  }) =>
      _callAndRetryError(
        requestId: request.requestId,
        hardwareType: hardwareType,
        callRequest: (service) => service.requestToDeviceHardware.callProcedure(
          request: request,
          executionTimeout: _getExecutionTimeout(request.requestId, executionTimeout),
        ),
      );

  /// Call order in the device and doesn't wait for the result
  /// With [hardwareType] you specify through what hardware you want to request the device
  Future<HaloErrorType> callOrder({
    required HardwareType hardwareType,
    required HaloRequestParamsPacket request,
  }) =>
      _callAndRetryError(
        requestId: request.requestId,
        hardwareType: hardwareType,
        callRequest: (service) => service.requestToDeviceHardware.callOrder(request: request),
      );

  /// This method calls the [_callAndRetry] and specify the case where the request returns a
  /// [HaloErrorType]
  Future<HaloErrorType> _callAndRetryError({
    required HardwareType hardwareType,
    required MixinHaloRequestId requestId,
    required Future<HaloErrorType> Function(AbstractHaloHardware) callRequest,
  }) =>
      _callAndRetry(
        hardwareType: hardwareType,
        requestId: requestId,
        errorDefaultResult: HaloErrorType.genericError,
        callRequest: callRequest,
        isMakingSensToRetry: (error) => error.isMakingSensToRetry,
      );

  /// This method calls the [_callAndRetry] and specify the case where the request returns a
  /// [HaloRequestResult]
  Future<HaloRequestResult> _callAndRetryResult({
    required HardwareType hardwareType,
    required MixinHaloRequestId requestId,
    required Future<HaloRequestResult> Function(AbstractHaloHardware) callRequest,
  }) =>
      _callAndRetry(
        hardwareType: hardwareType,
        requestId: requestId,
        errorDefaultResult: HaloRequestResult.error(
          requestId: requestId,
          error: HaloErrorType.genericError,
        ),
        callRequest: callRequest,
        isMakingSensToRetry: (result) => result.error.isMakingSensToRetry,
      );

  /// Call a request and retry if an error occurred and if it makes sens to do it
  /// With [hardwareType] you specify through what material you want to request the device
  /// The [errorDefaultResult] is the default error value to return if an error occurred in the
  /// process
  /// The real request is done through the [callRequest] param given, and to test if we need to
  /// retry, we use [isMakingSensToRetry]
  ///
  /// To note that [HaloErrorType.noError] is considered has a non need of retry because we succeed
  Future<T> _callAndRetry<T>({
    required HardwareType hardwareType,
    required MixinHaloRequestId requestId,
    required T errorDefaultResult,
    required Future<T> Function(AbstractHaloHardware) callRequest,
    required bool Function(T) isMakingSensToRetry,
  }) async {
    await haloManagerConfig.actionMutex.acquire();

    final service = haloManagerConfig.hardwareLayer.hardwareServices[hardwareType]?.haloHardware;

    if (service == null) {
      appLogger().w("The hardware layer is unknown, we can't call request to the device");
      haloManagerConfig.actionMutex.release();
      return errorDefaultResult;
    }

    var result = errorDefaultResult;
    var nbTry = 0;

    while (isMakingSensToRetry(result) && nbTry < haloManagerConfig.retryNbBeforeReturningError) {
      result = await callRequest(service);
      nbTry++;
    }

    haloManagerConfig.actionMutex.release();

    return result;
  }

  /// Get the request execution timeout, the [forcedExecutionTimeout] value prevails on the
  /// [haloManagerConfig] `requestIdHelper.overriddenExecutionTimeout` which prevails on the
  /// [haloManagerConfig] `requestIdHelper.defaultRequestTimeout` which prevails on the default
  /// execution timeout
  Duration _getExecutionTimeout(MixinHaloRequestId requestId, Duration? forcedExecutionTimeout) =>
      forcedExecutionTimeout ??
      haloManagerConfig.requestIdHelper.overriddenExecutionTimeout[requestId.uniqueId] ??
      haloManagerConfig.requestIdHelper.defaultRequestTimeout ??
      AbstractHaloRequestToDeviceHardware.defaultExecutionTimeout;
}
