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
class HaloRequestToDeviceFeature<MaterialType> extends AbstractHaloFeature<MaterialType> {
  /// Class constructor
  HaloRequestToDeviceFeature({
    required super.haloManagerConfig,
  });

  /// Call function in the device and wait for the result
  /// With [materialType] you specify through what material you want to request the device
  Future<HaloRequestResult> callFunction({
    required MaterialType materialType,
    required HaloRequestParamsPacket request,
  }) =>
      _callAndRetryResult(
        requestId: request.requestId,
        materialType: materialType,
        callRequest: (service) => service.requestToDeviceMaterial.callFunction(request: request),
      );

  /// Call function with boolean return in the device and wait for the result
  /// With [materialType] you specify through what material you want to request the device
  Future<bool?> callBooleanFunction({
    required MaterialType materialType,
    required HaloRequestParamsPacket request,
  }) async =>
      _callOneReturnFunction<bool>(
        materialType: materialType,
        request: request,
        type: _OneReturnType.bool,
      );

  /// Call function with string return in the device and wait for the result
  /// With [materialType] you specify through what material you want to request the device
  Future<String?> callStringFunction({
    required MaterialType materialType,
    required HaloRequestParamsPacket request,
  }) async =>
      _callOneReturnFunction<String>(
        materialType: materialType,
        request: request,
        type: _OneReturnType.string,
      );

  /// Call function with signed integer return in the device and wait for the result
  /// With [materialType] you specify through what material you want to request the device
  Future<int?> callIntFunction({
    required MaterialType materialType,
    required HaloRequestParamsPacket request,
  }) async =>
      _callOneReturnFunction<int>(
        materialType: materialType,
        request: request,
        type: _OneReturnType.int,
      );

  /// Call function with unsigned integer return in the device and wait for the result
  /// With [materialType] you specify through what material you want to request the device
  Future<int?> callUIntFunction({
    required MaterialType materialType,
    required HaloRequestParamsPacket request,
  }) async =>
      _callOneReturnFunction<int>(
        materialType: materialType,
        request: request,
        type: _OneReturnType.uInt,
      );

  /// Call a function a specify the expected result type
  /// With [materialType] you specify through what material you want to request the device
  /// Be careful, the generic template has to match the [type] given
  Future<T?> _callOneReturnFunction<T>({
    required MaterialType materialType,
    required HaloRequestParamsPacket request,
    required _OneReturnType type,
  }) async {
    final result = await callFunction(materialType: materialType, request: request);

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
  /// With [materialType] you specify through what material you want to request the device
  Future<HaloErrorType> callProcedure({
    required MaterialType materialType,
    required HaloRequestParamsPacket request,
  }) =>
      _callAndRetryError(
        requestId: request.requestId,
        materialType: materialType,
        callRequest: (service) => service.requestToDeviceMaterial.callProcedure(request: request),
      );

  /// Call order in the device and doesn't wait for the result
  /// With [materialType] you specify through what material you want to request the device
  Future<HaloErrorType> callOrder({
    required MaterialType materialType,
    required HaloRequestParamsPacket request,
  }) =>
      _callAndRetryError(
        requestId: request.requestId,
        materialType: materialType,
        callRequest: (service) => service.requestToDeviceMaterial.callOrder(request: request),
      );

  /// This method calls the [_callAndRetry] and specify the case where the request returns a
  /// [HaloErrorType]
  Future<HaloErrorType> _callAndRetryError({
    required MaterialType materialType,
    required HaloRequestId requestId,
    required Future<HaloErrorType> Function(AbstractHaloMaterial) callRequest,
  }) =>
      _callAndRetry(
        materialType: materialType,
        requestId: requestId,
        errorDefaultResult: HaloErrorType.genericError,
        callRequest: callRequest,
        isMakingSensToRetry: (error) => error.isMakingSensToRetry,
      );

  /// This method calls the [_callAndRetry] and specify the case where the request returns a
  /// [HaloRequestResult]
  Future<HaloRequestResult> _callAndRetryResult({
    required MaterialType materialType,
    required HaloRequestId requestId,
    required Future<HaloRequestResult> Function(AbstractHaloMaterial) callRequest,
  }) =>
      _callAndRetry(
        materialType: materialType,
        requestId: requestId,
        errorDefaultResult: HaloRequestResult.error(
          requestId: requestId,
          error: HaloErrorType.genericError,
        ),
        callRequest: callRequest,
        isMakingSensToRetry: (result) => result.error.isMakingSensToRetry,
      );

  /// Call a request and retry if an error occurred and if it makes sens to do it
  /// With [materialType] you specify through what material you want to request the device
  /// The [errorDefaultResult] is the default error value to return if an error occurred in the
  /// process
  /// The real request is done through the [callRequest] param given, and to test if we need to
  /// retry, we use [isMakingSensToRetry]
  ///
  /// To note that [HaloErrorType.noError] is considered has a non need of retry because we succeed
  Future<T> _callAndRetry<T>({
    required MaterialType materialType,
    required HaloRequestId requestId,
    required T errorDefaultResult,
    required Future<T> Function(AbstractHaloMaterial) callRequest,
    required bool Function(T) isMakingSensToRetry,
  }) async {
    await haloManagerConfig.actionMutex.acquire();

    final service = haloManagerConfig.materialLayer.materialServices[materialType]?.haloMaterial;

    if (service == null) {
      appLogger().w("The material layer is unknown, we can't call request to the device");
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
}
