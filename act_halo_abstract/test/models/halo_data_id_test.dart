// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

/// The data an application exchanges with its device.
enum _Data { temperature, pressure }

void main() {
  group("HaloDataId", () {
    test("equals another id which carries the same value and the same id", () {
      const id = HaloDataId(id: 0x10, value: _Data.temperature);

      expect(id, const HaloDataId(id: 0x10, value: _Data.temperature));
    });

    test("differs from an id which carries another value", () {
      const id = HaloDataId(id: 0x10, value: _Data.temperature);

      expect(id, isNot(const HaloDataId(id: 0x10, value: _Data.pressure)));
    });

    test("differs from an id which carries another id", () {
      const id = HaloDataId(id: 0x10, value: _Data.temperature);

      expect(id, isNot(const HaloDataId(id: 0x11, value: _Data.temperature)));
    });

    test("accepts the lowest and the highest id a byte can carry", () {
      expect(() => const HaloDataId(id: 0x00, value: _Data.temperature), returnsNormally);
      expect(() => const HaloDataId(id: 0xFF, value: _Data.temperature), returnsNormally);
    });

    test("refuses an id which overflows a byte", () {
      expect(
        () => HaloDataId(id: 0x100, value: _Data.temperature),
        throwsA(isA<AssertionError>()),
      );
    });

    test("refuses a negative id", () {
      expect(() => HaloDataId(id: -1, value: _Data.temperature), throwsA(isA<AssertionError>()));
    });
  });

  group("AbstractHaloDataIdHelper", () {
    test("keeps the data ids of the application", () {
      const temperature = HaloDataId(id: 0x10, value: _Data.temperature);

      final helper = _DataIdHelper({_Data.temperature: temperature});

      expect(helper.dataIds[_Data.temperature], temperature);
    });
  });
}

/// The data ids of the application under test.
class _DataIdHelper extends AbstractHaloDataIdHelper<_Data> {
  /// Class constructor
  _DataIdHelper(Map<_Data, HaloDataId<_Data>> dataIds) : super(dataIds: dataIds);
}
