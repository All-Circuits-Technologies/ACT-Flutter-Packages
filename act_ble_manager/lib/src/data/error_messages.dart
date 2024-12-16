// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library error_messages;

/// Bonding error message
const String bondingErrorMessage = "Bonding is in progress wait for bonding to be finished";

/// iOS bonding error messages
const String iosFirstBondingError = "Encryption is insufficient";
const String iosSecondBondingError = "Authentication is insufficient";

/// This error is raised when the bluetooth is disabled
const String bluetoothDisabled = "Bluetooth disabled";

/// This error is raised when a problem occurred while scanning
const String scanThrottle = "Undocumented scan throttle";

/// This error is raised when a problem occurred and fire the disconnection of device
const String gattSuccessDisconnectedError = "Disconnected from MAC='XX:XX:XX:XX:XX:XX' with "
    "status 0 (GATT_SUCCESS)";

/// This error occurred when we haven't enough authorization to act with a characteristic
const String missAuth = "GATT_INSUF_AUTHORIZATION or GATT_CONN_TIMEOUT";

/// This error occurred when we try to clear the GATT cache of a device when it's not connected
const String clearCacheDeviceNotConnected = "Device is not connected";
