// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_ocsigen_halo_manager/act_ocsigen_halo_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a device answers about one network it saw.
void _aNetwork(
  HaloPayloadPacket packet, {
  String ssid = "a network",
  int rssi = -60,
  int channelNb = 6,
  int authMode = 0x03,
}) {
  packet.addString(ssid);
  packet.addInt8(rssi);
  packet.addUInt8(channelNb);
  packet.addUInt8(authMode);
}

void main() {
  setUp(FakeGlobalManager.install);

  group("OcsigenWiFiCompleteScanResult.parseFromDevice", () {
    test("reads what a device knows of a network", () {
      final packet = HaloPayloadPacket();
      _aNetwork(packet);

      final results = OcsigenWiFiCompleteScanResult.parseFromDevice(packet)!;

      expect(results.single.ssid, "a network");
      expect(results.single.rssi, -60);
      expect(results.single.channelNb, 6);
      expect(results.single.authMode, OcsigenWiFiAuthMode.wiFiAuthWpa2Psk);
    });

    test("reads every network of an answer which carries several", () {
      final packet = HaloPayloadPacket();
      _aNetwork(packet);
      _aNetwork(packet, ssid: "another network", channelNb: 11);

      final results = OcsigenWiFiCompleteScanResult.parseFromDevice(packet)!;

      expect(results.map((result) => result.ssid), ["a network", "another network"]);
      expect(results.last.channelNb, 11);
    });

    test("reads no network from a device which saw none", () {
      expect(OcsigenWiFiCompleteScanResult.parseFromDevice(HaloPayloadPacket()), isEmpty);
    });

    test("keeps a network whose way to authenticate is unknown", () {
      final packet = HaloPayloadPacket();
      _aNetwork(packet, authMode: 0x42);

      final results = OcsigenWiFiCompleteScanResult.parseFromDevice(packet)!;

      expect(results.single.authMode, OcsigenWiFiAuthMode.wiFiAuthUnknown);
    });

    test("refuses an answer which does not carry whole networks", () {
      final packet = HaloPayloadPacket()..addString("a network");

      expect(OcsigenWiFiCompleteScanResult.parseFromDevice(packet), isNull);
    });

    test("is the same network as another one a device answered the same way", () {
      final packet = HaloPayloadPacket();
      _aNetwork(packet);
      final other = HaloPayloadPacket();
      _aNetwork(other);

      expect(
        OcsigenWiFiCompleteScanResult.parseFromDevice(packet),
        OcsigenWiFiCompleteScanResult.parseFromDevice(other),
      );
    });
  });
}
