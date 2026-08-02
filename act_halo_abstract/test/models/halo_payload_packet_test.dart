// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_foundation/act_foundation.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// The byte which closes a packet.
const _endByte = 0xC1;

void main() {
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
  });

  group("HaloPayloadPacket", () {
    test("carries no element when it is built", () {
      expect(HaloPayloadPacket().elementsNb, 0);
    });

    test("counts the elements which have been added to it", () {
      final packet = HaloPayloadPacket()
        ..addString("a")
        ..addBoolean(true);

      expect(packet.elementsNb, 2);
    });
  });

  group("HaloPayloadPacket.fromDevice", () {
    test("reads the elements of a packet received in one part", () {
      final sent = HaloPayloadPacket()
        ..addString("a")
        ..addString("b");

      final received = HaloPayloadPacket.fromDevice(sent.getDataToSend());

      expect(received?.elementsNb, 2);
    });

    test("joins the parts of a packet received in several ones", () {
      final sent = HaloPayloadPacket()..addString("a longer value");

      final received = HaloPayloadPacket.fromDevice(sent.getDataToSend(maxPacketSize: 4));

      expect(received?.getString(0), ("a longer value", null));
    });

    test("returns null when the parts do not make a whole packet", () {
      expect(HaloPayloadPacket.fromDevice([Uint8List.fromList([0x01])]), isNull);
    });

    test("warns about the packet it refuses", () {
      HaloPayloadPacket.fromDevice([Uint8List.fromList([0x01])]);

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 2);
    });
  });

  group("HaloPayloadPacket.getDataToSend", () {
    test("returns nothing for a packet which carries no element", () {
      expect(HaloPayloadPacket().getDataToSend(), isEmpty);
    });

    test("returns a single part when no maximum size is given", () {
      final packet = HaloPayloadPacket()..addString("a longer value");

      expect(packet.getDataToSend().length, 1);
    });

    test("cuts the packet in parts of the maximum size", () {
      final packet = HaloPayloadPacket()..addString("a longer value");

      expect(packet.getDataToSend(maxPacketSize: 4).first.length, 4);
    });
  });

  group("HaloPayloadPacket.addString", () {
    test("adds one element", () {
      final packet = HaloPayloadPacket()..addString("hello");

      expect(packet.elementsNb, 1);
    });

    test("keeps the string it was given", () {
      final packet = HaloPayloadPacket()..addString("hello");

      expect(packet.getString(0), ("hello", null));
    });

    test("keeps the timestamp it was given", () {
      final ts = DateTime.utc(2024, 5, 17, 10, 30);

      final packet = HaloPayloadPacket()..addString("hello", ts: ts);

      expect(packet.getString(0), ("hello", ts));
    });
  });

  group("HaloPayloadPacket.addStringList", () {
    test("adds one element per value", () {
      final packet = HaloPayloadPacket()..addStringList(["a", "b", "c"]);

      expect(packet.elementsNb, 3);
    });

    test("attaches the timestamp to the first value only", () {
      final ts = DateTime.utc(2024, 5, 17, 10, 30);

      final packet = HaloPayloadPacket()..addStringList(["a", "b"], ts: ts);

      expect(packet.getString(0), ("a", ts));
      expect(packet.getString(1), ("b", null));
    });

    test("adds nothing for an empty list", () {
      final packet = HaloPayloadPacket()..addStringList([]);

      expect(packet.elementsNb, 0);
    });
  });

  group("HaloPayloadPacket.getString", () {
    test("returns the string at the index given", () {
      final packet = HaloPayloadPacket()..addStringList(["a", "b"]);

      expect(packet.getString(1), ("b", null));
    });

    test("returns null when the index overflows the elements of the packet", () {
      final packet = HaloPayloadPacket()..addString("a");

      expect(packet.getString(1), isNull);
    });

    test("warns about the index which overflows", () {
      HaloPayloadPacket().getString(0);

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });
  });

  group("HaloPayloadPacket.getListString", () {
    test("returns every value from the index given", () {
      final packet = HaloPayloadPacket()..addStringList(["a", "b", "c"]);

      expect(packet.getListString(1)?.$1, ["b", "c"]);
    });

    test("returns the number of values asked for", () {
      final packet = HaloPayloadPacket()..addStringList(["a", "b", "c"]);

      expect(packet.getListString(0, 2)?.$1, ["a", "b"]);
    });

    test("returns the timestamp of the first value it reads", () {
      final ts = DateTime.utc(2024, 5, 17, 10, 30);
      final packet = HaloPayloadPacket()..addStringList(["a", "b"], ts: ts);

      expect(packet.getListString(0)?.$2, ts);
    });

    test("returns an empty list when the index is the one after the last element", () {
      final packet = HaloPayloadPacket()..addString("a");

      expect(packet.getListString(1)?.$1, isEmpty);
    });

    test("returns null when the index overflows the elements of the packet", () {
      final packet = HaloPayloadPacket()..addString("a");

      expect(packet.getListString(2), isNull);
    });

    test("returns null when the number of values asked for overflows the packet", () {
      final packet = HaloPayloadPacket()..addStringList(["a", "b"]);

      expect(packet.getListString(1, 2), isNull);
    });
  });

  group("HaloPayloadPacket.addBoolean", () {
    test("keeps the value it was given", () {
      final packet = HaloPayloadPacket()..addBoolean(true);

      expect(packet.getBoolean(0), (true, null));
    });

    test("keeps the timestamp it was given", () {
      final ts = DateTime.utc(2024, 5, 17, 10, 30);

      final packet = HaloPayloadPacket()..addBoolean(false, ts: ts);

      expect(packet.getBoolean(0), (false, ts));
    });
  });

  group("HaloPayloadPacket.addBooleanList", () {
    test("adds one element per value", () {
      final packet = HaloPayloadPacket()..addBooleanList([true, false, true]);

      expect(packet.elementsNb, 3);
    });

    test("attaches the timestamp to the first value only", () {
      final ts = DateTime.utc(2024, 5, 17, 10, 30);

      final packet = HaloPayloadPacket()..addBooleanList([true, false], ts: ts);

      expect(packet.getBoolean(0), (true, ts));
      expect(packet.getBoolean(1), (false, null));
    });
  });

  group("HaloPayloadPacket.getBoolean", () {
    test("returns null when the index overflows the elements of the packet", () {
      expect(HaloPayloadPacket().getBoolean(0), isNull);
    });
  });

  group("HaloPayloadPacket.addUInt8", () {
    test("accepts a number which fits in a byte", () {
      final packet = HaloPayloadPacket();

      expect(packet.addUInt8(0xFF), isTrue);
      expect(packet.getUInt(0), (0xFF, null));
    });

    test("refuses a number which overflows a byte", () {
      final packet = HaloPayloadPacket();

      expect(packet.addUInt8(0x100), isFalse);
    });

    test("adds no element when it refuses the number", () {
      final packet = HaloPayloadPacket()..addUInt8(0x100);

      expect(packet.elementsNb, 0);
    });
  });

  group("HaloPayloadPacket.addUInt16", () {
    test("accepts a number which fits in two bytes", () {
      final packet = HaloPayloadPacket();

      expect(packet.addUInt16(0xFFFF), isTrue);
      expect(packet.getUInt(0), (0xFFFF, null));
    });

    test("refuses a number which overflows two bytes", () {
      expect(HaloPayloadPacket().addUInt16(0x10000), isFalse);
    });
  });

  group("HaloPayloadPacket.addUInt32", () {
    test("accepts a number which fits in four bytes", () {
      final packet = HaloPayloadPacket();

      expect(packet.addUInt32(0xFFFFFFFF), isTrue);
      expect(packet.getUInt(0), (0xFFFFFFFF, null));
    });

    test("refuses a number which overflows four bytes", () {
      expect(HaloPayloadPacket().addUInt32(0x100000000), isFalse);
    });
  });

  group("HaloPayloadPacket.addInt8", () {
    test("accepts a negative number which fits in a byte", () {
      final packet = HaloPayloadPacket();

      expect(packet.addInt8(-128), isTrue);
      expect(packet.getInt(0), (-128, null));
    });

    test("refuses a number which overflows a signed byte", () {
      expect(HaloPayloadPacket().addInt8(128), isFalse);
    });
  });

  group("HaloPayloadPacket.addInt16", () {
    test("accepts a negative number which fits in two bytes", () {
      final packet = HaloPayloadPacket();

      expect(packet.addInt16(-32768), isTrue);
      expect(packet.getInt(0), (-32768, null));
    });

    test("refuses a number which overflows a signed short", () {
      expect(HaloPayloadPacket().addInt16(32768), isFalse);
    });
  });

  group("HaloPayloadPacket.addInt32", () {
    test("accepts a negative number which fits in four bytes", () {
      final packet = HaloPayloadPacket();

      expect(packet.addInt32(-2147483648), isTrue);
      expect(packet.getInt(0), (-2147483648, null));
    });

    test("refuses a number which overflows a signed integer of 32 bits", () {
      expect(HaloPayloadPacket().addInt32(2147483648), isFalse);
    });
  });

  group("HaloPayloadPacket.addDoubleViaInt8", () {
    test("sends the number multiplied by the power of ten of the coefficient", () {
      final packet = HaloPayloadPacket();

      expect(packet.addDoubleViaInt8(2.5, 1), isTrue);
      expect(packet.getInt(0), (25, null));
    });

    test("refuses a number which overflows a signed byte once multiplied", () {
      expect(HaloPayloadPacket().addDoubleViaInt8(2.5, 3), isFalse);
    });
  });

  group("HaloPayloadPacket.addDoubleViaInt16", () {
    test("sends the number multiplied by the power of ten of the coefficient", () {
      final packet = HaloPayloadPacket();

      expect(packet.addDoubleViaInt16(-2.5, 2), isTrue);
      expect(packet.getInt(0), (-250, null));
    });
  });

  group("HaloPayloadPacket.addDoubleViaInt32", () {
    test("sends the number multiplied by the power of ten of the coefficient", () {
      final packet = HaloPayloadPacket();

      expect(packet.addDoubleViaInt32(2.5, 4), isTrue);
      expect(packet.getInt(0), (25000, null));
    });
  });

  group("HaloPayloadPacket.addDoubleViaUInt8", () {
    test("sends the number multiplied by the power of ten of the coefficient", () {
      final packet = HaloPayloadPacket();

      expect(packet.addDoubleViaUInt8(2.5, 1), isTrue);
      expect(packet.getUInt(0), (25, null));
    });

    test("refuses a negative number", () {
      expect(HaloPayloadPacket().addDoubleViaUInt8(-2.5, 1), isFalse);
    });
  });

  group("HaloPayloadPacket.addDoubleViaUInt16", () {
    test("sends the number multiplied by the power of ten of the coefficient", () {
      final packet = HaloPayloadPacket();

      expect(packet.addDoubleViaUInt16(2.5, 2), isTrue);
      expect(packet.getUInt(0), (250, null));
    });
  });

  group("HaloPayloadPacket.addDoubleViaUInt32", () {
    test("sends the number multiplied by the power of ten of the coefficient", () {
      final packet = HaloPayloadPacket();

      expect(packet.addDoubleViaUInt32(2.5, 4), isTrue);
      expect(packet.getUInt(0), (25000, null));
    });
  });

  group("HaloPayloadPacket.getNumber", () {
    test("returns null when the index overflows the elements of the packet", () {
      expect(HaloPayloadPacket().getNumber(0, isSigned: false), isNull);
    });

    test("reads a negative number as a large unsigned one when asked to", () {
      final packet = HaloPayloadPacket()..addInt8(-1);

      expect(packet.getUInt(0), (0xFF, null));
    });
  });

  group("HaloPayloadPacket.isLastElementPacket", () {
    test("returns true for a part which ends on the end byte", () {
      expect(
        HaloPayloadPacket.isLastElementPacket(Uint8List.fromList([0x01, _endByte])),
        isTrue,
      );
    });

    test("returns false for a part which does not carry the end byte", () {
      expect(HaloPayloadPacket.isLastElementPacket(Uint8List.fromList([0x01])), isFalse);
    });
  });

  group("HaloPayloadPacket.tryToCleanLastElementPacket", () {
    test("removes the padding which follows the end byte", () {
      expect(
        HaloPayloadPacket.tryToCleanLastElementPacket(
          Uint8List.fromList([0x01, _endByte, 0x00]),
        ),
        Uint8List.fromList([0x01, _endByte]),
      );
    });

    test("returns null when the bytes which follow the end byte are not padding", () {
      expect(
        HaloPayloadPacket.tryToCleanLastElementPacket(
          Uint8List.fromList([0x01, _endByte, 0x02]),
        ),
        isNull,
      );
    });
  });

  group("HaloPayloadPacket", () {
    test("carries every kind of value it accepts through a whole exchange", () {
      final ts = DateTime.utc(2024, 5, 17, 10, 30);
      final sent = HaloPayloadPacket()
        ..addString("hello", ts: ts)
        ..addBoolean(true)
        ..addUInt16(0xC0C1)
        ..addInt32(-42);

      final received = HaloPayloadPacket.fromDevice(sent.getDataToSend(maxPacketSize: 3))!;

      expect(received.getString(0), ("hello", ts));
      expect(received.getBoolean(1), (true, null));
      expect(received.getUInt(2), (0xC0C1, null));
      expect(received.getInt(3), (-42, null));
    });
  });
}
