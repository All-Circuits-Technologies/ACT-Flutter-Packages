// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_ocsigen_halo_manager/act_ocsigen_halo_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("OcsigenWiFiUrc.parseValue", () {
    test("reads every state of a connection a device knows", () {
      for (final urc in OcsigenWiFiUrc.values) {
        expect(OcsigenWiFiUrc.parseValue(urc.rawValue), urc);
      }
    });

    test("reads a state the package does not know", () {
      expect(OcsigenWiFiUrc.parseValue(0x42), OcsigenWiFiUrc.unknown);
    });
  });
}
