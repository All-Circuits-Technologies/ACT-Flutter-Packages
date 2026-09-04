// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/act_halo_ble_layer.dart';
// The hardware layers are handed over by the hardware of the package rather than built by an
// application, so they are not part of its public interface
// ignore: implementation_imports
import 'package:act_halo_ble_layer/src/hardware_layer/halo_ble_request_to_device_hardware.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_halo_ble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The time the tests let a request take.
  const aShortTimeout = Duration(milliseconds: 20);

  late FakeGlobalManager globalManager;
  late FakeBlePlatform ble;
  late BleManager manager;
  late FakeBleConfigManager config;
  late HaloBleConfig halo;
  late FakeHaloCompanion companion;
  late HaloBleRequestToDeviceHardware hardware;

  setUpAll(() => ble = FakeBlePlatform.install());

  setUp(() async {
    ble.reset();
    globalManager = FakeGlobalManager.install();

    config = await FakeBleConfigManager.withContent(aBleConf);
    manager = BleManager(confGetter: () => config);
    globalGetIt().registerSingleton<BleManager>(manager);

    halo = aHaloConfig();
    companion = FakeHaloCompanion(haloBleConfig: halo, bleManager: manager);
    hardware = HaloBleRequestToDeviceHardware(bleCompanion: companion);
  });

  tearDown(() async {
    FakeAssets.stop();
    await config.disposeLifeCycle();
    await globalManager.reset();
  });

  /// The request of an application which asks the device for [requestId].
  HaloRequestParamsPacket aRequest({
    MixinHaloRequestId requestId = FakeHaloRequestId.aFunction,
    List<int> nbValues = const [],
    List<String> parameters = const [],
  }) {
    companion.ackFor = requestId;

    return HaloRequestParamsPacket(
      requestId: requestId,
      nbValues: nbValues,
      parameters: aPayload(parameters),
    );
  }

  /// The command which was written into the characteristic of the commands, [index] writings in.
  Uint8List commandWritten(int index) =>
      companion.writesInto(halo.charJRequestToDeviceCmd.uuid).elementAt(index);

  group("HaloBleRequestToDeviceHardware.callOrder", () {
    test("starts the exchange over before it asks the device for anything", () async {
      await hardware.callOrder(request: aRequest(requestId: FakeHaloRequestId.anOrder));

      expect(commandWritten(0)[0], HaloCmdId.reset.rawValue);
      expect(commandWritten(1)[0], HaloCmdId.call.rawValue);
    });

    test("waits for nothing of an order which carries no parameter", () async {
      final result = await hardware.callOrder(
        request: aRequest(requestId: FakeHaloRequestId.anOrder),
      );

      expect(result, HaloErrorType.noError);
      expect(companion.writes.last.waited, isFalse);
    });

    test("says that the exchange could not be started over", () async {
      companion.answers.add((HaloErrorType.commError, null));

      final result = await hardware.callOrder(
        request: aRequest(requestId: FakeHaloRequestId.anOrder),
      );

      expect(result, HaloErrorType.commError);
      expect(companion.writes.length, 1);
    });

    test("says that the order could not be written to the device", () async {
      companion.writeAnswer = HaloErrorType.commError;

      final result = await hardware.callOrder(
        request: aRequest(requestId: FakeHaloRequestId.anOrder),
      );

      expect(result, HaloErrorType.commError);
    });

    test("asks for nothing of a request which is not an order", () async {
      final result = await hardware.callOrder(
        request: aRequest(requestId: FakeHaloRequestId.aProcedure),
      );

      expect(result, HaloErrorType.formatError);
      expect(companion.writes, isEmpty);
    });
  });

  group("HaloBleRequestToDeviceHardware.callProcedure", () {
    test("asks the device for the procedure and waits for it to answer", () async {
      final result = await hardware.callProcedure(
        request: aRequest(requestId: FakeHaloRequestId.aProcedure),
      );

      expect(result, HaloErrorType.noError);
      expect(commandWritten(1)[1], FakeHaloRequestId.aProcedure.rawValue);
      expect(companion.writes.last.waited, isTrue);
    });

    test("answers the error the device raised", () async {
      companion.answers.addAll([
        (HaloErrorType.noError, anAck(requestId: FakeHaloRequestId.aProcedure)),
        (
          HaloErrorType.noError,
          anAck(requestId: FakeHaloRequestId.aProcedure, error: HaloErrorType.formatError),
        ),
      ]);

      final result = await hardware.callProcedure(
        request: aRequest(requestId: FakeHaloRequestId.aProcedure),
      );

      expect(result, HaloErrorType.formatError);
    });

    test("says that the answer of the device could not be read", () async {
      companion.answers.addAll([
        (HaloErrorType.noError, anAck(requestId: FakeHaloRequestId.aProcedure)),
        (HaloErrorType.noError, Uint8List.fromList(const [0x06, 0x00])),
      ]);

      final result = await hardware.callProcedure(
        request: aRequest(requestId: FakeHaloRequestId.aProcedure),
      );

      expect(result, HaloErrorType.genericError);
    });

    test("hands the parameters of the request over after the request itself", () async {
      final result = await hardware.callProcedure(
        request: aRequest(
          requestId: FakeHaloRequestId.aProcedure,
          nbValues: const [1],
          parameters: const ["a parameter"],
        ),
      );

      expect(result, HaloErrorType.noError);
      expect(companion.writesInto(halo.charKRequestToDeviceTmp.uuid).length, 1);
    });

    test("hands a parameter which is too long over in several packets", () async {
      final aLongParameter = "a parameter which does not fit in one packet of the device";

      await hardware.callProcedure(
        request: aRequest(
          requestId: FakeHaloRequestId.aProcedure,
          nbValues: const [1],
          parameters: [aLongParameter],
        ),
      );

      // The packet of the parameters carries the parameter itself between the two bytes which
      // frame it, and it is cut in as many packets as the device takes
      expect(
        companion.writesInto(halo.charKRequestToDeviceTmp.uuid).length,
        ((aLongParameter.length + 2) / aMaxCharacteristicByteSize).ceil(),
      );
    });

    test("says that the parameters could not be handed over", () async {
      companion.answers.addAll([
        (HaloErrorType.noError, anAck(requestId: FakeHaloRequestId.aProcedure)),
        (HaloErrorType.noError, anAck(requestId: FakeHaloRequestId.aProcedure)),
        (HaloErrorType.commError, null),
      ]);

      final result = await hardware.callProcedure(
        request: aRequest(
          requestId: FakeHaloRequestId.aProcedure,
          nbValues: const [1],
          parameters: const ["a parameter"],
        ),
      );

      expect(result, HaloErrorType.commError);
    });

    test("asks the device for nothing more once the procedure was called", () async {
      await hardware.callProcedure(
        request: aRequest(requestId: FakeHaloRequestId.aProcedure),
      );

      expect(companion.writes.length, 2);
    });
  });

  group("HaloBleRequestToDeviceHardware.callFunction", () {
    /// Has the device answer the acknowledgments of a function and then [values] as its result.
    void theDeviceAnswers(List<String> values, {int maxPacketSize = -1}) {
      companion.answers.addAll([
        (HaloErrorType.noError, anAck(requestId: FakeHaloRequestId.aFunction)),
        (HaloErrorType.noError, anAck(requestId: FakeHaloRequestId.aFunction)),
        ...aPayloadFromDevice(values, maxPacketSize: maxPacketSize).map(
          (packet) => (HaloErrorType.noError, packet),
        ),
      ]);
    }

    test("reads the result the device answers", () async {
      theDeviceAnswers(const ["a result"]);

      final result = await hardware.callFunction(request: aRequest());

      expect(result.error, HaloErrorType.noError);
      expect(result.result?.getString(0)?.$1, "a result");
    });

    test("asks the device to hand its result over", () async {
      theDeviceAnswers(const ["a result"]);

      await hardware.callFunction(request: aRequest());

      expect(commandWritten(2)[0], HaloCmdId.readReady.rawValue);
    });

    test("reads a result the device hands over in several packets", () async {
      theDeviceAnswers(const ["a result which does not fit in one packet"], maxPacketSize: 16);

      final result = await hardware.callFunction(request: aRequest());

      expect(result.error, HaloErrorType.noError);
      expect(result.result?.getString(0)?.$1, "a result which does not fit in one packet");
    });

    test("reads every value of a result which carries several", () async {
      theDeviceAnswers(const ["the first", "the second"]);

      final result = await hardware.callFunction(request: aRequest());

      expect(result.result?.elementsNb, 2);
      expect(result.result?.getString(1)?.$1, "the second");
    });

    test("says that the result of the device could not be read", () async {
      companion.answers.addAll([
        (HaloErrorType.noError, anAck(requestId: FakeHaloRequestId.aFunction)),
        (HaloErrorType.noError, anAck(requestId: FakeHaloRequestId.aFunction)),
        (HaloErrorType.noError, Uint8List.fromList(const [0x2A, 0xC1])),
      ]);

      final result = await hardware.callFunction(request: aRequest());

      expect(result.error, HaloErrorType.formatError);
    });

    test("says that the result could not be asked for", () async {
      companion.answers.addAll([
        (HaloErrorType.noError, anAck(requestId: FakeHaloRequestId.aFunction)),
        (HaloErrorType.noError, anAck(requestId: FakeHaloRequestId.aFunction)),
        (HaloErrorType.commError, null),
      ]);

      final result = await hardware.callFunction(request: aRequest());

      expect(result.error, HaloErrorType.commError);
    });

    test("reads a result of a device which answered no value at all", () async {
      companion.answers.addAll([
        (HaloErrorType.noError, anAck(requestId: FakeHaloRequestId.aFunction)),
        (HaloErrorType.noError, anAck(requestId: FakeHaloRequestId.aFunction)),
        (HaloErrorType.noError, Uint8List.fromList(const [0xC0, 0xC1])),
      ]);

      final result = await hardware.callFunction(request: aRequest());

      expect(result.error, HaloErrorType.noError);
      expect(result.result?.elementsNb, 0);
    });

    test("asks for nothing of a request which is not a function", () async {
      final result = await hardware.callFunction(
        request: aRequest(requestId: FakeHaloRequestId.anOrder),
      );

      expect(result.error, HaloErrorType.formatError);
      expect(companion.writes, isEmpty);
    });

    test("lets the device take the time the caller allows it", () async {
      theDeviceAnswers(const ["a result"]);

      final result = await hardware.callFunction(
        request: aRequest(),
        executionTimeout: aShortTimeout,
      );

      expect(result.error, HaloErrorType.noError);
    });
  });

  group("HaloBleRequestToDeviceHardware.close", () {
    test("holds nothing which has to be given up", () async {
      await hardware.close();

      expect(companion.writes, isEmpty);
    });
  });
}
