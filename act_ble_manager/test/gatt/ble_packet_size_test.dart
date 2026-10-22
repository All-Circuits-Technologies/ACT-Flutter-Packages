// SPDX-FileCopyrightText: 2026 Damien Manceau <damien.manceau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_ble_manager/src/gatt/ble_packet_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("packetSizeFromMtuResult", () {
    test("removes the 3 bytes of the ATT header on Android", () {
      expect(packetSizeFromMtuResult(247, isIos: false), 244);
    });

    test("keeps the value on iOS, which is already the size of a write", () {
      expect(packetSizeFromMtuResult(182, isIos: true), 182);
    });

    test("never goes under the 20 bytes of the default MTU", () {
      expect(packetSizeFromMtuResult(23, isIos: false), 20);
      expect(packetSizeFromMtuResult(10, isIos: true), 20);
    });
  });
}
