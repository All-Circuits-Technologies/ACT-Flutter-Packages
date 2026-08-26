// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_request_ids.dart';

void main() {
  group("HaloRequestParamsPacket", () {
    test("equals another packet which carries the same request, values and parameters", () {
      final parameters = HaloPayloadPacket();

      expect(
        HaloRequestParamsPacket(
          requestId: FakeRequestId.startHeating,
          nbValues: const [1],
          parameters: parameters,
        ),
        HaloRequestParamsPacket(
          requestId: FakeRequestId.startHeating,
          nbValues: const [1],
          parameters: parameters,
        ),
      );
    });

    test("differs from a packet which carries another request", () {
      final parameters = HaloPayloadPacket();

      expect(
        HaloRequestParamsPacket(
          requestId: FakeRequestId.startHeating,
          nbValues: const [1],
          parameters: parameters,
        ),
        isNot(
          HaloRequestParamsPacket(
            requestId: FakeRequestId.reboot,
            nbValues: const [1],
            parameters: parameters,
          ),
        ),
      );
    });

    test("accepts as many parameters as the protocol allows", () {
      expect(
        () => HaloRequestParamsPacket(
          requestId: FakeRequestId.startHeating,
          nbValues: List.filled(maxRequestParameterNumber, 1),
          parameters: HaloPayloadPacket(),
        ),
        returnsNormally,
      );
    });

    test("refuses more parameters than the protocol allows", () {
      expect(
        () => HaloRequestParamsPacket(
          requestId: FakeRequestId.startHeating,
          nbValues: List.filled(maxRequestParameterNumber + 1, 1),
          parameters: HaloPayloadPacket(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group("HaloRequestParamsPacket.voidParams", () {
    test("carries no parameter", () {
      final packet = HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.reboot);

      expect(packet.nbValues, isEmpty);
      expect(packet.parameters.elementsNb, 0);
    });

    test("carries the request it is built for", () {
      final packet = HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.reboot);

      expect(packet.requestId, FakeRequestId.reboot);
    });
  });
}
