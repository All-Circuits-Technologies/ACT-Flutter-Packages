// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library ble_constants;

/// Duration of scan ON in scan loop
const Duration scanOnDuration = Duration(seconds: 5);

/// Maximum time after which a device has disappeared
const Duration scanMaxTimeDeviceDisappeared = Duration(seconds: 30);

/// Maximum time to connect
const Duration connectTimeout = Duration(seconds: 20);

/// Low level maximum time to connect
const Duration lowLevelConnectTimeout = Duration(seconds: 10);

/// Timer after which popup disconnect is sent
const Duration disconnectPopupTimeout = Duration(milliseconds: 5000);

/// Scan needed to connect to a specific jacket that was not scanned already
const Duration scanOnConnectionDuration = Duration(seconds: 15);

/// Time for a simple communication (read/write/setNotify)
const Duration simpleCommunicationDuration = Duration(seconds: 5);

/// Duration to wait for connection to be complete
const Duration waitForConnectionDuration = Duration(seconds: 2);
