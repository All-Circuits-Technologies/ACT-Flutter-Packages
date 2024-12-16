// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_ble_manager_ui/src/mixins/mixin_ble_connection_route.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_router_manager/act_router_manager.dart';
import 'package:flutter/widgets.dart';

/// This mixin "overrides" [MixinRedirectService] to redirect the views to the right BLE connection
/// page if we are in a page which needs to be connected with a BLE device.
///
/// Because, you might have different processes which need to have a connection with a BLE device,
/// we manage different page redirections.
mixin MixinBleConnectionRedirectService<T extends MixinBleConnectionRoute<T>>
    on MixinRedirectService<T> {
  /// Subscription controller to connected Ble Device
  late final StreamSubscription<BleDevice?> _onConnectedDevice;

  /// The listened device
  BleDevice? connectedDevice;

  /// This method has to be called to initialize the redirect service.
  /// When the class is no more used don't forget to call [closeRedirectService] method.
  @override
  Future<bool> initRedirectService() async {
    // First call super method, if not null, we don't go further
    if (!(await super.initRedirectService())) {
      return false;
    }

    final bleManager = globalGetIt().get<BleManager>();

    _onConnectedDevice = bleManager.bleGattService.lastConnectedDeviceStream.listen(_onNewDevice);
    await _onNewDevice(bleManager.bleGattService.lastConnectedDevice);

    return true;
  }

  /// This method is called when we want to go to a specific view and ask if it's ok or if we want
  /// to redirect.
  /// If the function returns null, it means that there is nothing to do
  /// If the function returns a non null route:
  ///   - it means that we want to redirect to this page,
  ///   - be aware that the new view replaces the one wanted (therefore, the route tested won't be
  ///     built and displayed),
  ///   - this method will be recalled with the new view we ask (so be careful to not create
  ///     infinite redirection)
  ///
  /// If the super class has already required a view, this service don't go further. We consider
  /// that the order of the mixins is also the order of priority
  @override
  Future<T?> onRedirect(BuildContext context, T route, GoRouterState state) async {
    final redirect = await super.onRedirect(context, route, state);

    if (redirect != null) {
      return redirect;
    }

    final redirectTo = _getPageToRedirectToIfNeeded(currentView: route);

    if (redirectTo == null) {
      // Nothing to do
      return null;
    }

    return redirectTo;
  }

  /// Called when we are connected to a new BLE device or null if we are disconnected from a BLE
  /// device
  Future<void> _onNewDevice(BleDevice? newDevice) async {
    if (newDevice != connectedDevice) {
      connectedDevice = newDevice;

      final redirectTo = _getPageToRedirectToIfNeeded();

      if (redirectTo == null) {
        // Nothing to do
        return;
      }

      await _redirectPage(redirectTo);
    }
  }

  /// Get the page to redirect to if we are no more connected to a BLE device and if the page needs
  /// us to be connected to a BLE device.
  ///
  /// Returns null when you are nothing to do.
  T? _getPageToRedirectToIfNeeded({
    T? currentView,
  }) {
    final tmpCurrent = currentView ?? routerManager.getCurrentTopView();

    if (tmpCurrent == null) {
      // We can't know; therefore, we do nothing
      return null;
    }

    final redirectTo = tmpCurrent.redirectToIfBleDeviceDisconnected;

    if (redirectTo == null) {
      // Nothing to do
      return null;
    }

    if (connectedDevice != null) {
      // We are connected to a device, therefore we don't go further
      return null;
    }

    return redirectTo;
  }

  /// Called to redirect to the wanted page
  Future<void> _redirectPage(T redirectTo) async {
    while (routerManager.canPop()) {
      routerManager.pop();
      final currentView = routerManager.getCurrentTopView();

      if (currentView == redirectTo) {
        // Nothing to do more
        return;
      }

      final currentRedirectTo = currentView?.redirectToIfBleDeviceDisconnected;
      if (currentRedirectTo == null || currentRedirectTo != redirectTo) {
        // The previous view is not managed by this redirection, we push the view
        await routerManager.push(redirectTo);
        return;
      }
    }

    // If there is no other view, we replace the current one
    await routerManager.replace(redirectTo);
  }

  /// This method has to be called to close the redirect service. It will unregister the router
  /// redirection.
  @override
  Future<void> closeRedirectService() async {
    await super.closeRedirectService();

    await _onConnectedDevice.cancel();
  }
}
