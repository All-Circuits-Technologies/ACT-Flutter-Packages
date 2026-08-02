// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_hardware.dart';

/// The data an application exchanges with its device.
enum _Data { temperature }

/// Builds the packet a device sends when an attribute changes.
HaloPacket _aPacket() => HaloPacket(
  dataId: const HaloDataId(id: 0x10, value: _Data.temperature),
  payload: HaloPayloadPacket(),
);

void main() {
  late FakeAttributeHardware hardware;

  setUp(() => hardware = FakeAttributeHardware());

  group("AbstractHaloAttributeHardware.attrNewValueStream", () {
    test("pushes the values the device sends", () async {
      final packet = _aPacket();
      final received = expectLater(hardware.attrNewValueStream, emits(packet));

      hardware.pushNewValue(packet);

      await received;
    });

    test("pushes the values to every listener", () async {
      final packet = _aPacket();
      final first = expectLater(hardware.attrNewValueStream, emits(packet));
      final second = expectLater(hardware.attrNewValueStream, emits(packet));

      hardware.pushNewValue(packet);

      await first;
      await second;
    });
  });

  group("AbstractHaloAttributeHardware.close", () {
    test("closes the stream of the values of the device", () async {
      final done = expectLater(hardware.attrNewValueStream, emitsDone);

      await hardware.close();

      await done;
    });
  });
}
