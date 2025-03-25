// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_ble_manager/src/ble_manager.dart';
import 'package:act_ble_manager/src/data/constants.dart' as ble_constants;
import 'package:act_ble_manager/src/data/error_messages.dart' as error_messages;
import 'package:act_ble_manager/src/models/ble_device.dart';
import 'package:act_ble_manager/src/types/bond_state.dart';
import 'package:act_ble_manager/src/types/characteristics_error.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:mutex/mutex.dart';

/// Manages all the features linked to characteristics in the BLE GATT part
class BleGattCharacteristicService extends AbsWithLifeCycle {
  /// The flutter BLE lib instance
  final FlutterReactiveBle _flutterBle;

  /// The BLE manager
  final BleManager _bleManager;

  /// Mutex used to manage concurrency inside BLE manager
  final Mutex _bleMutex;

  /// Class constructor
  BleGattCharacteristicService({
    required FlutterReactiveBle flutterReactiveBle,
    required BleManager bleManager,
    required Mutex bleMutex,
  })  : _bleMutex = bleMutex,
        _flutterBle = flutterReactiveBle,
        _bleManager = bleManager;

  /// {@template act_ble_manager.BleGattCharacteristicService.writeBleCharacteristic}
  /// Write [values] to characteristic from [uuid]
  /// {@endtemplate}
  Future<CharacteristicsError> writeBleCharacteristic(
    BleDevice device,
    String uuid,
    List<int> values, {
    bool withoutResponse = false,
  }) async =>
      _bleMutex.protect(() async {
        final (result, tmpChar) = await _verifyDeviceAndGetWantedChar(device: device, uuid: uuid);

        if (result != CharacteristicsError.success) {
          return result;
        }

        final characteristic = tmpChar!;

        var success = CharacteristicsError.genericError;
        _bleManager.logsHelper.d('Try to write characteristic: '
            '${characteristic.characteristicId}, with value: $values in device: '
            '${device.id}');
        try {
          // Write without response does not work on iOS, always use write with response
          if (withoutResponse && !globalGetIt().get<PlatformManager>().isIos) {
            await _flutterBle.writeCharacteristicWithoutResponse(characteristic, value: values);
          } else {
            await _flutterBle.writeCharacteristicWithResponse(characteristic, value: values);
          }

          success = CharacteristicsError.success;
        } catch (e) {
          success = await _manageDeviceInteractionError(
            error: e,
            device: device,
            characteristic: characteristic,
          );
        }

        if (success != CharacteristicsError.success) {
          if (globalGetIt().get<PlatformManager>().isAndroid) {
            // When an exception occurred, this block the next connection of the app
            // on Android that's why we force the reinitialization of the ble lib
            await _bleManager.reInitFlutterBle();
          }
        }

        return success;
      });

  /// {@template act_ble_manager.BleGattCharacteristicService.readBleCharacteristic}
  /// Read characteristic from [uuid]
  /// Return value read
  /// {@endtemplate}
  Future<(CharacteristicsError, List<int>?)> readBleCharacteristic(
    BleDevice device,
    String uuid,
  ) async =>
      _bleMutex.protect(() async {
        final (result, tmpChar) = await _verifyDeviceAndGetWantedChar(device: device, uuid: uuid);

        if (result != CharacteristicsError.success) {
          return (result, null);
        }

        final characteristic = tmpChar!;

        var success = CharacteristicsError.genericError;
        List<int>? values;
        try {
          values = await _flutterBle
              .readCharacteristic(characteristic)
              .timeout(ble_constants.simpleCommunicationDuration);
          success = CharacteristicsError.success;
        } catch (e) {
          success = await _manageDeviceInteractionError(
            error: e,
            device: device,
            characteristic: characteristic,
          );
        }

        _bleManager.logsHelper.d('Characteristic read: '
            '${characteristic.characteristicId}, with value: $values in device: '
            '${device.id}');

        return (success, values);
      });

