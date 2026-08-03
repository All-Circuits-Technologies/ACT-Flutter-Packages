// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_manager/act_halo_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_halo.dart';

/// The values a device answers a function with.
HaloPayloadPacket _aPayload(void Function(HaloPayloadPacket packet) fill) {
  final packet = HaloPayloadPacket();
  fill(packet);

  return packet;
}

void main() {
  setUp(FakeGlobalManager.install);

  /// The request the tests send to the device.
  HaloRequestParamsPacket aRequest([FakeRequestId id = FakeRequestId.readTemperature]) =>
      HaloRequestParamsPacket.voidParams(requestId: id);

  /// Builds the feature of an application whose device answers [errors] and [result].
  ///
  /// The application reaches its device over the way [hardwareType] names, which is the one the
  /// tests ask for unless they ask for another.
  ({HaloRequestToDeviceFeature<FakeHwType> feature, FakeRequestToDeviceHardware device}) aFeature({
    List<HaloErrorType> errors = const [HaloErrorType.noError],
    HaloPayloadPacket? result,
    FakeHwType hardwareType = FakeHwType.ble,
    int retryNbBeforeReturningError = HaloManagerConfig.defaultRetryNumber,
    Map<int, Duration> overriddenExecutionTimeout = const {},
    Duration? defaultRequestTimeout,
  }) {
    final device = FakeRequestToDeviceHardware(errors: errors, result: result);
    final config = HaloManagerConfig<FakeHwType>(
      hardwareLayer: FakeHwTypeHelper.only(type: hardwareType, requestToDevice: device),
      requestIdHelper: FakeRequestIdHelper(
        overriddenExecutionTimeout: overriddenExecutionTimeout,
        defaultRequestTimeout: defaultRequestTimeout,
      ),
      retryNbBeforeReturningError: retryNbBeforeReturningError,
    );

    return (
      feature: HaloRequestToDeviceFeature<FakeHwType>(haloManagerConfig: config),
      device: device,
    );
  }

  group("HaloRequestToDeviceFeature.callFunction", () {
    test("asks the device and answers what it read", () async {
      final packet = _aPayload((packet) => packet.addString("20 degrees"));
      final (:feature, :device) = aFeature(result: packet);

      final result = await feature.callFunction(hardwareType: FakeHwType.ble, request: aRequest());

      expect(result.error, HaloErrorType.noError);
      expect(result.result, packet);
      expect(device.calls, [FakeRequestId.readTemperature]);
    });

    test("asks again while the error is one which may pass", () async {
      final packet = _aPayload((packet) => packet.addString("20 degrees"));
      final (:feature, :device) = aFeature(
        errors: [HaloErrorType.commError, HaloErrorType.noError],
        result: packet,
      );

      final result = await feature.callFunction(hardwareType: FakeHwType.ble, request: aRequest());

      expect(result.error, HaloErrorType.noError);
      expect(device.calls, hasLength(2));
    });

    test("gives up once it has asked as many times as the application allows", () async {
      final (:feature, :device) = aFeature(
        errors: [HaloErrorType.commError],
        retryNbBeforeReturningError: 3,
      );

      final result = await feature.callFunction(hardwareType: FakeHwType.ble, request: aRequest());

      expect(result.error, HaloErrorType.commError);
      expect(device.calls, hasLength(3));
    });

    test("asks only once when the error is one which will not pass", () async {
      final (:feature, :device) = aFeature(errors: [HaloErrorType.formatError]);

      final result = await feature.callFunction(hardwareType: FakeHwType.ble, request: aRequest());

      expect(result.error, HaloErrorType.formatError);
      expect(device.calls, hasLength(1));
    });

    test("answers an error when the application cannot reach the device that way", () async {
      final (:feature, :device) = aFeature(hardwareType: FakeHwType.serial);

      final result = await feature.callFunction(hardwareType: FakeHwType.ble, request: aRequest());

      expect(result.error, HaloErrorType.genericError);
      expect(device.calls, isEmpty);
    });

    test("goes on answering after it could not reach the device", () async {
      final (:feature, :device) = aFeature(
        result: _aPayload((packet) => packet.addString("20 degrees")),
      );

      await feature.callFunction(hardwareType: FakeHwType.serial, request: aRequest());
      final result = await feature.callFunction(hardwareType: FakeHwType.ble, request: aRequest());

      expect(result.error, HaloErrorType.noError);
      expect(device.calls, hasLength(1));
    });

    test("answers an error when the device answers a function with nothing", () async {
      final (:feature, :device) = aFeature();

      final result = await feature.callFunction(hardwareType: FakeHwType.ble, request: aRequest());

      expect(result.error, HaloErrorType.genericError);
    });
  });

  group("HaloRequestToDeviceFeature", () {
    test("reads the boolean the device answered", () async {
      final (:feature, device: _) = aFeature(
        result: _aPayload((packet) => packet.addBoolean(true)),
      );

      final value = await feature.callBooleanFunction(
        hardwareType: FakeHwType.ble,
        request: aRequest(),
      );

      expect(value, isTrue);
    });

    test("reads the text the device answered", () async {
      final (:feature, device: _) = aFeature(
        result: _aPayload((packet) => packet.addString("20 degrees")),
      );

      final value = await feature.callStringFunction(
        hardwareType: FakeHwType.ble,
        request: aRequest(),
      );

      expect(value, "20 degrees");
    });

    test("reads the signed number the device answered", () async {
      final (:feature, device: _) = aFeature(result: _aPayload((packet) => packet.addInt8(-20)));

      final value = await feature.callIntFunction(
        hardwareType: FakeHwType.ble,
        request: aRequest(),
      );

      expect(value, -20);
    });

    test("reads the unsigned number the device answered", () async {
      final (:feature, device: _) = aFeature(result: _aPayload((packet) => packet.addUInt8(20)));

      final value = await feature.callUIntFunction(
        hardwareType: FakeHwType.ble,
        request: aRequest(),
      );

      expect(value, 20);
    });

    test("reads nothing when the device answered more than one value", () async {
      final (:feature, device: _) = aFeature(
        result: _aPayload((packet) {
          packet
            ..addBoolean(true)
            ..addBoolean(false);
        }),
      );

      final value = await feature.callBooleanFunction(
        hardwareType: FakeHwType.ble,
        request: aRequest(),
      );

      expect(value, isNull);
    });

    test("reads nothing when the device answered an error", () async {
      final (:feature, device: _) = aFeature(errors: [HaloErrorType.formatError]);

      final value = await feature.callBooleanFunction(
        hardwareType: FakeHwType.ble,
        request: aRequest(),
      );

      expect(value, isNull);
    });
  });

  group("HaloRequestToDeviceFeature.callProcedure", () {
    test("asks the device and answers what it said", () async {
      final (:feature, :device) = aFeature();

      final error = await feature.callProcedure(
        hardwareType: FakeHwType.ble,
        request: aRequest(FakeRequestId.startHeating),
      );

      expect(error, HaloErrorType.noError);
      expect(device.calls, [FakeRequestId.startHeating]);
    });

    test("asks again while the error is one which may pass", () async {
      final (:feature, :device) = aFeature(
        errors: [HaloErrorType.serviceBusyError, HaloErrorType.noError],
      );

      final error = await feature.callProcedure(
        hardwareType: FakeHwType.ble,
        request: aRequest(FakeRequestId.startHeating),
      );

      expect(error, HaloErrorType.noError);
      expect(device.calls, hasLength(2));
    });

    test("answers an error when the application cannot reach the device that way", () async {
      final (:feature, device: _) = aFeature(hardwareType: FakeHwType.serial);

      final error = await feature.callProcedure(
        hardwareType: FakeHwType.ble,
        request: aRequest(FakeRequestId.startHeating),
      );

      expect(error, HaloErrorType.genericError);
    });
  });

  group("HaloRequestToDeviceFeature.callOrder", () {
    test("asks the device and answers what it said", () async {
      final (:feature, :device) = aFeature();

      final error = await feature.callOrder(
        hardwareType: FakeHwType.ble,
        request: aRequest(FakeRequestId.reboot),
      );

      expect(error, HaloErrorType.noError);
      expect(device.calls, [FakeRequestId.reboot]);
    });
  });

  group("HaloRequestToDeviceFeature.executionTimeout", () {
    test("waits as long as the caller asked", () async {
      final (:feature, :device) = aFeature(defaultRequestTimeout: const Duration(seconds: 5));

      await feature.callFunction(
        hardwareType: FakeHwType.ble,
        request: aRequest(),
        executionTimeout: const Duration(seconds: 1),
      );

      expect(device.timeouts.first, const Duration(seconds: 1));
    });

    test("waits as long as the request asks when the caller asked for nothing", () async {
      final (:feature, :device) = aFeature(
        overriddenExecutionTimeout: {
          FakeRequestId.readTemperature.uniqueId: const Duration(seconds: 2),
        },
        defaultRequestTimeout: const Duration(seconds: 5),
      );

      await feature.callFunction(hardwareType: FakeHwType.ble, request: aRequest());

      expect(device.timeouts.first, const Duration(seconds: 2));
    });

    test("waits as long as the application asks when the request asks for nothing", () async {
      final (:feature, :device) = aFeature(defaultRequestTimeout: const Duration(seconds: 5));

      await feature.callFunction(hardwareType: FakeHwType.ble, request: aRequest());

      expect(device.timeouts.first, const Duration(seconds: 5));
    });

    test("waits the time the protocol says when nobody asks for another", () async {
      final (:feature, :device) = aFeature();

      await feature.callFunction(hardwareType: FakeHwType.ble, request: aRequest());

      expect(device.timeouts.first, AbstractHaloRequestToDeviceHardware.defaultExecutionTimeout);
    });
  });
}
