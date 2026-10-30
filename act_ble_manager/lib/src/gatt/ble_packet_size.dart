// SPDX-FileCopyrightText: 2026 Damien Manceau <damien.manceau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library;

import 'dart:math';

/// The packet size of the default ATT MTU (23 bytes), the smallest a device can negotiate
const int defaultPacketSize = 20;

/// Gives the size of the packets which can be written to a device, from the [value] answered by
/// `requestMtu` of flutter_reactive_ble
///
/// The plugin does not answer the same thing on each platform:
/// - On Android, it answers the ATT MTU negotiated (`ReactiveBleClient.kt`, `requestMtu` of
///   RxAndroidBle); the packet is the MTU without the 3 bytes of the ATT header.
/// - On iOS, it answers `peripheral.maximumWriteValueLength(for: .withoutResponse)`
///   (`PluginController.swift`, `reportMaximumWriteValueLength`), which is already the MTU without
///   the header.
///
/// The result is never under [defaultPacketSize].
int packetSizeFromMtuResult(int value, {required bool isIos}) =>
    max(defaultPacketSize, isIos ? value : value - 3);
