// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_ocsigen_halo_manager/act_ocsigen_halo_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a device answers when it was asked to join a network.
HaloPayloadPacket _answer(int value) => HaloPayloadPacket()..addUInt8(value);

void main() {
  setUp(FakeGlobalManager.install);

  group("OcsigenWiFiConnectResult.parseFromDevice", () {
    test("reads the device which joined the network", () {
      final result = OcsigenWiFiConnectResult.parseFromDevice(_answer(0x00))!;

      expect(result.status, OcsigenWiFiConnectStatus.success);
      expect(result.status.isError, isFalse);
      expect(result.errorValue, 0x00);
    });

    test("reads why the device did not join the network", () {
      final result = OcsigenWiFiConnectResult.parseFromDevice(_answer(0x02))!;

      expect(result.status, OcsigenWiFiConnectStatus.wrongPasswordError);
      expect(result.status.isError, isTrue);
    });

    test("keeps the value of an error the package does not know", () {
      final result = OcsigenWiFiConnectResult.parseFromDevice(_answer(0x42))!;

      expect(result.status, OcsigenWiFiConnectStatus.unknownError);
      expect(result.errorValue, 0x42);
    });

    test("refuses an answer which carries nothing", () {
      expect(OcsigenWiFiConnectResult.parseFromDevice(HaloPayloadPacket()), isNull);
    });

    test("refuses an answer which carries more than the status", () {
      final packet = _answer(0x00)..addUInt8(0x01);

      expect(OcsigenWiFiConnectResult.parseFromDevice(packet), isNull);
    });
  });
}
