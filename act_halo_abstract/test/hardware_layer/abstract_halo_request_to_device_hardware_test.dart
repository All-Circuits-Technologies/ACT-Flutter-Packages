// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_hardware.dart';
import '../fakes/fake_request_ids.dart';

void main() {
  late FakeLogger logger;
  late FakeRequestToDeviceHardware hardware;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
    hardware = FakeRequestToDeviceHardware();
  });

  group("AbstractHaloRequestToDeviceHardware.callFunction", () {
    test("sends the request to the device", () async {
      final request = HaloRequestParamsPacket.voidParams(
        requestId: FakeRequestId.readTemperature,
      );

      await hardware.callFunction(request: request);

      expect(hardware.calledRequests, [request]);
    });

    test("returns what the device answers", () async {
      final result = HaloRequestResult(
        requestId: FakeRequestId.readTemperature,
        result: HaloPayloadPacket(),
        error: HaloErrorType.noError,
        nbValues: 1,
      );
      hardware.functionResult = result;

      final answer = await hardware.callFunction(
        request: HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.readTemperature),
      );

      expect(answer, result);
    });

    test("waits for the device as long as the caller asks it to", () async {
      const timeout = Duration(seconds: 5);

      await hardware.callFunction(
        request: HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.readTemperature),
        executionTimeout: timeout,
      );

      expect(hardware.executionTimeouts, [timeout]);
    });

    test("waits for the device for the default timeout when the caller gives none", () async {
      await hardware.callFunction(
        request: HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.readTemperature),
      );

      expect(hardware.executionTimeouts, [
        AbstractHaloRequestToDeviceHardware.defaultExecutionTimeout,
      ]);
    });

    test("refuses a request which is not a function", () async {
      final answer = await hardware.callFunction(
        request: HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.startHeating),
      );

      expect(answer.error, HaloErrorType.formatError);
    });

    test("sends nothing to the device when it refuses the request", () async {
      await hardware.callFunction(
        request: HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.startHeating),
      );

      expect(hardware.calledRequests, isEmpty);
    });

    test("warns about the request it refuses", () async {
      await hardware.callFunction(
        request: HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.startHeating),
      );

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("returns an error when the device answers a success without any value", () async {
      hardware.functionResult = const HaloRequestResult(
        requestId: FakeRequestId.readTemperature,
        result: null,
        error: HaloErrorType.noError,
      );

      final answer = await hardware.callFunction(
        request: HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.readTemperature),
      );

      expect(answer.error, HaloErrorType.genericError);
    });

    test("returns the error of the device when it fails without any value", () async {
      hardware.functionResult = const HaloRequestResult.error(
        requestId: FakeRequestId.readTemperature,
        error: HaloErrorType.commError,
      );

      final answer = await hardware.callFunction(
        request: HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.readTemperature),
      );

      expect(answer.error, HaloErrorType.commError);
    });
  });

  group("AbstractHaloRequestToDeviceHardware.callProcedure", () {
    test("sends the request to the device", () async {
      final request = HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.startHeating);

      await hardware.callProcedure(request: request);

      expect(hardware.calledRequests, [request]);
    });

    test("returns what the device answers", () async {
      hardware.procedureError = HaloErrorType.serviceBusyError;

      final answer = await hardware.callProcedure(
        request: HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.startHeating),
      );

      expect(answer, HaloErrorType.serviceBusyError);
    });

    test("waits for the device for the default timeout when the caller gives none", () async {
      await hardware.callProcedure(
        request: HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.startHeating),
      );

      expect(hardware.executionTimeouts, [
        AbstractHaloRequestToDeviceHardware.defaultExecutionTimeout,
      ]);
    });

    test("refuses a request which is not a procedure", () async {
      final answer = await hardware.callProcedure(
        request: HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.readTemperature),
      );

      expect(answer, HaloErrorType.formatError);
      expect(hardware.calledRequests, isEmpty);
    });
  });

  group("AbstractHaloRequestToDeviceHardware.callOrder", () {
    test("sends the request to the device", () async {
      final request = HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.reboot);

      await hardware.callOrder(request: request);

      expect(hardware.calledRequests, [request]);
    });

    test("returns what the device answers", () async {
      hardware.orderError = HaloErrorType.commError;

      final answer = await hardware.callOrder(
        request: HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.reboot),
      );

      expect(answer, HaloErrorType.commError);
    });

    test("refuses a request which is not an order", () async {
      final answer = await hardware.callOrder(
        request: HaloRequestParamsPacket.voidParams(requestId: FakeRequestId.startHeating),
      );

      expect(answer, HaloErrorType.formatError);
      expect(hardware.calledRequests, isEmpty);
    });
  });
}
