// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_halo_abstract/act_halo_abstract.dart';
// The results of the protocol are only read inside the package, so they are not part of its public
// interface; there is no other way to read what a device answered
// ignore: implementation_imports
import 'package:act_halo_ble_layer/src/packets/halo_ble_request_result.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_halo_ble.dart';

void main() {
  late FakeGlobalManager globalManager;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() => globalManager.reset());

  /// Reads what the device answered about [requestId].
  HaloBleRequestResult? read(
    List<int> answer, {
    MixinHaloRequestId requestId = FakeHaloRequestId.aFunction,
  }) => HaloBleRequestResult.parseResultFromDevice(
    requestId: requestId,
    deviceResult: Uint8List.fromList(answer),
  );

  group("HaloBleRequestResult.parseResultFromDevice", () {
    test("reads the answer of a device to the request it was asked", () {
      final result = read(anAck(requestId: FakeHaloRequestId.aFunction, nbValues: 2));

      expect(result?.cmdId, HaloCmdId.ack);
      expect(result?.error, HaloErrorType.noError);
      expect(result?.requestId, FakeHaloRequestId.aFunction);
      expect(result?.nbValues, 2);
      expect(result?.result, isNull);
    });

    test("reads the error a device answers", () {
      final result = read(
        anAck(requestId: FakeHaloRequestId.aFunction, error: HaloErrorType.commError),
      );

      expect(result?.error, HaloErrorType.commError);
    });

    test("says nothing of an answer which is not of the size the protocol says", () {
      expect(read(const [0x06, 0x00, 0x00]), isNull);
      expect(read(const [0x06, 0x00, 0x00, 0x01, 0x00]), isNull);
    });

    test("says nothing of an answer which is about another request", () {
      final answer = anAck(requestId: FakeHaloRequestId.anOrder);

      expect(read(answer), isNull);
    });

    test("reads an answer whose command the protocol does not know", () {
      final result = read(const [0xEE, 0x00, 0x00, 0x01]);

      expect(result?.cmdId, HaloCmdId.unknown);
      expect(result?.error, HaloErrorType.noError);
    });

    test("reads an answer whose error the protocol does not know", () {
      final result = read(const [0x06, 0xEE, 0x00, 0x01]);

      expect(result?.error, HaloErrorType.unknown);
    });
  });

  group("HaloBleRequestResult", () {
    test("says that a request which went through was acknowledged", () {
      const result = HaloBleRequestResult.success(
        requestId: FakeHaloRequestId.aFunction,
        result: null,
      );

      expect(result.cmdId, HaloCmdId.ack);
      expect(result.error, HaloErrorType.noError);
      expect(result.nbValues, 0);
    });

    test("says that a request which failed was acknowledged by nothing", () {
      const result = HaloBleRequestResult.error(
        requestId: FakeHaloRequestId.aFunction,
        error: HaloErrorType.commError,
      );

      expect(result.cmdId, HaloCmdId.unknown);
      expect(result.error, HaloErrorType.commError);
    });

    test("tells two answers of the same request apart by their command", () {
      const success = HaloBleRequestResult.success(
        requestId: FakeHaloRequestId.aFunction,
        result: null,
      );
      const failure = HaloBleRequestResult.error(
        requestId: FakeHaloRequestId.aFunction,
        error: HaloErrorType.noError,
      );

      expect(success, isNot(failure));
    });
  });
}
