// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_ocsigen_halo_manager/act_ocsigen_halo_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("OcsigenWiFiAuthMode.parseValue", () {
    test("reads every way of authenticating a device knows", () {
      for (final authMode in OcsigenWiFiAuthMode.values) {
        expect(OcsigenWiFiAuthMode.parseValue(authMode.rawValue), authMode);
      }
    });

    test("reads a way of authenticating the package does not know", () {
      expect(OcsigenWiFiAuthMode.parseValue(0x42), OcsigenWiFiAuthMode.wiFiAuthUnknown);
    });
  });
}
