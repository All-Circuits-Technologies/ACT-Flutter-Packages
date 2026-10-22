// SPDX-FileCopyrightText: 2026 Damien Manceau <damien.manceau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_manager/src/features/abstract_halo_feature.dart';

/// This is the definition of feature when exchanging the instant data with the device
///
/// Every call is retried and serialized as the ones of the request to device feature
class HaloInstantDataFeature<HardwareType> extends AbstractHaloFeature<HardwareType> {
  /// Class constructor
  HaloInstantDataFeature({required super.haloManagerConfig});

  /// Read the instant data [dataId] in the device and returns the values it holds
  /// With [hardwareType] you specify through what hardware you want to read the device
  Future<(HaloErrorType, HaloPayloadPacket?)> readInstantData({
    required HardwareType hardwareType,
    required HaloDataId dataId,
  }) async {
    final (error, packet) = await callAndRetry(
      hardwareType: hardwareType,
      errorDefaultResult: (HaloErrorType.genericError, null as HaloPacket?),
      callRequest: (service) => service.instantDataHardware.readInstantData(dataId: dataId),
      isMakingSensToRetry: (result) => result.$1.isMakingSensToRetry,
    );

    return (error, packet?.payload);
  }

  /// Ask the device to tell us when the instant data [dataId] changes
  /// With [hardwareType] you specify through what hardware you want to reach the device
  Future<HaloErrorType> subInstantData({
    required HardwareType hardwareType,
    required HaloDataId dataId,
  }) => _callAndRetryError(
    hardwareType: hardwareType,
    callRequest: (service) => service.instantDataHardware.subInstantData(dataId: dataId),
  );

  /// Ask the device to stop telling us when the instant data [dataId] changes
  /// With [hardwareType] you specify through what hardware you want to reach the device
  Future<HaloErrorType> unSubInstantData({
    required HardwareType hardwareType,
    required HaloDataId dataId,
  }) => _callAndRetryError(
    hardwareType: hardwareType,
    callRequest: (service) => service.instantDataHardware.unSubInstantData(dataId: dataId),
  );

  /// The new values the device sends when its instant data change, read through [hardwareType]
  ///
  /// The stream is empty if the hardware layer is unknown
  Stream<HaloPacket> instDataNewValueStream({required HardwareType hardwareType}) =>
      haloManagerConfig
          .hardwareLayer
          .hardwareServices[hardwareType]
          ?.haloHardware
          .instantDataHardware
          .instDataNewValueStream ??
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
    isMakingSensToRetry: (error) => error.isMakingSensToRetry,
  );
}
