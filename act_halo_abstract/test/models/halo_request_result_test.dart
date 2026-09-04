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
        result: HaloPayloadPacket(),
        error: HaloErrorType.noError,
      );

      expect(result.nbValues, 0);
    });

    test("equals another result which carries the same request, payload, error and count", () {
      final payload = HaloPayloadPacket();

      expect(
        HaloRequestResult(
          requestId: FakeRequestId.readTemperature,
          result: payload,
          error: HaloErrorType.noError,
          nbValues: 1,
        ),
        HaloRequestResult(
          requestId: FakeRequestId.readTemperature,
          result: payload,
          error: HaloErrorType.noError,
          nbValues: 1,
        ),
      );
    });

    test("differs from a result which carries another error", () {
      final payload = HaloPayloadPacket();

      expect(
        HaloRequestResult(
          requestId: FakeRequestId.readTemperature,
          result: payload,
          error: HaloErrorType.noError,
        ),
        isNot(
          HaloRequestResult(
            requestId: FakeRequestId.readTemperature,
            result: payload,
            error: HaloErrorType.commError,
          ),
        ),
      );
    });
  });

  group("HaloRequestResult.error", () {
    test("carries the error and no result", () {
      const result = HaloRequestResult.error(
        requestId: FakeRequestId.readTemperature,
        error: HaloErrorType.commError,
      );

      expect(result.error, HaloErrorType.commError);
      expect(result.result, isNull);
      expect(result.nbValues, 0);
    });
  });
}
