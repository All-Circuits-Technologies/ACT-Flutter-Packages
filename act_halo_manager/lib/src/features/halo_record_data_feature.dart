// SPDX-FileCopyrightText: 2026 Damien Manceau <damien.manceau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_manager/src/features/abstract_halo_feature.dart';

/// This is the definition of feature when exchanging the historical data with the device
///
/// Every call is retried and serialized as the ones of the request to device feature
class HaloRecordDataFeature<HardwareType> extends AbstractHaloFeature<HardwareType> {
  /// Class constructor
  HaloRecordDataFeature({required super.haloManagerConfig});

  /// Get the keys of the archives of the historical data [dataId] the device holds
  /// With [hardwareType] you specify through what hardware you want to read the device
  ///
  /// The device may expose only a window of its archives, see [drainRecords]
  Future<ResultWithRequiredValue<HaloErrorType, List<HaloRecordKey>>> getAllRecordDataKeys({
    required HardwareType hardwareType,
    required HaloDataId dataId,
  }) => callAndRetry(
    hardwareType: hardwareType,
    errorDefaultResult: const ResultWithRequiredValue(status: HaloErrorType.genericError),
    callRequest: (service) => service.recordDataHardware.getAllRecordDataKeys(dataId: dataId),
  );

  /// Read the archive [recordKey] in the device
  /// With [hardwareType] you specify through what hardware you want to read the device
  Future<ResultWithRequiredValue<HaloErrorType, HaloRecordPacket>> readRecordData({
    required HardwareType hardwareType,
    required HaloRecordKey recordKey,
  }) => callAndRetry(
    hardwareType: hardwareType,
    errorDefaultResult: const ResultWithRequiredValue(status: HaloErrorType.genericError),
    callRequest: (service) => service.recordDataHardware.readRecordData(recordKey: recordKey),
  );

  /// Tell the device that the archive [recordKey] is saved, so that it frees it
  /// With [hardwareType] you specify through what hardware you want to reach the device
  Future<HaloErrorType> ackRecordData({
    required HardwareType hardwareType,
    required HaloRecordKey recordKey,
  }) => _callAndRetryError(
    hardwareType: hardwareType,
    callRequest: (service) => service.recordDataHardware.ackRecordData(recordKey: recordKey),
  );

  /// Ask the device to tell us when it holds new archives of the historical data [dataId]
  /// With [hardwareType] you specify through what hardware you want to reach the device
  Future<HaloErrorType> subRecordData({
    required HardwareType hardwareType,
    required HaloDataId dataId,
  }) => _callAndRetryError(
    hardwareType: hardwareType,
    callRequest: (service) => service.recordDataHardware.subRecordData(dataId: dataId),
  );

  /// Ask the device to stop telling us when it holds new archives of the historical data [dataId]
  /// With [hardwareType] you specify through what hardware you want to reach the device
  Future<HaloErrorType> unSubRecordData({
    required HardwareType hardwareType,
    required HaloDataId dataId,
  }) => _callAndRetryError(
    hardwareType: hardwareType,
    callRequest: (service) => service.recordDataHardware.unSubRecordData(dataId: dataId),
  );

  /// The keys of the archives the device says are waiting, read through [hardwareType]
  ///
  /// The stream is empty if the hardware layer is unknown
  Stream<HaloRecordKey> recordKeysNewValueStream({required HardwareType hardwareType}) =>
      haloManagerConfig
          .hardwareLayer
          .hardwareServices[hardwareType]
          ?.haloHardware
          .recordDataHardware
          .recordKeysNewValueStream ??
      const Stream<HaloRecordKey>.empty();

  /// Empty the archives of the historical data [dataId] of the device, through [hardwareType]
  ///
  /// The device may expose only a window of its archives and moves it each time one is
  /// acknowledged. So this lists the keys, reads each archive, gives it to [onRecord], which
  /// returns true once the archive is saved, then acknowledges it, and starts again until the
  /// device lists no key.
  ///
  /// When [onRecord] returns false the archive is not acknowledged: the device keeps it in its
  /// window, so it is not given again and the loop ends once the window only holds such archives.
  /// Every step is a call of its own, [onRecord] may so call the other features.
  ///
  /// Returns the first error which stops the loop, [HaloErrorType.noError] when it ends normally.
  Future<HaloErrorType> drainRecords({
    required HardwareType hardwareType,
    required HaloDataId dataId,
    required Future<bool> Function(HaloRecordPacket record) onRecord,
  }) async {
    final refused = <HaloRecordKey>{};

    while (true) {
      final keysResult = await getAllRecordDataKeys(hardwareType: hardwareType, dataId: dataId);

      if (keysResult.isError) {
        return keysResult.status;
      }

      final toRead = keysResult.value!.where((key) => !refused.contains(key)).toList();

      if (toRead.isEmpty) {
        return HaloErrorType.noError;
      }

      for (final key in toRead) {
        final readResult = await readRecordData(hardwareType: hardwareType, recordKey: key);

        if (readResult.isError) {
          return readResult.status;
        }

        if (!await onRecord(readResult.value!)) {
          refused.add(key);
          continue;
        }

        final ackError = await ackRecordData(hardwareType: hardwareType, recordKey: key);

        if (ackError != HaloErrorType.noError) {
          return ackError;
        }
      }
    }
  }

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
