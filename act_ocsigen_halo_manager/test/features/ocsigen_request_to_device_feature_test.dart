// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_ocsigen_halo_manager/act_ocsigen_halo_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_ocsigen.dart';

/// The values a device answers a function with.
HaloPayloadPacket _aPayload(void Function(HaloPayloadPacket packet) fill) {
  final packet = HaloPayloadPacket();
  fill(packet);

  return packet;
}

void main() {
  late FakeOcsigenDevice device;

  setUp(FakeGlobalManager.install);

  /// The feature of an application whose device answers [result] and [error].
  OcsigenRequestToDeviceFeature<FakeHwType> aFeature({
    HaloPayloadPacket? result,
    HaloErrorType error = HaloErrorType.noError,
  }) {
    device = FakeOcsigenDevice(result: result, error: error);

    return OcsigenRequestToDeviceFeature<FakeHwType>(
      haloManagerConfig: HaloManagerConfig<FakeHwType>(
        hardwareLayer: FakeHwTypeHelper.only(device: device),
        requestIdHelper: OcsigenRequestIdHelper(),
      ),
    );
  }

  group("OcsigenRequestToDeviceFeature.claimDevice", () {
    test("sends the key the device verifies the claim with", () async {
      final feature = aFeature(result: _aPayload((packet) => packet.addBoolean(true)));

      final result = await feature.claimDevice(hardwareType: FakeHwType.ble, key: "a key");

      expect(result, isTrue);
      expect(device.call.requestId, OcsigenRequestId.claimDevice);
      expect(device.call.parameters.getString(0)?.$1, "a key");
    });

    test("answers nothing when the device could not be reached", () async {
      final feature = aFeature(error: HaloErrorType.commError);

      expect(await feature.claimDevice(hardwareType: FakeHwType.ble, key: "a key"), isNull);
    });
  });

  group("OcsigenRequestToDeviceFeature.wiFiSsidScan", () {
    test("answers the networks the device saw", () async {
      final feature = aFeature(
        result: _aPayload((packet) => packet.addStringList(["a network", "another network"])),
      );

      final result = await feature.wiFiSsidScan(hardwareType: FakeHwType.ble);

      expect(result, ["a network", "another network"]);
      expect(device.call.requestId, OcsigenRequestId.wiFiSsidScan);
    });

    test("answers nothing when the device could not be reached", () async {
      final feature = aFeature(error: HaloErrorType.commError);

      expect(await feature.wiFiSsidScan(hardwareType: FakeHwType.ble), isNull);
    });

    test("answers no network when the device saw none", () async {
      final feature = aFeature(result: HaloPayloadPacket());

      expect(await feature.wiFiSsidScan(hardwareType: FakeHwType.ble), isEmpty);
    });
  });

  group("OcsigenRequestToDeviceFeature.wiFiCompleteScan", () {
    test("answers what the device knows of the networks it saw", () async {
      final feature = aFeature(
        result: _aPayload((packet) {
          packet.addString("a network");
          packet.addInt8(-60);
          packet.addUInt8(6);
          packet.addUInt8(OcsigenWiFiAuthMode.wiFiAuthWpa2Psk.rawValue);
        }),
      );

      final result = await feature.wiFiCompleteScan(hardwareType: FakeHwType.ble);

      expect(result?.single.ssid, "a network");
      expect(result?.single.rssi, -60);
      expect(result?.single.channelNb, 6);
      expect(result?.single.authMode, OcsigenWiFiAuthMode.wiFiAuthWpa2Psk);
    });

    test("answers nothing when the device could not be reached", () async {
      final feature = aFeature(error: HaloErrorType.commError);

      expect(await feature.wiFiCompleteScan(hardwareType: FakeHwType.ble), isNull);
    });
  });

  group("OcsigenRequestToDeviceFeature.wiFiConnect", () {
    test("sends the network, the password and the way to authenticate", () async {
      final feature = aFeature(result: _aPayload((packet) => packet.addUInt8(0)));

      final result = await feature.wiFiConnect(
        hardwareType: FakeHwType.ble,
        ssid: "a network",
        password: "a password",
        authMode: OcsigenWiFiAuthMode.wiFiAuthWpa2Psk,
      );

      expect(result?.status, OcsigenWiFiConnectStatus.success);
      expect(device.call.parameters.getString(0)?.$1, "a network");
      expect(device.call.parameters.getString(1)?.$1, "a password");
      expect(
        device.call.parameters.getUInt(2)?.$1,
        OcsigenWiFiAuthMode.wiFiAuthWpa2Psk.rawValue,
      );
    });

    test("says nothing of the way to authenticate to a device which knows none", () async {
      final feature = aFeature(result: _aPayload((packet) => packet.addUInt8(0)));

      await feature.wiFiConnect(
        hardwareType: FakeHwType.ble,
        ssid: "a network",
        password: "a password",
        supportAuthMode: false,
      );

      expect(device.call.parameters.elementsNb, 2);
    });

    test("refuses to ask a device which knows no way to authenticate for one", () async {
      final feature = aFeature(result: _aPayload((packet) => packet.addUInt8(0)));

      final result = await feature.wiFiConnect(
        hardwareType: FakeHwType.ble,
        ssid: "a network",
        password: "a password",
        authMode: OcsigenWiFiAuthMode.wiFiAuthWpa2Psk,
        supportAuthMode: false,
      );

      expect(result, isNull);
      expect(device.calls, isEmpty);
    });

    test("answers the error of a device which refused the password", () async {
      final feature = aFeature(
        result: _aPayload(
          (packet) => packet.addUInt8(OcsigenWiFiConnectStatus.wrongPasswordError.rawValue),
        ),
      );

      final result = await feature.wiFiConnect(
        hardwareType: FakeHwType.ble,
        ssid: "a network",
        password: "a password",
      );

      expect(result?.status, OcsigenWiFiConnectStatus.wrongPasswordError);
      expect(result?.status.isError, isTrue);
    });

    test("answers nothing when the device could not be reached", () async {
      final feature = aFeature(error: HaloErrorType.commError);

      final result = await feature.wiFiConnect(
        hardwareType: FakeHwType.ble,
        ssid: "a network",
        password: "a password",
      );

      expect(result, isNull);
    });
  });

  group("OcsigenRequestToDeviceFeature.wiFiDisconnect", () {
    test("asks the device to leave the network it is on", () async {
      final feature = aFeature(result: _aPayload((packet) => packet.addBoolean(true)));

      expect(await feature.wiFiDisconnect(hardwareType: FakeHwType.ble), isTrue);
      expect(device.call.requestId, OcsigenRequestId.wiFiDisconnect);
    });
  });

  group("OcsigenRequestToDeviceFeature.wiFiGetStatus", () {
    test("answers where the device stands on its network", () async {
      final feature = aFeature(
        result: _aPayload((packet) {
          packet.addString("a network");
          packet.addString("192.168.1.20");
          packet.addString("255.255.255.0");
          packet.addString("192.168.1.1");
          packet.addUInt8(OcsigenWiFiUrc.ok.rawValue);
        }),
      );

      final result = await feature.wiFiGetStatus(materialType: FakeHwType.ble);

      expect(result?.single.ssid, "a network");
      expect(result?.single.ip, "192.168.1.20");
      expect(result?.single.netmask, "255.255.255.0");
      expect(result?.single.gateway, "192.168.1.1");
      expect(result?.single.urc, OcsigenWiFiUrc.ok);
    });

    test("answers nothing when the device could not be reached", () async {
      final feature = aFeature(error: HaloErrorType.commError);

      expect(await feature.wiFiGetStatus(materialType: FakeHwType.ble), isNull);
    });
  });

  group("OcsigenRequestToDeviceFeature.wiFiGetMacAddress", () {
    test("answers the address of the WiFi chip of the device", () async {
      final feature = aFeature(
        result: _aPayload((packet) => packet.addString("00:11:22:33:44:55")),
      );

      expect(
        await feature.wiFiGetMacAddress(hardwareType: FakeHwType.ble),
        "00:11:22:33:44:55",
      );
    });
  });

  group("OcsigenRequestToDeviceFeature.apWiFiEnable", () {
    test("asks the device to open its own access point", () async {
      final feature = aFeature(result: _aPayload((packet) => packet.addBoolean(true)));

      expect(await feature.apWiFiEnable(hardwareType: FakeHwType.ble), isTrue);
      expect(device.call.parameters.getBoolean(0)?.$1, isTrue);
    });

    test("asks the device to close its own access point", () async {
      final feature = aFeature(result: _aPayload((packet) => packet.addBoolean(true)));

      await feature.apWiFiEnable(hardwareType: FakeHwType.ble, enable: false);

      expect(device.call.parameters.getBoolean(0)?.$1, isFalse);
    });
  });

  group("OcsigenRequestToDeviceFeature.echo", () {
    test("answers the value the device repeated", () async {
      final feature = aFeature(result: _aPayload((packet) => packet.addUInt8(42)));

      expect(await feature.echo(hardwareType: FakeHwType.ble, uInt8ToRepeat: 42), 42);
      expect(device.call.parameters.getUInt(0)?.$1, 42);
    });

    test("refuses a value which does not fit in what the device reads", () async {
      final feature = aFeature(result: _aPayload((packet) => packet.addUInt8(42)));

      expect(await feature.echo(hardwareType: FakeHwType.ble, uInt8ToRepeat: 300), isNull);
      expect(device.calls, isEmpty);
    });
  });

  group("OcsigenRequestToDeviceFeature.getSerialNumber", () {
    test("answers the serial number of the device", () async {
      final feature = aFeature(result: _aPayload((packet) => packet.addString("a serial number")));

      expect(await feature.getSerialNumber(hardwareType: FakeHwType.ble), "a serial number");
    });
  });

  group("OcsigenRequestToDeviceFeature.setGpsCoordinates", () {
    test("sends the coordinates as whole numbers, and how many digits they carry", () async {
      final feature = aFeature(result: _aPayload((packet) => packet.addBoolean(true)));

      final result = await feature.setGpsCoordinates(
        hardwareType: FakeHwType.ble,
        latitude: 20.5,
        longitude: -1.25,
        decimalPoint: 2,
      );

      expect(result, isTrue);
      expect(device.call.parameters.getInt(0)?.$1, 2050);
      expect(device.call.parameters.getInt(1)?.$1, -125);
      expect(device.call.parameters.getUInt(2)?.$1, 2);
    });

    test("refuses coordinates which do not fit in what the device reads", () async {
      final feature = aFeature(result: _aPayload((packet) => packet.addBoolean(true)));

      final result = await feature.setGpsCoordinates(
        hardwareType: FakeHwType.ble,
        latitude: 20.5,
        longitude: -1.25,
        decimalPoint: 9,
      );

      expect(result, isNull);
      expect(device.calls, isEmpty);
    });
  });

  group("OcsigenRequestToDeviceFeature.getSavedWiFi", () {
    test("answers the networks the device comes back to on its own", () async {
      final feature = aFeature(
        result: _aPayload((packet) => packet.addStringList(["a network"])),
      );

      expect(await feature.getSavedWiFi(hardwareType: FakeHwType.ble), ["a network"]);
      expect(device.call.requestId, OcsigenRequestId.getSavedWiFi);
    });

    test("answers nothing when the device could not be reached", () async {
      final feature = aFeature(error: HaloErrorType.commError);

      expect(await feature.getSavedWiFi(hardwareType: FakeHwType.ble), isNull);
    });

    test("answers no network for a device which comes back to none", () async {
      final feature = aFeature(result: HaloPayloadPacket());

      expect(await feature.getSavedWiFi(hardwareType: FakeHwType.ble), isEmpty);
    });
  });

  group("OcsigenRequestToDeviceFeature.forgetSavedWiFi", () {
    test("sends the network the device stops coming back to", () async {
      final feature = aFeature(result: _aPayload((packet) => packet.addBoolean(true)));

      final result = await feature.forgetSavedWiFi(
        hardwareType: FakeHwType.ble,
        wiFiSsid: "a network",
      );

      expect(result, isTrue);
      expect(device.call.parameters.getString(0)?.$1, "a network");
    });
  });

  group("OcsigenRequestToDeviceFeature.quitCommunication", () {
    test("tells the device how the communication ended", () async {
      final feature = aFeature();

      final result = await feature.quitCommunication(
        hardwareType: FakeHwType.ble,
        endComStatus: RestrictedEndComStatus.endComOk,
      );

      expect(result, isTrue);
      expect(device.call.requestId, OcsigenRequestId.quitCommunication);
      expect(device.call.parameters.getUInt(0)?.$1, RestrictedEndComStatus.endComOk.rawValue);
    });

    test("says that it failed when the device could not be reached", () async {
      final feature = aFeature(error: HaloErrorType.commError);

      final result = await feature.quitCommunication(
        hardwareType: FakeHwType.ble,
        endComStatus: RestrictedEndComStatus.endComGenericError,
      );

      expect(result, isFalse);
    });
  });
}
