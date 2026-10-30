// SPDX-FileCopyrightText: 2026 Damien Manceau <damien.manceau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:typed_data';

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/act_halo_ble_layer.dart';
// The hardware layers are handed over by the hardware of the package rather than built by an
// application, so they are not part of its public interface
// ignore: implementation_imports
import 'package:act_halo_ble_layer/src/hardware_layer/halo_ble_record_data_hardware.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_halo_ble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  late FakeBlePlatform ble;
  late FakeAppLifeCycleManager lifeCycle;
  late BleManager manager;
  late FakeBleConfigManager config;
  late HaloBleConfig halo;
  late FakeHaloCompanion companion;
  late HaloBleRecordDataHardware hardware;
  late StreamController<List<int>> notificationsOfG;

  setUpAll(() => ble = FakeBlePlatform.install());

  setUp(() async {
    ble.reset();
    globalManager = FakeGlobalManager.install();
    FakePermissionsPlatform.install();
    lifeCycle = FakeAppLifeCycleManager();
    globalGetIt()
      ..registerSingleton<PlatformManager>(FakePlatformManager())
      ..registerSingleton<AppLifeCycleManager>(lifeCycle)
      ..registerSingleton<PermissionsManager>(PermissionsManager());

    config = await FakeBleConfigManager.withContent(aBleConf);
    manager = BleManager(confGetter: () => config);
    globalGetIt().registerSingleton<BleManager>(manager);
    // The notifications of the characteristics are logged by the manager
    await manager.initLifeCycle();

    halo = aHaloConfig();
    companion = FakeHaloCompanion(haloBleConfig: halo, bleManager: manager);
    hardware = HaloBleRecordDataHardware(bleCompanion: companion);

    notificationsOfG = StreamController<List<int>>();
    await halo.charGRecordNotify.onStreamUpdate(notificationsOfG.stream, const Stream.empty());
  });

  tearDown(() async {
    await hardware.close();
    await notificationsOfG.close();
    FakeAssets.stop();
    await manager.disposeLifeCycle();
    await config.disposeLifeCycle();
    await lifeCycle.close();
    await globalManager.reset();
  });

  /// The historical data [id] of the device.
  HaloDataId<int> aData(int id) => HaloDataId<int>(id: id, value: id);

  /// The key of the archive [index] of the historical data [id].
  HaloRecordKey<dynamic> aKey(int id, int index) =>
      HaloRecordKey<dynamic>(dataId: aData(id), uniqueIndex: index);

  /// An answer of the device, made of the [bytes].
  ResultWithRequiredValue<HaloErrorType, Uint8List> answer(List<int> bytes) =>
      ResultWithRequiredValue(status: HaloErrorType.noError, value: Uint8List.fromList(bytes));

  /// The timestamp of the spec Annex A.4.
  final aDate = DateTime.fromMillisecondsSinceEpoch(1761048000 * 1000, isUtc: true);

  /// What was written into the characteristic of the commands (H).
  List<List<int>> commands() => companion.writesInto(halo.charHRecordCmd.uuid).toList();

  group("HaloBleRecordDataHardware.getAllRecordDataKeys", () {
    test("replays the list of the keys of the data 0x01 of the spec", () async {
      companion.answers.addAll([
        answer([0x00, 0x01, 0x00, 0x01]),
        answer([0xC0, 0x01, 0x01, 0xC1]),
      ]);

      final result = await hardware.getAllRecordDataKeys(dataId: aData(0x01));

      expect(result.status, HaloErrorType.noError);
      expect(result.value, [aKey(0x01, 0x01)]);
      expect(commands(), [
        [0x00, 0x00, 0x00, 0x01],
        [0x01, 0x00, 0x00, 0x01],
      ]);
    });

    test("unescapes the keys and gives them all, the order of the device kept", () async {
      companion.answers.addAll([
        answer([0x00, 0x02, 0x00, 0x01]),
        // The indexes 0xC0 and 0x02 then 0x7D, the data being 0x01
        answer([0xC0, 0x7D, 0xE0, 0x01, 0x02, 0x01, 0xC1]),
      ]);

      final result = await hardware.getAllRecordDataKeys(dataId: aData(0x01));

      expect(result.value, [aKey(0x01, 0xC0), aKey(0x01, 0x02)]);
    });

    test("gives no key when the device holds none", () async {
      companion.answers.addAll([
        answer([0x00, 0x00, 0x00, 0x01]),
        answer([0xC0, 0xC1]),
      ]);

      final result = await hardware.getAllRecordDataKeys(dataId: aData(0x01));

      expect(result.status, HaloErrorType.noError);
      expect(result.value, isEmpty);
    });

    test("refuses a list which cuts a key in two", () async {
      companion.answers.addAll([
        answer([0x00, 0x01, 0x00, 0x01]),
        answer([0xC0, 0x01, 0x01, 0x01, 0xC1]),
      ]);

      final result = await hardware.getAllRecordDataKeys(dataId: aData(0x01));

      expect(result.status, HaloErrorType.formatError);
      expect(result.value, isNull);
    });

    test("gives the error of the device and stops there", () async {
      companion.answers.add(answer([0x02, 0x00, 0x00, 0x09]));

      final result = await hardware.getAllRecordDataKeys(dataId: aData(0x09));

      expect(result.status, HaloErrorType.protocolError);
      expect(result.value, isNull);
    });
  });

  group("HaloBleRecordDataHardware.readRecordData", () {
    test("replays the read of the segment 0x0101 of the spec, in two packets", () async {
      companion.answers.addAll([
        answer([0x00, 0x04, 0x01, 0x01]),
        answer([
          0xC0, 0x7D, 0xE0, 0x75, 0xF7, 0x68, 0x3A, 0x7D, 0xE0, 0x75, //
          0xF7, 0x68, 0x7C, 0x52, 0x1C, 0x7C, 0x8E, 0x1C, 0x7C, 0xFF,
        ]),
        answer([0xFF, 0xC1]),
      ]);

      final result = await hardware.readRecordData(recordKey: aKey(0x01, 0x01));

      expect(result.status, HaloErrorType.noError);
      expect(result.value!.recordKey, aKey(0x01, 0x01));
      expect(
        result.value!.payload.getUInt(0).value,
        HaloTimestampedValue(data: 1761048000, timestamp: aDate),
      );
      expect(result.value!.payload.getUInt(1).value, const HaloTimestampedValue(data: 7250));
      expect(result.value!.payload.getUInt(2).value, const HaloTimestampedValue(data: 7310));
      expect(result.value!.payload.getUInt(3).value, const HaloTimestampedValue(data: 0xFFFF));
      expect(commands(), [
        [0x00, 0x00, 0x01, 0x01],
        [0x01, 0x00, 0x01, 0x01],
        [0x01, 0x00, 0x01, 0x01],
      ]);
    });

    test("replays the read of the header 0x0001 of the spec", () async {
      companion.answers.addAll([
        answer([0x00, 0x05, 0x01, 0x00]),
        answer([
          0xC0, 0x7D, 0xE0, 0x75, 0xF7, 0x68, 0x3A, 0x7D, 0xE0, 0x75, //
          0xF7, 0x68, 0x7C, 0x57, 0x7C, 0x55, 0x7C, 0x01, 0x7C, 0x01,
        ]),
        answer([0x00, 0xC1]),
      ]);

      final result = await hardware.readRecordData(recordKey: aKey(0x00, 0x01));

      expect(result.status, HaloErrorType.noError);
      expect(result.value!.payload.elementsNb, 5);
      expect(
        result.value!.payload.getUInt(0).value,
        HaloTimestampedValue(data: 1761048000, timestamp: aDate),
      );
      expect(result.value!.payload.getUInt(1).value, const HaloTimestampedValue(data: 87));
      expect(result.value!.payload.getUInt(2).value, const HaloTimestampedValue(data: 85));
      expect(result.value!.payload.getUInt(3).value, const HaloTimestampedValue(data: 1));
      expect(result.value!.payload.getUInt(4).value, const HaloTimestampedValue(data: 1));
      expect(commands().first, [0x00, 0x00, 0x01, 0x00]);
    });

    test("gives the error of the device and stops there", () async {
      companion.answers.add(answer([0x02, 0x00, 0x05, 0x01]));

      final result = await hardware.readRecordData(recordKey: aKey(0x01, 0x05));

      expect(result.status, HaloErrorType.protocolError);
      expect(result.value, isNull);
      expect(commands(), hasLength(1));
    });

    test("does not mix the steps of two reads asked together", () async {
      companion.answers.addAll([
        answer([0x00, 0x01, 0x01, 0x01]),
        answer([0xC0, 0xC1]),
        answer([0x00, 0x01, 0x02, 0x01]),
        answer([0xC0, 0xC1]),
      ]);

      await Future.wait([
        hardware.readRecordData(recordKey: aKey(0x01, 0x01)),
        hardware.readRecordData(recordKey: aKey(0x01, 0x02)),
      ]);

      expect(commands(), [
        [0x00, 0x00, 0x01, 0x01],
        [0x01, 0x00, 0x01, 0x01],
        [0x00, 0x00, 0x02, 0x01],
        [0x01, 0x00, 0x02, 0x01],
      ]);
    });
  });

  group("HaloBleRecordDataHardware.ackRecordData", () {
    test("replays the acknowledgment of the segment of the spec", () async {
      companion.answers.add(answer([0x00, 0x00, 0x01, 0x01]));

      final error = await hardware.ackRecordData(recordKey: aKey(0x01, 0x01));

      expect(error, HaloErrorType.noError);
      expect(commands(), [
        [0x06, 0x00, 0x01, 0x01],
      ]);
    });

    test("gives the refusal of the device to acknowledge them all", () async {
      companion.answers.add(answer([0x02, 0x00, 0x00, 0x00]));

      final error = await hardware.ackRecordData(recordKey: HaloRecordKey.getAll(dataId: aData(0)));

      expect(error, HaloErrorType.protocolError);
      expect(commands(), [
        [0x06, 0x00, 0x00, 0x00],
      ]);
    });

    test("refuses a result which is for another key", () async {
      companion.answers.add(answer([0x00, 0x00, 0x02, 0x01]));

      final error = await hardware.ackRecordData(recordKey: aKey(0x01, 0x01));

      expect(error, HaloErrorType.formatError);
    });
  });

  group("HaloBleRecordDataHardware.subRecordData", () {
    test("subscribes, then unsubscribes, to the data whatever the index", () async {
      companion.answers.addAll([
        answer([0x00, 0x00, 0x00, 0x01]),
        answer([0x00, 0x00, 0x00, 0x01]),
      ]);

      expect(await hardware.subRecordData(dataId: aData(0x01)), HaloErrorType.noError);
      expect(await hardware.unSubRecordData(dataId: aData(0x01)), HaloErrorType.noError);
      expect(commands(), [
        [0x04, 0x00, 0x00, 0x01],
        [0x05, 0x00, 0x00, 0x01],
      ]);
    });
  });

  group("HaloBleRecordDataHardware.recordKeysNewValueStream", () {
    /// Tells the hardware that the device notified the [keys] on G and returns what the hardware
    /// gave out for it, [count] keys.
    Future<List<HaloRecordKey>> notified(List<int> keys, int count) async {
      final received = hardware.recordKeysNewValueStream.take(count).toList();
      notificationsOfG.add(keys);

      return received.timeout(const Duration(seconds: 2));
    }

    test("gives the keys of the G of the spec, oldest first", () async {
      final keys = await notified([0x01, 0x01, 0x01, 0x00], 2);

      expect(keys, [aKey(0x01, 0x01), aKey(0x00, 0x01)]);
      expect(companion.writes, isEmpty);
    });

    test("gives the key left in G after the acknowledgment of the spec", () async {
      final keys = await notified([0x01, 0x00], 1);

      expect(keys, [aKey(0x00, 0x01)]);
    });

    test("gives nothing when G is empty, and the next keys all the same", () async {
      notificationsOfG.add(const []);
      final keys = await notified([0x02, 0x01], 1);

      expect(keys, [aKey(0x01, 0x02)]);
    });

    test("keeps the exchange of a read going when G is notified in the middle of it", () async {
      companion.answers.addAll([
        answer([0x00, 0x01, 0x01, 0x01]),
        answer([0xC0, 0xC1]),
      ]);

      final read = hardware.readRecordData(recordKey: aKey(0x01, 0x01));
      final keys = await notified([0x03, 0x01], 1);
      final result = await read;

      expect(keys, [aKey(0x01, 0x03)]);
      expect(result.status, HaloErrorType.noError);
      expect(commands(), [
        [0x00, 0x00, 0x01, 0x01],
        [0x01, 0x00, 0x01, 0x01],
      ]);
    });
  });
}
