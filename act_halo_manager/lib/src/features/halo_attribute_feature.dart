// SPDX-FileCopyrightText: 2026 Damien Manceau <damien.manceau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_manager/src/features/abstract_halo_feature.dart';

/// This is the definition of feature when exchanging the attributes with the device
///
/// Every call is retried and serialized as the ones of the request to device feature
class HaloAttributeFeature<HardwareType> extends AbstractHaloFeature<HardwareType> {
  /// Class constructor
  HaloAttributeFeature({required super.haloManagerConfig});

  /// Read the attribute [dataId] in the device and returns the values it holds
  /// With [hardwareType] you specify through what hardware you want to read the device
  Future<ResultWithRequiredValue<HaloErrorType, HaloPayloadPacket>> readAttribute({
    required HardwareType hardwareType,
    required HaloDataId dataId,
  }) async {
    final result = await callAndRetry(
      hardwareType: hardwareType,
      errorDefaultResult: const ResultWithRequiredValue<HaloErrorType, HaloPacket>(
        status: HaloErrorType.genericError,
      ),
      callRequest: (service) => service.attributeHardware.readAttribute(dataId: dataId),
    );

    return ResultWithRequiredValue(status: result.status, value: result.value?.payload);
  }

  /// Write the [packet] in the device
  /// With [hardwareType] you specify through what hardware you want to reach the device
  Future<HaloErrorType> writeAttribute({
    required HardwareType hardwareType,
    required HaloPacket packet,
  }) => _callAndRetryError(
    hardwareType: hardwareType,
    callRequest: (service) => service.attributeHardware.writeAttribute(packet: packet),
  );

  /// Ask the device to tell us when the attribute [dataId] changes
  /// With [hardwareType] you specify through what hardware you want to reach the device
  Future<HaloErrorType> subAttribute({
    required HardwareType hardwareType,
    required HaloDataId dataId,
  }) => _callAndRetryError(
    hardwareType: hardwareType,
    callRequest: (service) => service.attributeHardware.subAttribute(dataId: dataId),
  );

  /// Ask the device to stop telling us when the attribute [dataId] changes
  /// With [hardwareType] you specify through what hardware you want to reach the device
  Future<HaloErrorType> unSubAttribute({
    required HardwareType hardwareType,
    required HaloDataId dataId,
  }) => _callAndRetryError(
    hardwareType: hardwareType,
    callRequest: (service) => service.attributeHardware.unSubAttribute(dataId: dataId),
  );

  /// The new values the device sends when its attributes change, read through [hardwareType]
  ///
  /// The stream is empty if the hardware layer is unknown
  Stream<HaloPacket> attrNewValueStream({required HardwareType hardwareType}) =>
      haloManagerConfig
          .hardwareLayer
          .hardwareServices[hardwareType]
          ?.haloHardware
          .attributeHardware
          .attrNewValueStream ??
      const Stream<HaloPacket>.empty();

  /// This method calls the [callAndRetry] and specify the case where the call returns a
  /// [HaloErrorType]
  Future<HaloErrorType> _callAndRetryError({
    required HardwareType hardwareType,
    required Future<HaloErrorType> Function(AbstractHaloHardware) callRequest,
  }) => callAndRetry(
    hardwareType: hardwareType,
    errorDefaultResult: HaloErrorType.genericError,
    callRequest: callRequest,
  );
}
