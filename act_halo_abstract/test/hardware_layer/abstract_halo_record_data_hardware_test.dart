// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_hardware.dart';

/// The data an application records on its device.
enum _Data { measure }

/// The key of the recorded data.
const _recordKey = HaloRecordKey(
  dataId: HaloDataId(id: 0x30, value: _Data.measure),
  uniqueIndex: 0x01,
);

void main() {
  late FakeRecordDataHardware hardware;

  setUp(() => hardware = FakeRecordDataHardware());

  group("AbstractHaloRecordDataHardware.recordDataNewValueStream", () {
    test("pushes the records the device sends", () async {
      final packet = HaloRecordPacket(recordKey: _recordKey, payload: HaloPayloadPacket());
      final received = expectLater(hardware.recordDataNewValueStream, emits(packet));

      hardware.pushNewValue(packet);

      await received;
    });
  });

  group("AbstractHaloRecordDataHardware.recordKeysNewValueStream", () {
    test("pushes the keys the device sends", () async {
      final received = expectLater(hardware.recordKeysNewValueStream, emits(_recordKey));

      hardware.pushNewKey(_recordKey);

      await received;
    });

    test("pushes the keys on its own stream, not on the one of the records", () async {
      final records = expectLater(hardware.recordDataNewValueStream, neverEmits(anything));

      hardware.pushNewKey(_recordKey);
      await hardware.close();

      await records;
    });
  });

  group("AbstractHaloRecordDataHardware.close", () {
    test("closes the two streams of the device", () async {
      final records = expectLater(hardware.recordDataNewValueStream, emitsDone);
      final keys = expectLater(hardware.recordKeysNewValueStream, emitsDone);

      await hardware.close();

      await records;
      await keys;
    });
  });
}
