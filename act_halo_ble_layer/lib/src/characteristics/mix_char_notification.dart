// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_ble_layer/src/characteristics/abstract_halo_characteristic.dart';
import 'package:async/async.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Useful mixin for managing characteristics with notifications
mixin MixCharNotification on AbstractHaloCharacteristic {
  /// When waiting for an answer from the device, we don't wait more than this value
  // static const maxWaitForResponseDuration = Duration(seconds: 10);
  // TODO(brolandeau): set the max wait to a big value in order to manage the test by a human
  static const maxWaitForResponseDuration = Duration(minutes: 5);

  /// Contains all the current response waiter
  final _packetResponseWaiter = <ResponseWaiter>[];

  /// The stream subscription on the notify characteristic stream
  StreamSubscription? _notifyStreamSubscription;

  /// The stream subscription on device state
  StreamSubscription? _deviceStateSub;

  /// Redefined the has notification getter
  @override
  bool get hasNotification => true;

  /// Has to be called when succeeded to subscribe to the characteristic (in order to give the
  /// stream update)
  /// The [newStream] stream received when listening on the characteristic notification
  Future<void> onStreamUpdate(
    Stream<List<int>> newStream,
    Stream<DeviceConnectionState> deviceStateStream,
  ) async {
    await cleanStream();

    _notifyStreamSubscription = newStream.listen(_onNotificationReceived);
    _deviceStateSub = deviceStateStream.listen(_onDeviceState);
  }

  /// To call in order to prepare a wait response, this will return a [ResponseWaiter] which can be
  /// used to cancel the waiting
  Future<ResponseWaiter?> prepareWaitResponse() async {
    if (_notifyStreamSubscription == null) {
      appLogger().w("We can't wait for a notification of the characteristic: $name (uuid: $uuid), "
          "because the characteristic hasn't subscribed the BLE Device");
      return null;
    }

    return ResponseWaiter._(this);
  }

  /// Received when a new value is received from the notification
  /// We free all the pending [ResponseWaiter]
  Future<void> _onNotificationReceived(List<int> value) async {
    globalGetIt().get<BleManager>().logsHelper.d('Notification received for characteristic: '
        '$uuid, with value: $value');
    _completeValue(value);
  }

  /// Called when a device state is received, if the device is disconnected, we cancel all the
  /// pending [ResponseWaiter]
  Future<void> _onDeviceState(DeviceConnectionState deviceState) async {
    if (deviceState == DeviceConnectionState.disconnected ||
        deviceState == DeviceConnectionState.disconnecting) {
      _completeValue(null);
    }
  }

  /// Clean the stream and subscriptions
  Future<void> cleanStream() async {
    if (_notifyStreamSubscription != null) {
      await Future.wait([
        _notifyStreamSubscription!.cancel(),
        _deviceStateSub!.cancel(),
      ]);

      _deviceStateSub = null;
      _notifyStreamSubscription = null;

      _completeValue(null);
    }
  }

  /// Complete the value and free all the pending [ResponseWaiter] with the [expectedValue] given
  void _completeValue(List<int>? expectedValue) {
    for (final waiter in _packetResponseWaiter) {
      waiter._complete(expectedValue);
    }
    _packetResponseWaiter.clear();
  }
}

/// Useful class to wait for a new value in the notification stream
///
/// This class allows to cancel the waiting, if something bad happens meantime
class ResponseWaiter {
  /// The parent characteristic linked to the reponse waiter
  final MixCharNotification _parentToRegister;

  /// The cancelable completer linked to the current waiter
  final CancelableCompleter<List<int>?> _completer;

  /// The cancelable operation linked to the current waiter
  late final CancelableOperation<List<int>?> _operation;

  /// Private constructor to build the response waiter
  ResponseWaiter._(MixCharNotification parentToRegister)
      : _parentToRegister = parentToRegister,
        _completer = CancelableCompleter<List<int>?>() {
    _operation = _completer.operation;
    parentToRegister._packetResponseWaiter.add(this);
  }

  /// This allows to cancel a current waiting
  Future<void> cancel() async {
    if (_completer.isCompleted) {
      // Nothing to do
      return;
    }

    _parentToRegister._packetResponseWaiter.remove(this);
    return _operation.cancel();
  }

  /// Wait for a response in the characteristic
  ///
  /// The ways to leave this method are:
  /// - We receive a message from the spied characteristic
  /// - The timeout has raised before we received a message
  /// - Something else has cancelled the waiting
  Future<List<int>?> waitResponse({
    Duration? timeout = MixCharNotification.maxWaitForResponseDuration,
  }) async {
    if (timeout != null) {
      Timer(timeout, () async {
        if (_completer.isCompleted) {
          // Nothing to do
          return;
        }

        appLogger().w("The timeout raised before we got the expected value from characteristic: "
            "${_parentToRegister.name} (uuid: ${_parentToRegister.uuid}),");
        await cancel();
      });
    }

    return _operation.valueOrCancellation();
  }

  /// Call to complete the waiter with the received value or null to cancel
  void _complete(List<int>? value) {
    _completer.complete(value);
  }
}
