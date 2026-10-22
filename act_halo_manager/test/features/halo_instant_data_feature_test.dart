// SPDX-FileCopyrightText: 2026 Damien Manceau <damien.manceau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_manager/act_halo_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_halo.dart';

void main() {
  setUp(FakeGlobalManager.install);

  /// The instant data the tests exchange with the device.
  const anInstantData = HaloDataId<int>(id: 0x04, value: 0x04);

  /// The value the device holds for the instant data.
  HaloPayloadPacket aValue() => HaloPayloadPacket()..addUInt16(5000);

  /// Builds the feature of an application whose device answers [errors] and [result].
  ({HaloInstantDataFeature<FakeHwType> feature, FakeInstantDataHardware device}) aFeature({
    List<HaloErrorType> errors = const [HaloErrorType.noError],
    HaloPayloadPacket? result,
    FakeHwType hardwareType = FakeHwType.ble,
    int retryNbBeforeReturningError = HaloManagerConfig.defaultRetryNumber,
  }) {
    final device = FakeInstantDataHardware(errors: errors, result: result);
    final config = HaloManagerConfig<FakeHwType>(
      hardwareLayer: FakeHwTypeHelper.only(
        type: hardwareType,
        requestToDevice: FakeRequestToDeviceHardware(),
        instantData: device,
      ),
      requestIdHelper: FakeRequestIdHelper(),
      retryNbBeforeReturningError: retryNbBeforeReturningError,
    );

    return (feature: HaloInstantDataFeature<FakeHwType>(haloManagerConfig: config), device: device);
  }

  group("HaloInstantDataFeature.readInstantData", () {
    test("answers the values the device holds", () async {
      final value = aValue();
      final (:feature, :device) = aFeature(result: value);

      final (error, payload) = await feature.readInstantData(
        hardwareType: FakeHwType.ble,
        dataId: anInstantData,
      );

      expect(error, HaloErrorType.noError);
      expect(payload, value);
      expect(device.calls, ["read 4"]);
    });

    test("asks again while the error is one which may pass", () async {
      final (:feature, :device) = aFeature(
        errors: [HaloErrorType.commError, HaloErrorType.noError],
        result: aValue(),
      );

      final (error, payload) = await feature.readInstantData(
        hardwareType: FakeHwType.ble,
        dataId: anInstantData,
      );

      expect(error, HaloErrorType.noError);
      expect(payload, isNotNull);
      expect(device.calls, hasLength(2));
    });

    test("gives up once it has asked as many times as the application allows", () async {
      final (:feature, :device) = aFeature(
        errors: [HaloErrorType.serviceBusyError],
        retryNbBeforeReturningError: 3,
      );

      final (error, payload) = await feature.readInstantData(
        hardwareType: FakeHwType.ble,
        dataId: anInstantData,
      );

      expect(error, HaloErrorType.serviceBusyError);
      expect(payload, isNull);
      expect(device.calls, hasLength(3));
    });

    test("asks only once when the error is one which will not pass", () async {
      final (:feature, :device) = aFeature(errors: [HaloErrorType.protocolError]);

      final (error, _) = await feature.readInstantData(
        hardwareType: FakeHwType.ble,
        dataId: anInstantData,
      );

      expect(error, HaloErrorType.protocolError);
      expect(device.calls, hasLength(1));
    });

    test("answers an error when the application cannot reach the device that way", () async {
      final (:feature, :device) = aFeature(hardwareType: FakeHwType.serial);

      final (error, payload) = await feature.readInstantData(
        hardwareType: FakeHwType.ble,
        dataId: anInstantData,
      );

      expect(error, HaloErrorType.genericError);
      expect(payload, isNull);
      expect(device.calls, isEmpty);
    });

    test("goes on answering after the hardware threw", () async {
      final (:feature, :device) = aFeature(result: aValue());
      device.throwOnNextCall = true;

      await expectLater(
        feature.readInstantData(hardwareType: FakeHwType.ble, dataId: anInstantData),
        throwsStateError,
      );
      final (error, _) = await feature
          .readInstantData(hardwareType: FakeHwType.ble, dataId: anInstantData)
          .timeout(const Duration(seconds: 2));

      expect(error, HaloErrorType.noError);
    });
  });

  group("HaloInstantDataFeature.subInstantData", () {
    test("subscribes, then unsubscribes, through the device", () async {
      final (:feature, :device) = aFeature();

      final sub = await feature.subInstantData(hardwareType: FakeHwType.ble, dataId: anInstantData);
      final unSub = await feature.unSubInstantData(
        hardwareType: FakeHwType.ble,
        dataId: anInstantData,
      );

      expect(sub, HaloErrorType.noError);
      expect(unSub, HaloErrorType.noError);
      expect(device.calls, ["sub 4", "unsub 4"]);
    });
  });

  group("HaloInstantDataFeature.instDataNewValueStream", () {
    test("gives the new values the device sent", () async {
      final (:feature, :device) = aFeature();
      final packet = HaloPacket(dataId: anInstantData, payload: aValue());
      final received = feature.instDataNewValueStream(hardwareType: FakeHwType.ble).first;

      device.tellNewValue(packet);

      expect(await received, packet);
    });

    test("is empty when the application cannot reach the device that way", () async {
      final (:feature, device: _) = aFeature(hardwareType: FakeHwType.serial);

      expect(await feature.instDataNewValueStream(hardwareType: FakeHwType.ble).toList(), isEmpty);
    });
  });
}
