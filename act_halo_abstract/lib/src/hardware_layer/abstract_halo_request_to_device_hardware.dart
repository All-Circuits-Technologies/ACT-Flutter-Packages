// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/src/hardware_layer/abstract_halo_component_hardware.dart';
import 'package:act_halo_abstract/src/models/halo_request_params_packet.dart';
import 'package:act_halo_abstract/src/models/halo_request_result.dart';
import 'package:act_halo_abstract/src/types/halo_error_type.dart';
import 'package:act_halo_abstract/src/types/halo_request_type.dart';
import 'package:flutter/foundation.dart';

/// This defines an abstract class for the request send to the device and which has to be executed
/// in the device.
abstract class AbstractHaloRequestToDeviceHardware extends AbstractHaloComponentHardware {
  /// This is the default execution timeout to use when waiting for a response from the device after
  /// having requested an action.
  static const defaultExecutionTimeout = Duration(minutes: 1);

  /// This method allows to call a function in the device, a function always returns a value
  Future<HaloRequestResult> callFunction({
    required HaloRequestParamsPacket request,
    Duration executionTimeout = defaultExecutionTimeout,
  }) async {
    final error = _verifyRequest(
      request: request,
      expectedType: HaloRequestType.function,
    );
    if (error != null) {
      return error;
    }

    final result = await implCallFunction(
      request: request,
      executionTimeout: executionTimeout,
    );

    if (result.error == HaloErrorType.noError && result.result == null) {
      appLogger().w("The function: ${request.requestId} succeeds but no result has been returned");
      return HaloRequestResult.error(
        requestId: request.requestId,
        error: HaloErrorType.genericError,
      );
    }

    return result;
  }

  /// This is the method to override in order to define the implementation of the calling function
  /// feature.
  /// When this method is called, we have verified if the request id given is a function
  @protected
  Future<HaloRequestResult> implCallFunction({
    required HaloRequestParamsPacket request,
    required Duration executionTimeout,
  });

  /// This method allows to call a procedure in the device, a procedure doesn't return a value but
  /// the device says if everything goes right or not
  Future<HaloErrorType> callProcedure({
    required HaloRequestParamsPacket request,
    Duration executionTimeout = defaultExecutionTimeout,
  }) async {
    final error = _verifyRequest(request: request, expectedType: HaloRequestType.procedure);
    if (error != null) {
      return error.error;
    }

    return implCallProcedure(
      request: request,
      executionTimeout: executionTimeout,
    );
  }

  /// This is the method to override in order to define the implementation of the calling procedure
  /// feature.
  /// When this method is called, we have verified if the request id given is a procedure
  @protected
  Future<HaloErrorType> implCallProcedure({
    required HaloRequestParamsPacket request,
    required Duration executionTimeout,
  });

  /// This method allows to call an order in the device, an order doesn't return a value and the
  /// device doesn't say if everything goes right or not (this can be used for rebooting a device,
  /// for instance).
  Future<HaloErrorType> callOrder({required HaloRequestParamsPacket request}) async {
    final error = _verifyRequest(request: request, expectedType: HaloRequestType.procedure);
    if (error != null) {
      return error.error;
    }

    return implCallOrder(request: request);
  }

  /// This is the method to override in order to define the implementation of the calling order
  /// feature.
  /// When this method is called, we have verified if the request id given is an order
  @protected
  Future<HaloErrorType> implCallOrder({required HaloRequestParamsPacket request});

  /// This method verifies if the [request] requestId given matches the [expectedType]
  /// If the method type matches, null is returned and if they are not, an error result is returned
  HaloRequestResult? _verifyRequest({
    required HaloRequestParamsPacket request,
    required HaloRequestType expectedType,
  }) {
    if (request.requestId.type != expectedType) {
      appLogger().w("A problem occurred in the HALO lib, you tried to call a request: "
          "$expectedType, but the request id is: ${request.requestId}");
      return HaloRequestResult(
        requestId: request.requestId,
        result: null,
        error: HaloErrorType.formatError,
      );
    }

    return null;
  }
}
