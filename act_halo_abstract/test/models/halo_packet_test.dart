// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

/// The data an application exchanges with its device.
enum _Data { temperature, pressure }

/// The id of the exchanged data.
const _dataId = HaloDataId(id: 0x10, value: _Data.temperature);

void main() {
  group("HaloPacket", () {
    test("equals another packet which carries the same data id and the same payload", () {
      final payload = HaloPayloadPacket();

      expect(
        HaloPacket(dataId: _dataId, payload: payload),
        HaloPacket(dataId: _dataId, payload: payload),
      );
    });

    test("differs from a packet which carries another data id", () {
      final payload = HaloPayloadPacket();

      expect(
        HaloPacket(dataId: _dataId, payload: payload),
        isNot(
          HaloPacket(
            dataId: const HaloDataId(id: 0x11, value: _Data.pressure),
            payload: payload,
          ),
        ),
      );
    });
  });
}
