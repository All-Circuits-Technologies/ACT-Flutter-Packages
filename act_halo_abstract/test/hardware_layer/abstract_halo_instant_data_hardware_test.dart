// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_hardware.dart';

/// The data an application exchanges with its device.
enum _Data { speed }

void main() {
  late FakeInstantDataHardware hardware;

  setUp(() => hardware = FakeInstantDataHardware());

  group("AbstractHaloInstantDataHardware.instDataNewValueStream", () {
    test("pushes the values the device sends", () async {
      final packet = HaloPacket(
        dataId: const HaloDataId(id: 0x20, value: _Data.speed),
        payload: HaloPayloadPacket(),
      );
      final received = expectLater(hardware.instDataNewValueStream, emits(packet));

      hardware.pushNewValue(packet);

      await received;
    });
  });

  group("AbstractHaloInstantDataHardware.close", () {
    test("closes the stream of the values of the device", () async {
      final done = expectLater(hardware.instDataNewValueStream, emitsDone);

      await hardware.close();

      await done;
    });
  });
}
