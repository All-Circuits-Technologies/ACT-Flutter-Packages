// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_thingsboard.dart';

void main() {
  group("MixinTelemetriesKeys.parseTelemetryKeyList", () {
    test("answers the key the server knows each element under", () {
      final keys = MixinTelemetriesKeys.parseTelemetryKeyList(FakeTelemetryKeys.values);

      expect(keys, ["temp", "hum"]);
    });

    test("keeps the order the elements were given in", () {
      final keys = MixinTelemetriesKeys.parseTelemetryKeyList([
        FakeTelemetryKeys.humidity,
        FakeTelemetryKeys.temperature,
      ]);

      expect(keys, ["hum", "temp"]);
    });

    test("answers nothing when no element is given", () {
      expect(MixinTelemetriesKeys.parseTelemetryKeyList([]), isEmpty);
    });
  });
}
