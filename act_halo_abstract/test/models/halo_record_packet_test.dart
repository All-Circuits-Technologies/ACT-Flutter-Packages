// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

/// The data an application records on its device.
enum _Data { measure }

/// The key of the recorded data.
const _recordKey = HaloRecordKey(
  dataId: HaloDataId(id: 0x10, value: _Data.measure),
  uniqueIndex: 0x05,
);

void main() {
  group("HaloRecordPacket", () {
    test("equals another packet which carries the same key and the same payload", () {
      final payload = HaloPayloadPacket();

      expect(
        HaloRecordPacket(recordKey: _recordKey, payload: payload),
        HaloRecordPacket(recordKey: _recordKey, payload: payload),
      );
    });

    test("differs from a packet which carries another key", () {
      final payload = HaloPayloadPacket();

      expect(
        HaloRecordPacket(recordKey: _recordKey, payload: payload),
        isNot(
          HaloRecordPacket(
            recordKey: const HaloRecordKey(
              dataId: HaloDataId(id: 0x10, value: _Data.measure),
              uniqueIndex: 0x06,
            ),
            payload: payload,
          ),
        ),
      );
    });
  });
}