  /// {@template act_ble_manager.BleGattCharacteristicService.subscribeBleNotification}
  /// Set notification on characteristic from [uuid]
  /// Return success
  /// {@endtemplate}
  Future<(CharacteristicsError, Stream<List<int>>?)> subscribeBleNotification(
    BleDevice device,
    String uuid,
  ) async =>
      _bleMutex.protect(() async {
        final (result, tmpChar) = await _verifyDeviceAndGetWantedChar(device: device, uuid: uuid);

        if (result != CharacteristicsError.success) {
          return (result, null);
        }

        final characteristic = tmpChar!;

        Stream<List<int>>? notifStream;
        var success = CharacteristicsError.genericError;
        try {
          notifStream = _flutterBle.subscribeToCharacteristic(characteristic);
          success = CharacteristicsError.success;
        } catch (e) {
          success = await _manageDeviceInteractionError(
            error: e,
            device: device,
            characteristic: characteristic,
          );
        }

        return (success, notifStream?.handleError(_onSubscribeErrors));
      });

  /// Verify the device and get the wanted characteristic known by its [uuid]
  ///
  /// If [CharacteristicsError] is equals to [CharacteristicsError.success] the second item isn't
  /// null
  Future<(CharacteristicsError, QualifiedCharacteristic?)> _verifyDeviceAndGetWantedChar({
    required BleDevice device,
    required String uuid,
  }) async {
    if (device.connectionState != DeviceConnectionState.connected) {
      _bleManager.logsHelper.w("The device you want to interact with, isn't connected: "
          "${device.id}");
      return const (CharacteristicsError.genericError, null);
    }

    if (!(await _bleManager.checkAndAskForPermissionsAndServices())) {
      // This test manage the case where the user haven't accepted the BLE permissions or started
      // BLE
      _bleManager.logsHelper.w("The user don't have accepted the BLE permission or started the BLE "
          "service; therefore we can't write characteristic");
      return const (CharacteristicsError.genericError, null);
    }

    final characteristic = device.findCharacteristic(uuid);

    if (characteristic == null) {
      _bleManager.logsHelper.w("The characteristic: $uuid, hasn't been found in the "
          "device: ${device.id}, can't manage writing");
      return const (CharacteristicsError.genericError, null);
    }

    return (CharacteristicsError.success, characteristic);
  }

  /// Call to manage errors created by the characteristic interactions
  Future<CharacteristicsError> _manageDeviceInteractionError({
    required Object error,
    required BleDevice device,
    required QualifiedCharacteristic characteristic,
  }) async {
    var charError = CharacteristicsError.genericError;

    _bleManager.logsHelper.w('The interaction with ble characteristic: '
        '${characteristic.characteristicId}, on device: ${device.id}, failed: $error');

    // Check if iOS bonding error
    if (_isIosBondingError(error)) {
      _bleManager.logsHelper.i("Device bonded not done");
      device.bondState = BondState.bondingFailed;
    } else if (_isMissingAuthorization(error)) {
      charError = CharacteristicsError.missAuthorization;
    }

    return charError;
  }

  /// Verify if there is an iOS bonding error
  bool _isIosBondingError(Object error) {
    final stringError = error.toString();

    return stringError.contains(error_messages.iosFirstBondingError) ||
        stringError.contains(error_messages.iosSecondBondingError);
  }

  /// Verify if the error received is linked with a problem of authorization
  bool _isMissingAuthorization(Object error) {
    final stringError = error.toString();

    return stringError.contains(error_messages.missAuth);
  }

  /// Called when an error occurred in a characteristic subscription
  Future<void> _onSubscribeErrors(Object error) async {
    _bleManager.logsHelper.e("A non managed error occurred in the subscribe channel $error");

    final lastConnectedDevice = _bleManager.bleGattService.lastConnectedDevice;

    if (lastConnectedDevice == null) {
      // Nothing to do
      return;
    }

    final errString = error.toString();

    if (errString.contains(error_messages.gattSuccessDisconnectedError)) {
      _bleManager.logsHelper.e("A disconnection has been detected, we disconnect the last "
          "connected ble device");
      await lastConnectedDevice.disconnect();
    }
  }
}
