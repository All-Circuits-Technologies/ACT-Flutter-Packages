// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_request_ids.dart';

void main() {
  group("MixinHaloRequestId.uniqueId", () {
    test("builds an id from the type and the raw value of the request", () {
      // The type is the low byte and the raw value the high one
      expect(FakeRequestId.readTemperature.uniqueId, 0x0100);
    });

    test("tells apart two requests which share a raw value but not a type", () {
      expect(
        FakeRequestId.readTemperature.uniqueId,
        isNot(FakeRequestId.stopHeating.uniqueId),
      );
    });

    test("gives the same id to the same request declared twice", () {
      expect(
        FakeRequestId.readTemperature.uniqueId,
        OtherFakeRequestId.readTemperature.uniqueId,
      );
    });

    test("gives a distinct id to each request of a same type", () {
      expect(
        OtherFakeRequestId.readPressure.uniqueId,
        isNot(OtherFakeRequestId.readTemperature.uniqueId),
      );
    });
  });
}
