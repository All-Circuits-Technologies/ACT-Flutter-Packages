// SPDX-FileCopyrightText: 2026 Damien Manceau <damien.manceau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:typed_data';

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_ble_layer/act_halo_ble_layer.dart';
// The hardware layers are handed over by the hardware of the package rather than built by an
// application, so they are not part of its public interface
// ignore: implementation_imports
import 'package:act_halo_ble_layer/src/hardware_layer/halo_ble_instant_data_hardware.dart';
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
  late HaloBleInstantDataHardware hardware;
  late StreamController<List<int>> notificationsOfD;

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
    hardware = HaloBleInstantDataHardware(bleCompanion: companion);

    notificationsOfD = StreamController<List<int>>();
    await halo.charDInstNotify.onStreamUpdate(notificationsOfD.stream, const Stream.empty());
  });

  tearDown(() async {
    await hardware.close();
    await notificationsOfD.close();
    FakeAssets.stop();
    await manager.disposeLifeCycle();
    await config.disposeLifeCycle();
    await lifeCycle.close();
    await globalManager.reset();
  });

  /// The instant data [id] of the device.
  HaloDataId<int> aData(int id) => HaloDataId<int>(id: id, value: id);

  /// An answer of the device, made of the [bytes].
  (HaloErrorType, Uint8List?) answer(List<int> bytes) =>
      (HaloErrorType.noError, Uint8List.fromList(bytes));

  /// The timestamp of the spec Annex A.3.
  final aDate = DateTime.fromMillisecondsSinceEpoch(1761048000 * 1000, isUtc: true);

  /// What the device answers when the data [id] is read and holds the U2 [value] stamped [aDate].
  List<(HaloErrorType, Uint8List?)> readAnswers(int id, int value) {
    final payload = HaloPayloadPacket()..addUInt16(value, ts: aDate);

    return [
      answer([0x00, 0x01, id]),
      answer(payload.getDataToSend().single),
    ];
  }

  /// What was written into the characteristic of the commands (E).
  List<List<int>> commands() => companion.writesInto(halo.charEInstCmd.uuid).toList();

  group("HaloBleInstantDataHardware.readInstantData", () {
    test("replays the read of the load 0x00 of the spec", () async {
      companion.answers.addAll([
        answer([0x00, 0x01, 0x00]),
        answer([0xC0, 0x7D, 0xE0, 0x75, 0xF7, 0x68, 0x3A, 0x52, 0x1C, 0xC1]),
      ]);

      final (error, packet) = await hardware.readInstantData(dataId: aData(0x00));

      expect(error, HaloErrorType.noError);
      expect(packet!.dataId.id, 0x00);
      final (value, ts) = packet.payload.getUInt(0)!;
      expect(value, 7250);
      expect(ts, aDate);
      expect(commands(), [
        [0x00, 0x00, 0x00],
        [0x01, 0x00, 0x00],
      ]);
    });

    test("gives the error of the device and stops there", () async {
      companion.answers.add(answer([0x02, 0x00, 0x0E]));

      final (error, packet) = await hardware.readInstantData(dataId: aData(0x0E));

      expect(error, HaloErrorType.protocolError);
      expect(packet, isNull);
    });
  });

  group("HaloBleInstantDataHardware.writeInstantData", () {
    test("is not implemented over BLE and writes nothing", () async {
      final error = await hardware.writeInstantData(
        packet: HaloPacket(dataId: aData(0x00), payload: HaloPayloadPacket()..addUInt16(1)),
      );

      expect(error, HaloErrorType.notImplementedYet);
      expect(companion.writes, isEmpty);
    });
  });

  group("HaloBleInstantDataHardware.subInstantData", () {
    test("subscribes, then unsubscribes, with the commands of the spec", () async {
      companion.answers.addAll([
        answer([0x00, 0x00, 0x00]),
        answer([0x00, 0x00, 0x00]),
      ]);

      expect(await hardware.subInstantData(dataId: aData(0x00)), HaloErrorType.noError);
      expect(await hardware.unSubInstantData(dataId: aData(0x00)), HaloErrorType.noError);
      expect(commands(), [
        [0x04, 0x00, 0x00],
        [0x05, 0x00, 0x00],
      ]);
    });
  });

  group("HaloBleInstantDataHardware.instDataNewValueStream", () {
    /// Tells the hardware that the device notified the [flags] on D and returns the packets the
    /// hardware gave out for it, [count] of them.
    Future<List<HaloPacket>> notified(List<int> flags, int count) async {
      final received = hardware.instDataNewValueStream.take(count).toList();
      notificationsOfD.add(flags);

      return received.timeout(const Duration(seconds: 2));
    }

    test("reads the load 0x00 of the flags 01 00 of the spec", () async {
      companion.answers.addAll(readAnswers(0x00, 7250));

      final packets = await notified([0x01, 0x00], 1);

      expect(packets.single.dataId.id, 0x00);
      expect(packets.single.payload.getUInt(0), (7250, aDate));
      expect(commands(), [
        [0x00, 0x00, 0x00],
        [0x01, 0x00, 0x00],
      ]);
    });

    test("goes on with the next flag when a read throws, and keeps listening", () async {
      companion.throwOnNextWait = true;
      companion.answers.addAll([
        ...readAnswers(0x01, 1),
        ...readAnswers(0x02, 2),
        ...readAnswers(0x02, 3),
      ]);

      final first = await notified([0x07, 0x00], 2);
      final second = await notified([0x04, 0x00], 1);

      expect(first.map((packet) => packet.dataId.id), [0x01, 0x02]);
      expect(second.single.dataId.id, 0x02);
    });
  });
}
