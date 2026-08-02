// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

/// The data an application records on its device.
enum _Data { measure }

/// The id of the recorded data.
const _dataId = HaloDataId(id: 0x10, value: _Data.measure);

void main() {
  group("HaloRecordKey", () {
    test("equals another key which carries the same data id and the same index", () {
      const key = HaloRecordKey(dataId: _dataId, uniqueIndex: 0x05);

      expect(key, const HaloRecordKey(dataId: _dataId, uniqueIndex: 0x05));
    });

    test("differs from a key which carries another index", () {
      const key = HaloRecordKey(dataId: _dataId, uniqueIndex: 0x05);

      expect(key, isNot(const HaloRecordKey(dataId: _dataId, uniqueIndex: 0x06)));
    });

    test("accepts the lowest and the highest index a byte can carry", () {
      expect(() => const HaloRecordKey(dataId: _dataId, uniqueIndex: 0x00), returnsNormally);
      expect(() => const HaloRecordKey(dataId: _dataId, uniqueIndex: 0xFF), returnsNormally);
    });

    test("refuses an index which overflows a byte", () {
      expect(
        () => HaloRecordKey(dataId: _dataId, uniqueIndex: 0x100),
        throwsA(isA<AssertionError>()),
      );
    });

    test("refuses a negative index", () {
      expect(
        () => HaloRecordKey(dataId: _dataId, uniqueIndex: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group("HaloRecordKey.getAll", () {
    test("carries the index which stands for every record of the data id", () {
      const key = HaloRecordKey.getAll(dataId: _dataId);

      expect(key.uniqueIndex, HaloRecordKey.getAllUniqueIndex);
    });

    test("equals the key built with the index which stands for every record", () {
      const key = HaloRecordKey.getAll(dataId: _dataId);

      expect(
        key,
        const HaloRecordKey(dataId: _dataId, uniqueIndex: HaloRecordKey.getAllUniqueIndex),
      );
    });
  });
}
