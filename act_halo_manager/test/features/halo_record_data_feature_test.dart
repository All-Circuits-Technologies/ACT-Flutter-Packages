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

  /// The historical data the tests exchange with the device.
  const aRecordData = HaloDataId<int>(id: 0x01, value: 0x01);

  /// The key of the archive [index] of the historical data.
  HaloRecordKey aKey(int index) => HaloRecordKey(dataId: aRecordData, uniqueIndex: index);

  /// Builds the feature of an application whose device stores the archives [stored], exposes
  /// [windowSize] of them and answers [errors].
  ({HaloRecordDataFeature<FakeHwType> feature, FakeRecordDataHardware device}) aFeature({
    List<HaloErrorType> errors = const [HaloErrorType.noError],
    List<int> stored = const [],
    int windowSize = 255,
    FakeHwType hardwareType = FakeHwType.ble,
    int retryNbBeforeReturningError = HaloManagerConfig.defaultRetryNumber,
  }) {
    final device = FakeRecordDataHardware(errors: errors, stored: stored, windowSize: windowSize);
    final config = HaloManagerConfig<FakeHwType>(
      hardwareLayer: FakeHwTypeHelper.only(
        type: hardwareType,
        requestToDevice: FakeRequestToDeviceHardware(),
        record: device,
      ),
      requestIdHelper: FakeRequestIdHelper(),
      retryNbBeforeReturningError: retryNbBeforeReturningError,
    );

    return (feature: HaloRecordDataFeature<FakeHwType>(haloManagerConfig: config), device: device);
  }

  group("HaloRecordDataFeature.getAllRecordDataKeys", () {
    test("answers the keys the device exposes", () async {
      final (:feature, :device) = aFeature(stored: [1, 2, 3], windowSize: 2);

      final result = await feature.getAllRecordDataKeys(
        hardwareType: FakeHwType.ble,
        dataId: aRecordData,
      );

      expect(result.status, HaloErrorType.noError);
      expect(result.value, [aKey(1), aKey(2)]);
      expect(device.calls, ["getall 1"]);
    });

    test("asks again while the error is one which may pass", () async {
      final (:feature, :device) = aFeature(
        errors: [HaloErrorType.commError, HaloErrorType.noError],
        stored: [1],
      );

      final result = await feature.getAllRecordDataKeys(
        hardwareType: FakeHwType.ble,
        dataId: aRecordData,
      );

      expect(result.status, HaloErrorType.noError);
      expect(result.value, [aKey(1)]);
      expect(device.calls, hasLength(2));
    });

    test("gives up once it has asked as many times as the application allows", () async {
      final (:feature, :device) = aFeature(
        errors: [HaloErrorType.serviceBusyError],
        retryNbBeforeReturningError: 3,
      );

      final result = await feature.getAllRecordDataKeys(
        hardwareType: FakeHwType.ble,
        dataId: aRecordData,
      );

      expect(result.status, HaloErrorType.serviceBusyError);
      expect(result.value, isNull);
      expect(device.calls, hasLength(3));
    });

    test("asks only once when the error is one which will not pass", () async {
      final (:feature, :device) = aFeature(errors: [HaloErrorType.protocolError]);

      final result = await feature.getAllRecordDataKeys(
        hardwareType: FakeHwType.ble,
        dataId: aRecordData,
      );

      expect(result.status, HaloErrorType.protocolError);
      expect(device.calls, hasLength(1));
    });

    test("answers an error when the application cannot reach the device that way", () async {
      final (:feature, :device) = aFeature(hardwareType: FakeHwType.serial);

      final result = await feature.getAllRecordDataKeys(
        hardwareType: FakeHwType.ble,
        dataId: aRecordData,
      );

      expect(result.status, HaloErrorType.genericError);
      expect(result.value, isNull);
      expect(device.calls, isEmpty);
    });

    test("goes on answering after the hardware threw", () async {
      final (:feature, :device) = aFeature();
      device.throwOnNextCall = true;

      await expectLater(
        feature.getAllRecordDataKeys(hardwareType: FakeHwType.ble, dataId: aRecordData),
        throwsStateError,
      );
      final result = await feature
          .getAllRecordDataKeys(hardwareType: FakeHwType.ble, dataId: aRecordData)
          .timeout(const Duration(seconds: 2));

      expect(result.status, HaloErrorType.noError);
    });
  });

  group("HaloRecordDataFeature.readRecordData", () {
    test("answers the archive the device holds", () async {
      final (:feature, :device) = aFeature(stored: [7]);

      final result = await feature.readRecordData(hardwareType: FakeHwType.ble, recordKey: aKey(7));

      expect(result.status, HaloErrorType.noError);
      expect(result.value!.recordKey, aKey(7));
      expect(result.value!.payload.getUInt(0).value, const HaloTimestampedValue(data: 7));
      expect(device.calls, ["read 1/7"]);
    });

    test("gives the error of the device", () async {
      final (:feature, device: _) = aFeature(errors: [HaloErrorType.protocolError]);

      final result = await feature.readRecordData(hardwareType: FakeHwType.ble, recordKey: aKey(7));

      expect(result.status, HaloErrorType.protocolError);
      expect(result.value, isNull);
    });
  });

  group("HaloRecordDataFeature.ackRecordData", () {
    test("tells the device the archive is saved, and it frees it", () async {
      final (:feature, :device) = aFeature(stored: [1, 2]);

      final error = await feature.ackRecordData(hardwareType: FakeHwType.ble, recordKey: aKey(1));

      expect(error, HaloErrorType.noError);
      expect(device.calls, ["ack 1/1"]);
      expect(device.stored, [2]);
    });

    test("asks again while the error is one which may pass", () async {
      final (:feature, :device) = aFeature(
        errors: [HaloErrorType.commError, HaloErrorType.noError],
      );

      final error = await feature.ackRecordData(hardwareType: FakeHwType.ble, recordKey: aKey(1));

      expect(error, HaloErrorType.noError);
      expect(device.calls, ["ack 1/1", "ack 1/1"]);
    });
  });

  group("HaloRecordDataFeature.subRecordData", () {
    test("subscribes, then unsubscribes, through the device", () async {
      final (:feature, :device) = aFeature();

      final sub = await feature.subRecordData(hardwareType: FakeHwType.ble, dataId: aRecordData);
      final unSub = await feature.unSubRecordData(
        hardwareType: FakeHwType.ble,
        dataId: aRecordData,
      );

      expect(sub, HaloErrorType.noError);
      expect(unSub, HaloErrorType.noError);
      expect(device.calls, ["sub 1", "unsub 1"]);
    });
  });

  group("HaloRecordDataFeature.recordKeysNewValueStream", () {
    test("gives the keys the device said are waiting", () async {
      final (:feature, :device) = aFeature();
      final received = feature.recordKeysNewValueStream(hardwareType: FakeHwType.ble).first;

      device.tellNewKey(aKey(4));

      expect(await received, aKey(4));
    });

    test("is empty when the application cannot reach the device that way", () async {
      final (:feature, device: _) = aFeature(hardwareType: FakeHwType.serial);

      expect(
        await feature.recordKeysNewValueStream(hardwareType: FakeHwType.ble).toList(),
        isEmpty,
      );
    });
  });

  group("HaloRecordDataFeature.drainRecords", () {
    /// Drains the data and returns the error with the indexes [onRecord] was given.
    Future<(HaloErrorType, List<int>)> drain(
      HaloRecordDataFeature<FakeHwType> feature, {
      bool Function(int index)? accept,
    }) async {
      final given = <int>[];
      final error = await feature.drainRecords(
        hardwareType: FakeHwType.ble,
        dataId: aRecordData,
        onRecord: (record) async {
          final index = record.recordKey.uniqueIndex;
          given.add(index);

          return accept?.call(index) ?? true;
        },
      );

      return (error, given);
    }

    test("reads and acknowledges the 5 archives of a device which exposes 2 at a time", () async {
      final (:feature, :device) = aFeature(stored: [1, 2, 3, 4, 5], windowSize: 2);

      final (error, given) = await drain(feature);

      expect(error, HaloErrorType.noError);
      expect(given, [1, 2, 3, 4, 5]);
      expect(device.calls.where((call) => call.startsWith("ack")), [
        "ack 1/1",
        "ack 1/2",
        "ack 1/3",
        "ack 1/4",
        "ack 1/5",
      ]);
      expect(device.stored, isEmpty);
      // One list per window, the last one being the empty one which ends the loop
      expect(device.calls.where((call) => call.startsWith("getall")), hasLength(4));
    });

    test("asks nothing more than the list when the device holds nothing", () async {
      final (:feature, :device) = aFeature();

      final (error, given) = await drain(feature);

      expect(error, HaloErrorType.noError);
      expect(given, isEmpty);
      expect(device.calls, ["getall 1"]);
    });

    test("acknowledges nothing the application did not save, and does not read it again", () async {
      final (:feature, :device) = aFeature(stored: [1, 2, 3, 4], windowSize: 2);

      final (error, given) = await drain(feature, accept: (index) => index != 2);

      expect(error, HaloErrorType.noError);
      expect(given, [1, 2, 3, 4]);
      expect(device.calls, isNot(contains("ack 1/2")));
      expect(device.stored, [2]);
    });

    test(
      "ends when the application saves none of the archives, whatever the device holds",
      () async {
        final (:feature, :device) = aFeature(stored: [1, 2, 3], windowSize: 2);

        final (error, given) = await drain(feature, accept: (_) => false);

        expect(error, HaloErrorType.noError);
        expect(given, [1, 2]);
        expect(device.stored, [1, 2, 3]);
        expect(device.calls.where((call) => call.startsWith("ack")), isEmpty);
      },
    );

    test("stops on the error of a read, and acknowledges nothing after it", () async {
      final (:feature, :device) = aFeature(
        errors: [
          HaloErrorType.noError,
          HaloErrorType.noError,
          HaloErrorType.noError,
          HaloErrorType.protocolError,
        ],
        stored: [1, 2],
      );

      final (error, given) = await drain(feature);

      expect(error, HaloErrorType.protocolError);
      expect(given, [1]);
      expect(device.calls, ["getall 1", "read 1/1", "ack 1/1", "read 1/2"]);
    });

    test("stops on the error of an acknowledgment", () async {
      final (:feature, :device) = aFeature(
        errors: [HaloErrorType.noError, HaloErrorType.noError, HaloErrorType.protocolError],
        stored: [1, 2],
      );

      final (error, given) = await drain(feature);

      expect(error, HaloErrorType.protocolError);
      expect(given, [1]);
      expect(device.stored, [1, 2]);
    });

    test("gives the error of the list", () async {
      final (:feature, device: _) = aFeature(errors: [HaloErrorType.protocolError]);

      final (error, given) = await drain(feature);

      expect(error, HaloErrorType.protocolError);
      expect(given, isEmpty);
    });

    test("lets the application call the device while it saves an archive", () async {
      final (:feature, :device) = aFeature(stored: [1]);

      final error = await feature
          .drainRecords(
            hardwareType: FakeHwType.ble,
            dataId: aRecordData,
            onRecord: (_) async {
              await feature.subRecordData(hardwareType: FakeHwType.ble, dataId: aRecordData);

              return true;
            },
          )
          .timeout(const Duration(seconds: 2));

      expect(error, HaloErrorType.noError);
      expect(device.calls, contains("sub 1"));
    });
  });
}
