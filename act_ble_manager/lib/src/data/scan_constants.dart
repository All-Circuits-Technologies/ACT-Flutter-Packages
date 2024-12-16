// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library ble_scan_constants;

/// Scan ON periodic duration
const Duration scanOnDuration = Duration(seconds: 5);

/// Time after which a device is disappears in scan (when not found again)
const Duration scanMaxTimeDeviceDisappeared = Duration(seconds: 30);

/// This is the time to wait before restarting scan when the BLE is detected as connected again
const Duration waitBeforeRestartingScan = Duration(seconds: 2);
