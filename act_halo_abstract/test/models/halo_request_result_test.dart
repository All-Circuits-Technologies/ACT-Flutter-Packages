// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_request_ids.dart';

void main() {
  group("HaloRequestResult", () {
    test("expects no value unless the caller says how many it awaits", () {
      final result = HaloRequestResult(
        requestId: FakeRequestId.readTemperature,
        status: HaloErrorType.noError,
        value: HaloPayloadPacket(),
      );

      expect(result.nbValues, 0);
    });

    test("equals another result which carries the same request, payload, status and count", () {
      final payload = HaloPayloadPacket();

      expect(
        HaloRequestResult(
          requestId: FakeRequestId.readTemperature,
          status: HaloErrorType.noError,
          value: payload,
          nbValues: 1,
        ),
        HaloRequestResult(
          requestId: FakeRequestId.readTemperature,
          status: HaloErrorType.noError,
          value: payload,
          nbValues: 1,
        ),
      );
    });

    test("differs from a result which carries another status", () {
      final payload = HaloPayloadPacket();

      expect(
        HaloRequestResult(
          requestId: FakeRequestId.readTemperature,
          status: HaloErrorType.noError,
          value: payload,
        ),
        isNot(
          HaloRequestResult(
            requestId: FakeRequestId.readTemperature,
            status: HaloErrorType.commError,
            value: payload,
          ),
        ),
      );
    });
  });

  group("HaloRequestResult.error", () {
    test("carries the status and no value", () {
      const result = HaloRequestResult.error(
        requestId: FakeRequestId.readTemperature,
        status: HaloErrorType.commError,
      );

      expect(result.status, HaloErrorType.commError);
      expect(result.value, isNull);
      expect(result.nbValues, 0);
    });
  });
}
