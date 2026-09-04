// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ByteUtility limits", () {
    test("derives the minimum of a signed integer from its maximum", () {
      expect(ByteUtility.minInt8, -128);
      expect(ByteUtility.minInt16, -32768);
      expect(ByteUtility.minInt32, -2147483648);
    });

    test("keeps the 64 bits limits as big integers", () {
      expect(ByteUtility.maxInt64, BigInt.parse("9223372036854775807"));
      expect(ByteUtility.minInt64, BigInt.parse("-9223372036854775808"));
    });

    test("derives the bits number from the bytes number", () {
      expect(ByteUtility.bitsNbUint8, 8);
      expect(ByteUtility.bitsNbUint16, 16);
      expect(ByteUtility.bitsNbUint32, 32);
      expect(ByteUtility.bitsNbUint64, 64);
    });
  });

  group("ByteUtility.testNumberLimits", () {
    test("accepts a number which fits in a signed integer", () {
      expect(
        ByteUtility.testNumberLimits(number: 127, bytesNb: 1, isSigned: true),
        isTrue,
      );
      expect(
        ByteUtility.testNumberLimits(number: -128, bytesNb: 1, isSigned: true),
        isTrue,
      );
    });

    test("rejects a number which overflows a signed integer", () {
      expect(
        ByteUtility.testNumberLimits(number: 128, bytesNb: 1, isSigned: true),
        isFalse,
      );
      expect(
        ByteUtility.testNumberLimits(number: -129, bytesNb: 1, isSigned: true),
        isFalse,
      );
    });

    test("accepts a number which fits in an unsigned integer", () {
      expect(
        ByteUtility.testNumberLimits(number: 255, bytesNb: 1, isSigned: false),
        isTrue,
      );
    });

    test("rejects a negative number for an unsigned integer", () {
      expect(
        ByteUtility.testNumberLimits(number: -1, bytesNb: 1, isSigned: false),
        isFalse,
      );
    });

    test("rejects a bytes number which makes no sense", () {
      expect(
        ByteUtility.testNumberLimits(number: 0, bytesNb: 0, isSigned: true),
        isFalse,
      );
      expect(
        ByteUtility.testNumberLimits(number: 0, bytesNb: 9, isSigned: true),
        isFalse,
      );
    });

    test("accepts any number in a signed integer of 64 bits", () {
      expect(
        ByteUtility.testNumberLimits(number: -1, bytesNb: 8, isSigned: true),
        isTrue,
      );
    });

    test("rejects an unsigned integer of 64 bits, which a Dart integer cannot hold", () {
      expect(
        ByteUtility.testNumberLimits(number: 1, bytesNb: 8, isSigned: false),
        isFalse,
      );
    });
  });

  group("ByteUtility.unsafeGetByte", () {
    test("returns the byte at the given index", () {
      expect(ByteUtility.unsafeGetByte(0x1234, 0), 0x34);
      expect(ByteUtility.unsafeGetByte(0x1234, 1), 0x12);
    });

    test("returns zero above the bytes of the number", () {
      expect(ByteUtility.unsafeGetByte(0x1234, 3), 0);
    });
  });

  group("ByteUtility.convertToLsbFirst", () {
    test("returns the bytes with the least significant one first", () {
      expect(
        ByteUtility.convertToLsbFirst(number: 0x1234, bytesNb: 2),
        Uint8List.fromList([0x34, 0x12]),
      );
    });

    test("pads with zeros when the number is smaller than the asked size", () {
      expect(
        ByteUtility.convertToLsbFirst(number: 1, bytesNb: 4),
        Uint8List.fromList([1, 0, 0, 0]),
      );
    });

    test("returns null when the number does not fit in the asked size", () {
      expect(ByteUtility.convertToLsbFirst(number: 256, bytesNb: 1), isNull);
    });

    test("returns null when the number is negative and the size is unsigned", () {
      expect(ByteUtility.convertToLsbFirst(number: -1, bytesNb: 1, isSigned: false), isNull);
    });
  });

  group("ByteUtility.convertToMsbFirst", () {
    test("returns the bytes with the most significant one first", () {
      expect(
        ByteUtility.convertToMsbFirst(number: 0x1234, bytesNb: 2),
        Uint8List.fromList([0x12, 0x34]),
      );
    });

    test("returns the reverse of the LSB first conversion", () {
      final lsb = ByteUtility.convertToLsbFirst(number: 0x123456, bytesNb: 4)!;
      final msb = ByteUtility.convertToMsbFirst(number: 0x123456, bytesNb: 4)!;

      expect(msb, lsb.reversed.toList());
    });

    test("returns null when the number does not fit in the asked size", () {
      expect(ByteUtility.convertToMsbFirst(number: 256, bytesNb: 1), isNull);
    });
  });

  group("ByteUtility.convertFromLsb", () {
    test("rebuilds a number from its bytes", () {
      expect(
        ByteUtility.convertFromLsb(lsbNumber: Uint8List.fromList([0x34, 0x12])),
        0x1234,
      );
    });

    test("reads the sign of a signed number", () {
      expect(ByteUtility.convertFromLsb(lsbNumber: Uint8List.fromList([0xFF])), -1);
    });

    test("ignores the sign when the number is unsigned", () {
      expect(
        ByteUtility.convertFromLsb(lsbNumber: Uint8List.fromList([0xFF]), isSigned: false),
        255,
      );
    });

    test("returns null when the bytes number is not a supported one", () {
      expect(
        ByteUtility.convertFromLsb(lsbNumber: Uint8List.fromList([1, 2, 3])),
        isNull,
      );
    });

    test("returns null for an unsigned number of eight bytes", () {
      expect(
        ByteUtility.convertFromLsb(
          lsbNumber: Uint8List.fromList([1, 0, 0, 0, 0, 0, 0, 0]),
          isSigned: false,
        ),
        isNull,
      );
    });

    test("undoes the conversion to bytes", () {
      final bytes = ByteUtility.convertToLsbFirst(number: -1234, bytesNb: 4)!;

      expect(ByteUtility.convertFromLsb(lsbNumber: bytes), -1234);
    });
  });

  group("ByteUtility.convertFromMsb", () {
    test("rebuilds a number from its bytes", () {
      expect(
        ByteUtility.convertFromMsb(msbNumber: Uint8List.fromList([0x12, 0x34])),
        0x1234,
      );
    });

    test("returns null when the bytes number is not a supported one", () {
      expect(
        ByteUtility.convertFromMsb(msbNumber: Uint8List.fromList([1, 2, 3])),
        isNull,
      );
    });

    test("warns through the logger when the bytes cannot be converted", () {
      final logger = FakeLogger();

      ByteUtility.convertFromMsb(msbNumber: Uint8List.fromList([1, 2, 3]), logger: logger);

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("undoes the conversion to bytes", () {
      final bytes = ByteUtility.convertToMsbFirst(number: -1234, bytesNb: 4)!;

      expect(ByteUtility.convertFromMsb(msbNumber: bytes), -1234);
    });
  });

  group("ByteUtility.safeConvertList", () {
    test("returns the bytes of a list which holds only bytes", () {
      final logger = FakeLogger();

      expect(
        ByteUtility.safeConvertList([0, 128, 255], logger: logger),
        Uint8List.fromList([0, 128, 255]),
      );
    });

    test("returns null when a value overflows a byte", () {
      final logger = FakeLogger();

      expect(ByteUtility.safeConvertList([256], logger: logger), isNull);
    });

    test("returns null when a value is negative", () {
      final logger = FakeLogger();

      expect(ByteUtility.safeConvertList([-1], logger: logger), isNull);
    });

    test("warns through the logger when a value overflows a byte", () {
      final logger = FakeLogger();

      ByteUtility.safeConvertList([256], logger: logger);

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });
  });

  group("ByteUtility.toHex", () {
    test("writes two digits per byte", () {
      expect(ByteUtility.toHex(Uint8List.fromList([0x0A, 0xFF])), "0aff");
    });

    test("returns an empty string for an empty list", () {
      expect(ByteUtility.toHex(Uint8List(0)), "");
    });
  });

  group("ByteUtility.fromUint16ToHex", () {
    test("writes four digits per value", () {
      expect(ByteUtility.fromUint16ToHex(Uint16List.fromList([0x0A, 0xFFFF])), "000affff");
    });

    test("returns an empty string for an empty list", () {
      expect(ByteUtility.fromUint16ToHex(Uint16List(0)), "");
    });
  });
}
