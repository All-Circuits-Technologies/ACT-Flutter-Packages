// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/act_router_manager.dart';

/// This mixin extends [MixinRoute] and adds the [redirectToIfBleDeviceDisconnected] getter, used
/// to know if a view needs to be connected to a BLE device or not.
/// If the value is not null, it represents the page to redirect to when we are no more connected to
/// a BLE device.
mixin MixinBleConnectionRoute<T extends MixinRoute> on MixinRoute {
  /// The route to redirect to if we are in the page and it's no more connected to a BLE device.
  /// If null, there is nothing to do.
  T? get redirectToIfBleDeviceDisconnected;
}
