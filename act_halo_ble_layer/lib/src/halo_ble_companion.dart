// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:typed_data';

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/src/characteristics/abstract_halo_characteristic.dart';
import 'package:act_halo_ble_layer/src/characteristics/mix_char_notification.dart';
import 'package:act_halo_ble_layer/src/halo_ble_config.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Companion of the HALO BLE material layer,
/// This contains useful method to write and read in BLE characteristics
class HaloBleCompanion {
  /// This contains the BLE config
  final HaloBleConfig haloBleConfig;

  /// This is the BLE manager
  final BleManager bleManager;

  /// This is the stream subscription for the BLE device state
  StreamSubscription? _bleDeviceState;

  /// This is the current connected, and usable for HALO, BLE device
  BleDevice? _bleDevice;

  /// Class constructor
  HaloBleCompanion({required this.haloBleConfig, required this.bleManager});

  /// Called when a new HALO BLE device is connected. This manages the subscription to all the
  /// characteristics.
  ///
  /// If [bleDevice] is null, this calls the method [onDisconnection]
  Future<void> onNewHaloBleDevice(BleDevice? bleDevice) async {
    if (bleDevice == null) {
      return onDisconnection();
    }

    _bleDevice = bleDevice;
    _bleDeviceState = _bleDevice!.connectionStateStream.listen(_onDeviceBleStateUpdate);

    if (!(await _subscribeToNotifs(bleDevice: bleDevice))) {
      return;
    }
  }

  /// Called when the current BLE device [_bleDevice] is disconnected from us
  Future<void> onDisconnection() async {
    if (_bleDevice == null) {
      // Nothing to do
      return;
    }

    final futures = <Future>[_unsubscribeToNotifs()];

    if (_bleDeviceState != null) {
      futures.add(_bleDeviceState!.cancel());
    }

    await Future.wait(futures);

    _bleDeviceState = null;
    _bleDevice = null;
  }

  /// Call to write the [dataToWrite] data in the characteristic [toWriteInto]
  /// This method verifies if the current [_bleDevice] is not null
  Future<HaloErrorType> onlyWrite({
    required AbstractHaloCharacteristic toWriteInto,
    required Uint8List dataToWrite,
  }) async {
    if (_bleDevice == null) {
      appLogger().w("The BLE device isn't connected we can't write data to it");
      return HaloErrorType.commError;
    }

    return _unsafeOnlyWrite(dataToWrite: dataToWrite, toWriteInto: toWriteInto);
  }

  /// Call to write the [dataToWrite] data in the characteristic [toWriteInto]
  /// This method doesn't verify if the [_bleDevice] is null or not (this has to be done in the
  /// caller method)
  Future<HaloErrorType> _unsafeOnlyWrite({
    required AbstractHaloCharacteristic toWriteInto,
    required Uint8List dataToWrite,
  }) async {
    if (!(await bleManager.bleGattService
            .writeBleCharacteristic(_bleDevice!, toWriteInto.uuid, dataToWrite))
        .isSuccess) {
      appLogger().w("A problem occurred when tried to write in the HALO characteristic: "
          "${toWriteInto.name} (uuid: ${toWriteInto.uuid})");
      return HaloErrorType.commError;
    }

    return HaloErrorType.noError;
  }

  /// Call to write the [dataToWrite] data in the characteristic [toWriteInto], and wait a result
  /// in the [toWaitNotifyFrom] characteristic
  Future<(HaloErrorType, Uint8List?)> writeAndWaitNotifResult({
    required AbstractHaloCharacteristic toWriteInto,
    required Uint8List dataToWrite,
    required MixCharNotification toWaitNotifyFrom,
  }) async {
    if (_bleDevice == null) {
      appLogger().w("The BLE device isn't connected we can't write data to it");
      return const (HaloErrorType.commError, null);
    }

    final waiter = await toWaitNotifyFrom.prepareWaitResponse();

    if (waiter == null) {
      // A problem occurred when tried to prepare the waiting
      return const (HaloErrorType.genericError, null);
    }

    final writeResult = await _unsafeOnlyWrite(dataToWrite: dataToWrite, toWriteInto: toWriteInto);

    if (writeResult != HaloErrorType.noError) {
      await waiter.cancel();
      return (writeResult, null);
    }

    final result = await waiter.waitResponse();

    if (result == null) {
      // The waiter has been cancelled or an error occurred
      return const (HaloErrorType.genericError, null);
    }

    return (HaloErrorType.noError, Uint8List.fromList(result));
  }

  /// Subscribe to the HALO [bleDevice] characteristics notifications
  /// Returns false if a problem occurred in the process
  Future<bool> _subscribeToNotifs({
    required BleDevice bleDevice,
  }) async {
    for (final charToSub in haloBleConfig.notifiableHaloCharacteristics) {
      final (result, stream) =
          await bleManager.bleGattService.subscribeBleNotification(bleDevice, charToSub.uuid);

      if (!result.isSuccess || stream == null) {
        appLogger().w("A problem occurred when tried to subscribe to the characteristic: "
            "${charToSub.name} (uuid: ${charToSub.uuid}), in the device: ${bleDevice.name}");
        return false;
      }

      await charToSub.onStreamUpdate(stream, bleDevice.connectionStateStream);
    }

    return true;
  }

  /// Unsubscribe to the HALO [bleDevice] characteristics notifications
  /// Returns false if a problem occurred in the process
  Future<bool> _unsubscribeToNotifs() async {
    final futures = <Future>[];

    for (final charToSub in haloBleConfig.notifiableHaloCharacteristics) {
      futures.add(charToSub.cleanStream());
    }

    await Future.wait(futures);

    return true;
  }

  /// This method is called when the device connection state of the current [_bleDevice] is updated
  Future<void> _onDeviceBleStateUpdate(DeviceConnectionState state) async {
    if (state == DeviceConnectionState.disconnected ||
        state == DeviceConnectionState.disconnecting) {
      await onDisconnection();
    }
  }
}
