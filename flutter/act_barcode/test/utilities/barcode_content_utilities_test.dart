// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_barcode/act_barcode.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeGlobalManager globalManager;
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    globalManager = FakeGlobalManager.install(logger: logger);
  });

  tearDown(() => globalManager.reset());

  group("BarcodeContentUtilities.generateWifiQrCodeData", () {
    test("writes the type, the SSID and the password of a WPA network", () {
      expect(
        BarcodeContentUtilities.generateWifiQrCodeData(
          ssid: "Farm",
          security: QrCodeDataWifiSecurity.wpa,
          password: "secret12",
        ),
        "WIFI:T:WPA;S:Farm;P:secret12;;",
      );
    });

    test("writes the WEP type", () {
      expect(
        BarcodeContentUtilities.generateWifiQrCodeData(
          ssid: "Farm",
          security: QrCodeDataWifiSecurity.wep,
          password: "secret12",
        ),
        "WIFI:T:WEP;S:Farm;P:secret12;;",
      );
    });

    test("writes no password for an open network, without warning", () {
      expect(
        BarcodeContentUtilities.generateWifiQrCodeData(
          ssid: "Farm",
          security: QrCodeDataWifiSecurity.none,
          password: null,
        ),
        "WIFI:T:nopass;S:Farm;;",
      );
      expect(logger.recordsAtLevel(LogsLevel.warn), isEmpty);
    });

    test("ignores the password of an open network", () {
      expect(
        BarcodeContentUtilities.generateWifiQrCodeData(
          ssid: "Farm",
          security: QrCodeDataWifiSecurity.none,
          password: "secret12",
        ),
        "WIFI:T:nopass;S:Farm;;",
      );
    });

    test("falls back to an open network and warns when a secured network has no password", () {
      for (final password in [null, ""]) {
        logger.clearRecords();

        expect(
          BarcodeContentUtilities.generateWifiQrCodeData(
            ssid: "Farm",
            security: QrCodeDataWifiSecurity.wpa,
            password: password,
          ),
          "WIFI:T:nopass;S:Farm;;",
        );
        expect(logger.recordsAtLevel(LogsLevel.warn), hasLength(1));
      }
    });

    test("marks a hidden network", () {
      expect(
        BarcodeContentUtilities.generateWifiQrCodeData(
          ssid: "Farm",
          security: QrCodeDataWifiSecurity.wpa,
          password: "secret12",
          hidden: true,
        ),
        "WIFI:T:WPA;S:Farm;P:secret12;H:true;;",
      );
    });

    test("escapes the special characters of the SSID and the password", () {
      expect(
        BarcodeContentUtilities.generateWifiQrCodeData(
          ssid: r'My;Farm:"1",\',
          security: QrCodeDataWifiSecurity.wpa,
          password: r'a\b;c,d"e:f',
        ),
        r'WIFI:T:WPA;S:My\;Farm\:\"1\"\,\\;P:a\\b\;c\,d\"e\:f;;',
      );
    });
  });
}
