// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_ocsigen_halo_manager/act_ocsigen_halo_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a device answers about where it stands on one network.
void _aStatus(
  HaloPayloadPacket packet, {
  String ssid = "a network",
  String ip = "192.168.1.20",
  String netmask = "255.255.255.0",
  String gateway = "192.168.1.1",
  int urc = 0x00,
}) {
  packet.addString(ssid);
  packet.addString(ip);
  packet.addString(netmask);
  packet.addString(gateway);
  packet.addUInt8(urc);
}

void main() {
  setUp(FakeGlobalManager.install);

  group("OcsigenWiFiStatusResult.parseFromDevice", () {
    test("reads where a device stands on its network", () {
      final packet = HaloPayloadPacket();
      _aStatus(packet);

      final results = OcsigenWiFiStatusResult.parseFromDevice(packet)!;

      expect(results.single.ssid, "a network");
      expect(results.single.ip, "192.168.1.20");
      expect(results.single.netmask, "255.255.255.0");
      expect(results.single.gateway, "192.168.1.1");
      expect(results.single.urc, OcsigenWiFiUrc.ok);
    });

    test("reads the network a device is still connecting to", () {
      final packet = HaloPayloadPacket();
      _aStatus(packet, urc: OcsigenWiFiUrc.connecting.rawValue);

      expect(OcsigenWiFiStatusResult.parseFromDevice(packet)?.single.urc, OcsigenWiFiUrc.connecting);
    });

    test("reads every network of an answer which carries several", () {
      final packet = HaloPayloadPacket();
      _aStatus(packet);
      _aStatus(packet, ssid: "another network");

      final results = OcsigenWiFiStatusResult.parseFromDevice(packet)!;

      expect(results.map((result) => result.ssid), ["a network", "another network"]);
    });

    test("keeps a network whose state is unknown", () {
      final packet = HaloPayloadPacket();
      _aStatus(packet, urc: 0x42);

      expect(OcsigenWiFiStatusResult.parseFromDevice(packet)?.single.urc, OcsigenWiFiUrc.unknown);
    });

    test("refuses an answer which does not carry whole statuses", () {
      final packet = HaloPayloadPacket()..addString("a network");

      expect(OcsigenWiFiStatusResult.parseFromDevice(packet), isNull);
    });
  });
}
