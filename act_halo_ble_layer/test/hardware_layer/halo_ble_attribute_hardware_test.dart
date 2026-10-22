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
import 'package:act_halo_ble_layer/src/hardware_layer/halo_ble_attribute_hardware.dart';
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
  late HaloBleAttributeHardware hardware;
  late StreamController<List<int>> notificationsOfA;

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
    hardware = HaloBleAttributeHardware(bleCompanion: companion);

    notificationsOfA = StreamController<List<int>>();
    await halo.charAAttrNotify.onStreamUpdate(notificationsOfA.stream, const Stream.empty());
  });

  tearDown(() async {
    await hardware.close();
    await notificationsOfA.close();
    FakeAssets.stop();
    await manager.disposeLifeCycle();
    await config.disposeLifeCycle();
    await lifeCycle.close();
    await globalManager.reset();
  });

  /// The attribute [id] of the device.
  HaloDataId<int> anAttribute(int id) => HaloDataId<int>(id: id, value: id);

  /// An answer of the device, made of the [bytes].
  (HaloErrorType, Uint8List?) answer(List<int> bytes) =>
      (HaloErrorType.noError, Uint8List.fromList(bytes));

  /// What the device answers when the attribute [id] is read and holds the U2 [value].
  List<(HaloErrorType, Uint8List?)> readAnswers(int id, int value) {
    final payload = HaloPayloadPacket()..addUInt16(value);

    return [
      answer([0x00, 0x01, id]),
      answer(payload.getDataToSend().single),
    ];
  }

  /// What was written into the characteristic of the commands (B).
  List<List<int>> commands() => companion.writesInto(halo.charBAttrCmd.uuid).toList();

  /// What was written into the characteristic of the exchange area (C).
  List<List<int>> exchanges() => companion.writesInto(halo.charCAttrTmp.uuid).toList();

  group("HaloBleAttributeHardware.readAttribute", () {
    test("replays the read of the attribute 0x04 of the spec", () async {
      companion.answers.addAll(readAnswers(0x04, 5000));

      final (error, packet) = await hardware.readAttribute(dataId: anAttribute(0x04));

      expect(error, HaloErrorType.noError);
      expect(packet!.dataId.id, 0x04);
      expect(packet.payload.getUInt(0)?.$1, 5000);
      expect(commands(), [
        [0x00, 0x00, 0x04],
        [0x01, 0x00, 0x04],
      ]);
      expect(exchanges(), isEmpty);
    });

    test("gives the error of the device and stops there", () async {
      companion.answers.add(answer([0x02, 0x00, 0x0E]));

      final (error, packet) = await hardware.readAttribute(dataId: anAttribute(0x0E));

      expect(error, HaloErrorType.protocolError);
      expect(packet, isNull);
      expect(commands(), [
        [0x00, 0x00, 0x0E],
      ]);
    });

    test("gives the error of the companion when nothing comes on C", () async {
      // The device answers a READ_READY with nothing to send on B, so the wait on C times out
      companion.answers.addAll([
        answer([0x00, 0x01, 0x04]),
        (HaloErrorType.genericError, null),
      ]);

      final (error, packet) = await hardware.readAttribute(dataId: anAttribute(0x04));

      expect(error, HaloErrorType.genericError);
      expect(packet, isNull);
    });

    test("rebuilds a value which the device cut in several packets", () async {
      final payload = HaloPayloadPacket()..addString("a string longer than twenty bytes");
      final packets = payload.getDataToSend(maxPacketSize: 20);
      expect(packets.length, greaterThan(1));
      companion.answers.addAll([
        answer([0x00, 0x01, 0x07]),
        for (final packet in packets) answer(packet),
      ]);

      final (error, packet) = await hardware.readAttribute(dataId: anAttribute(0x07));

      expect(error, HaloErrorType.noError);
      expect(packet!.payload.getString(0)?.$1, "a string longer than twenty bytes");
      expect(commands().where((command) => command[0] == 0x01).length, packets.length);
    });

    test("gives a format error when the result is not made of three bytes", () async {
      companion.answers.add(answer([0x00, 0x01]));

      final (error, packet) = await hardware.readAttribute(dataId: anAttribute(0x04));

      expect(error, HaloErrorType.formatError);
      expect(packet, isNull);
    });

    test("gives a format error when the result is for another attribute", () async {
      companion.answers.add(answer([0x00, 0x01, 0x05]));

      final (error, packet) = await hardware.readAttribute(dataId: anAttribute(0x04));

      expect(error, HaloErrorType.formatError);
      expect(packet, isNull);
    });

    test("gives the error of the communication", () async {
      companion.answers.add((HaloErrorType.commError, null));

      final (error, packet) = await hardware.readAttribute(dataId: anAttribute(0x04));

      expect(error, HaloErrorType.commError);
      expect(packet, isNull);
    });

    test("does not mix two reads asked at once", () async {
      companion.answers.addAll([...readAnswers(0x04, 1), ...readAnswers(0x05, 2)]);

      final results = await Future.wait([
        hardware.readAttribute(dataId: anAttribute(0x04)),
        hardware.readAttribute(dataId: anAttribute(0x05)),
      ]);

      expect(results[0].$2!.payload.getUInt(0)?.$1, 1);
      expect(results[1].$2!.payload.getUInt(0)?.$1, 2);
      expect(commands(), [
        [0x00, 0x00, 0x04],
        [0x01, 0x00, 0x04],
        [0x00, 0x00, 0x05],
        [0x01, 0x00, 0x05],
      ]);
    });
  });

  group("HaloBleAttributeHardware.writeAttribute", () {
    /// The packet which carries the U2 [value] for the attribute [id].
    HaloPacket aPacket(int id, int value) =>
        HaloPacket(dataId: anAttribute(id), payload: HaloPayloadPacket()..addUInt16(value));

    test("replays the write of 3000 in the attribute 0x04 of the spec", () async {
      companion.answers.addAll([
        answer([0x00, 0x00, 0x04]),
        answer([0x00, 0x00, 0x04]),
      ]);

      final error = await hardware.writeAttribute(packet: aPacket(0x04, 3000));

      expect(error, HaloErrorType.noError);
      expect(commands(), [
        [0x02, 0x01, 0x04],
      ]);
      expect(exchanges(), [
        [0xC0, 0xB8, 0x0B, 0xC1],
      ]);
    });

    test("gives the error of the device to a write in a read-only attribute", () async {
      companion.answers.add(answer([0x02, 0x00, 0x01]));

      final error = await hardware.writeAttribute(packet: aPacket(0x01, 1));

      expect(error, HaloErrorType.protocolError);
      expect(exchanges(), isEmpty);
    });

    test("gives the error the device answers to the last packet", () async {
      companion.answers.addAll([
        answer([0x00, 0x00, 0x04]),
        answer([0x01, 0x00, 0x04]),
      ]);

      final error = await hardware.writeAttribute(packet: aPacket(0x04, 3000));

      expect(error, HaloErrorType.formatError);
    });

    test("writes 60 bytes in packets of 20, each acknowledged", () async {
      final payload = HaloPayloadPacket()..addString("a" * 60);
      final frame = payload.getDataToSend().single;
      companion.answers.addAll([
        for (var i = 0; i < 5; ++i) answer([0x00, 0x00, 0x09]),
      ]);

      final error = await hardware.writeAttribute(
        packet: HaloPacket(dataId: anAttribute(0x09), payload: payload),
      );

      expect(error, HaloErrorType.noError);
      expect(commands(), [
        [0x02, 0x01, 0x09],
      ]);
      expect(exchanges().length, 4);
      expect(exchanges().every((packet) => packet.length <= 20), isTrue);
      expect(exchanges().expand((packet) => packet).toList(), frame);
      // The command, then one acknowledgment per packet: all of them were waited for
      expect(companion.writes.every((write) => write.waited), isTrue);
    });

    test("cuts the packets at the size of the companion", () async {
      companion.forcedPacketSize = 8;
      companion.answers.addAll([
        for (var i = 0; i < 5; ++i) answer([0x00, 0x00, 0x09]),
      ]);

      await hardware.writeAttribute(
        packet: HaloPacket(
          dataId: anAttribute(0x09),
          payload: HaloPayloadPacket()..addString("a" * 20),
        ),
      );

      expect(exchanges().map((packet) => packet.length), [8, 8, 6]);
    });

    test("stops at the first packet the device does not acknowledge", () async {
      companion.answers.addAll([
        answer([0x00, 0x00, 0x09]),
        answer([0x00, 0x00, 0x09]),
        answer([0x03, 0x00, 0x09]),
      ]);

      final error = await hardware.writeAttribute(
        packet: HaloPacket(
          dataId: anAttribute(0x09),
          payload: HaloPayloadPacket()..addString("a" * 60),
        ),
      );

      expect(error, HaloErrorType.serviceBusyError);
      expect(exchanges().length, 2);
    });

    test("refuses a packet without any value", () async {
      final error = await hardware.writeAttribute(
        packet: HaloPacket(dataId: anAttribute(0x04), payload: HaloPayloadPacket()),
      );

      expect(error, HaloErrorType.formatError);
      expect(companion.writes, isEmpty);
    });
  });

  group("HaloBleAttributeHardware.subAttribute", () {
    test("subscribes, then unsubscribes, with the commands of the spec", () async {
      companion.answers.addAll([
        answer([0x00, 0x00, 0x04]),
        answer([0x00, 0x00, 0x04]),
      ]);

      expect(await hardware.subAttribute(dataId: anAttribute(0x04)), HaloErrorType.noError);
      expect(await hardware.unSubAttribute(dataId: anAttribute(0x04)), HaloErrorType.noError);
      expect(commands(), [
        [0x04, 0x00, 0x04],
        [0x05, 0x00, 0x04],
      ]);
    });

    test("gives the error of the device", () async {
      companion.answers.add(answer([0x02, 0x00, 0x7F]));

      expect(await hardware.subAttribute(dataId: anAttribute(0x7F)), HaloErrorType.protocolError);
    });
  });

  group("HaloBleAttributeHardware.attrNewValueStream", () {
    /// Tells the hardware that the device notified the [flags] on A and returns the packets the
    /// hardware gave out for it, [count] of them.
    Future<List<HaloPacket>> notified(List<int> flags, int count) async {
      final received = hardware.attrNewValueStream.take(count).toList();
      notificationsOfA.add(flags);

      return received.timeout(const Duration(seconds: 2));
    }

    test("reads the two attributes of the flags 30 00 of the spec", () async {
      companion.answers.addAll([...readAnswers(0x04, 5000), ...readAnswers(0x05, 7)]);

      final packets = await notified([0x30, 0x00], 2);

      expect(packets.map((packet) => packet.dataId.id), [0x04, 0x05]);
      expect(packets.map((packet) => packet.payload.getUInt(0)?.$1), [5000, 7]);
      expect(commands(), [
        [0x00, 0x00, 0x04],
        [0x01, 0x00, 0x04],
        [0x00, 0x00, 0x05],
        [0x01, 0x00, 0x05],
      ]);
    });

    test("accepts flags of three bytes", () async {
      companion.answers.addAll([...readAnswers(0x04, 1), ...readAnswers(0x10, 2)]);

      final packets = await notified([0x10, 0x00, 0x01], 2);

      expect(packets.map((packet) => packet.dataId.id), [0x04, 0x10]);
    });

    test("goes on with the next flag when a read fails", () async {
      companion.answers.addAll([
        answer([0x02, 0x00, 0x04]),
        ...readAnswers(0x05, 7),
      ]);

      final packets = await notified([0x30, 0x00], 1);

      expect(packets.single.dataId.id, 0x05);
    });

    test("goes on with the next flag when a read throws, and keeps listening", () async {
      companion.throwOnNextWait = true;
      companion.answers.addAll([...readAnswers(0x05, 7), ...readAnswers(0x06, 8)]);

      final first = await notified([0x30, 0x00], 1);
      final second = await notified([0x40, 0x00], 1);

      expect(first.single.dataId.id, 0x05);
      expect(second.single.dataId.id, 0x06);
    });

    test("ignores flags which are too short to be flags", () async {
      notificationsOfA.add([0x30]);
      await pumpHalo();

      expect(companion.writes, isEmpty);
    });
  });
}
