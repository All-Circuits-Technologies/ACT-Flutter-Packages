// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library;

/// Scan ON periodic duration
const Duration scanOnDuration = Duration(seconds: 5);

/// Time after which a device is disappears in scan (when not found again)
const Duration scanMaxTimeDeviceDisappeared = Duration(seconds: 30);

/// This is the time to wait before restarting scan when the BLE is detected as connected again
const Duration waitBeforeRestartingScan = Duration(seconds: 2);

/// The time Android takes to stop a scan once it is cancelled, before a connection may be opened
///
/// Some Android phones fail to connect right after a scan was stopped
/// (https://github.com/googlesamples/android-BluetoothLeGatt/issues/44). The value is the one of
/// flutter_reactive_ble, found by experience: it means to wait as long after every scan which is
/// cancelled on Android (`DeviceScannerImpl`), but awaits a single `Future` built with the plugin,
/// which is over a few hundred milliseconds after the application started. The wait is done here.
const Duration waitAfterStoppingScan = Duration(milliseconds: 300);
