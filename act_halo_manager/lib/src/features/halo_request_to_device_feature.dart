// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
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
  /// The result holds the HALO error if the call failed, [HaloErrorType.formatError] if the device
  /// hasn't answered exactly one value of the expected type, and the decoded value otherwise
  Future<ResultWithRequiredValue<HaloErrorType, bool>> callBooleanFunction({
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
  /// The result holds the HALO error if the call failed, [HaloErrorType.formatError] if the device
  /// hasn't answered exactly one value of the expected type, and the decoded value otherwise
  Future<ResultWithRequiredValue<HaloErrorType, String>> callStringFunction({
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
  /// The result holds the HALO error if the call failed, [HaloErrorType.formatError] if the device
  /// hasn't answered exactly one value of the expected type, and the decoded value otherwise
  Future<ResultWithRequiredValue<HaloErrorType, int>> callIntFunction({
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
  /// The result holds the HALO error if the call failed, [HaloErrorType.formatError] if the device
  /// hasn't answered exactly one value of the expected type, and the decoded value otherwise
  Future<ResultWithRequiredValue<HaloErrorType, int>> callUIntFunction({
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
  ///
  /// The returned status is the one of the call if it failed, [HaloErrorType.formatError] if the
  /// device hasn't answered exactly one value of the expected type, and [HaloErrorType.noError]
  /// with the decoded value otherwise
  Future<ResultWithRequiredValue<HaloErrorType, T>> _callOneReturnFunction<T>({
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

    if (result.isError) {
      appLogger().w("A problem occurred when calling the ${request.requestId} function, can't "
          "proceed");
      return ResultWithRequiredValue(status: result.status);
    }

    final resultPacket = result.value;

    if (resultPacket == null || resultPacket.elementsNb != 1) {
      appLogger().w("The ${request.requestId} call hasn't returned the expected return");
      return ResultWithRequiredValue(status: HaloErrorType.formatError);
    }

    final Object? decoded;

    switch (type) {
      case _OneReturnType.bool:
        decoded = resultPacket.getBoolean(0).data;
        break;
      case _OneReturnType.string:
        decoded = resultPacket.getString(0).data;
        break;
      case _OneReturnType.int:
        decoded = resultPacket.getInt(0).data;
        break;
      case _OneReturnType.uInt:
        decoded = resultPacket.getUInt(0).data;
        break;
    }

    if (decoded == null) {
      appLogger().w("The ${request.requestId} returned value isn't a $type");
      return ResultWithRequiredValue(status: HaloErrorType.formatError);
    }

    return ResultWithRequiredValue(
      status: HaloErrorType.noError,
      value: decoded as T,
    );
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

  /// This method calls the [callAndRetry] and specify the case where the request returns a
  /// [HaloErrorType]
  Future<HaloErrorType> _callAndRetryError({
    required HardwareType hardwareType,
    required MixinHaloRequestId requestId,
    required Future<HaloErrorType> Function(AbstractHaloHardware) callRequest,
  }) =>
      callAndRetry(
        hardwareType: hardwareType,
        errorDefaultResult: HaloErrorType.genericError,
        callRequest: callRequest,
      );

  /// This method calls the [callAndRetry] and specify the case where the request returns a
  /// [HaloRequestResult]
  Future<HaloRequestResult> _callAndRetryResult({
    required HardwareType hardwareType,
    required MixinHaloRequestId requestId,
    required Future<HaloRequestResult> Function(AbstractHaloHardware) callRequest,
  }) =>
      callAndRetry(
        hardwareType: hardwareType,
        errorDefaultResult: HaloRequestResult.error(
          requestId: requestId,
          status: HaloErrorType.genericError,
        ),
        callRequest: callRequest,
      );

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
