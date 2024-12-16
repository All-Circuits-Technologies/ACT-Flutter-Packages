// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_router_manager/act_router_manager.dart';
import 'package:flutter/foundation.dart';

/// Mixin used to redirect to a given page when we are disconnected from the listened device
///
/// This may be useful if you are in pages which needs to be connected to a BLE device.
///
/// When using this mixin, don't forget to call the [initObserver] and [closeObserver] methods
mixin MixinBleDeviceConnectionObserver<R extends MixinRoute, M extends AbstractRouterManager<R>> {
  /// The listened device
  late final BleDevice listenedDevice;

  /// The router manager
  late final M _routerManager;

  /// The page to redirect to when the device is disconnected
  late final R _disconnectedPage;

  /// The extra information to pass to the page when the device is disconnected
  late final Object? _extraDisconnectedPage;

  /// Subscription controller to connection state
  StreamSubscription<DeviceConnectionState>? _connectionStateSub;

  /// Initialize the mixin
  @mustCallSuper
  Future<void> initObserver({
    required M routerManager,
    required R disconnectedPage,
    BleDevice? listenedDevice,
    Object? extraDisconnectedPage,
  }) async {
    _routerManager = routerManager;
    _disconnectedPage = disconnectedPage;
    _extraDisconnectedPage = extraDisconnectedPage;

    final tmpDevice =
        listenedDevice ?? globalGetIt().get<BleManager>().bleGattService.lastConnectedDevice;

    if (tmpDevice == null) {
      return _redirectPage();
    }

    this.listenedDevice = tmpDevice;

    _connectionStateSub = tmpDevice.connectionStateStream.listen(_onStatusChanged);
  }

  /// Called on connection status changed and redirect to the device disconnected page
  Future<void> _onStatusChanged(DeviceConnectionState status) async {
    if (status != DeviceConnectionState.disconnected) {
      // Nothing to do
      return;
    }

    return _redirectPage();
  }

  /// Called to redirect to the wanted page
  Future<void> _redirectPage() async {
    await _routerManager.replace(_disconnectedPage, extra: _extraDisconnectedPage);
  }

  /// Close the observer
  @mustCallSuper
  Future<void> closeObserver() async {
    /// Cancel of the stream device connection
    await _connectionStateSub?.cancel();
  }
}
