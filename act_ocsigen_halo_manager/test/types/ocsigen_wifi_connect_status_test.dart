// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_ocsigen_halo_manager/act_ocsigen_halo_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("OcsigenWiFiConnectStatus.parseValue", () {
    test("reads every answer of a device which was asked to join a network", () {
      for (final status in OcsigenWiFiConnectStatus.values) {
        expect(OcsigenWiFiConnectStatus.parseValue(status.rawValue), status);
      }
    });

    test("reads an answer the package does not know", () {
      expect(OcsigenWiFiConnectStatus.parseValue(0x42), OcsigenWiFiConnectStatus.unknownError);
    });

    test("says that the only answer which is not an error is the success", () {
      expect(
        OcsigenWiFiConnectStatus.values.where((status) => !status.isError),
        [OcsigenWiFiConnectStatus.success],
      );
    });
  });
}
