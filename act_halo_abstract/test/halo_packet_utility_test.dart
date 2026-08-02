// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_foundation/act_foundation.dart';
import 'package:act_halo_abstract/src/halo_packet_utility.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// The byte which opens a packet.
const _startByte = 0xC0;

/// The byte which closes a packet.
const _endByte = 0xC1;

/// The byte which separates two elements of a packet.
const _elementSeparator = 0x7C;

/// The byte which separates the timestamp of an element from its value.
const _tsSeparator = 0x3A;

/// The byte which marks the next one as escaped.
const _escapeElement = 0x7D;

/// The mask applied to a byte which is escaped.
const _escapeMask = 0x20;

void main() {
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
  });

  group("HaloPacketUtility.formatPackets", () {
    test("wraps the elements between the start and the end bytes", () {
      final packets = HaloPacketUtility.formatPackets(
        escapedDataToSend: [Uint8List.fromList([0x01])],
      );

      expect(packets, [
        Uint8List.fromList([_startByte, 0x01, _endByte]),
      ]);
    });

    test("separates two elements", () {
      final packets = HaloPacketUtility.formatPackets(
        escapedDataToSend: [
          Uint8List.fromList([0x01]),
          Uint8List.fromList([0x02]),
        ],
      );

      expect(packets, [
        Uint8List.fromList([_startByte, 0x01, _elementSeparator, 0x02, _endByte]),
      ]);
    });

    test("returns nothing when there is no element to send", () {
      expect(HaloPacketUtility.formatPackets(escapedDataToSend: const []), isEmpty);
    });

    test("returns a single packet when no maximum size is given", () {
      final packets = HaloPacketUtility.formatPackets(
        escapedDataToSend: [Uint8List.fromList(List.filled(100, 0x01))],
      );

      expect(packets.length, 1);
    });

    test("cuts the packet in parts of the maximum size", () {
      final packets = HaloPacketUtility.formatPackets(
        escapedDataToSend: [Uint8List.fromList([0x01, 0x02, 0x03, 0x04])],
        maxPacketSize: 3,
      );

      expect(packets, [
        Uint8List.fromList([_startByte, 0x01, 0x02]),
        Uint8List.fromList([0x03, 0x04, _endByte]),
      ]);
    });

    test("leaves the last part shorter than the maximum size", () {
      final packets = HaloPacketUtility.formatPackets(
        escapedDataToSend: [Uint8List.fromList([0x01, 0x02, 0x03])],
        maxPacketSize: 2,
      );

      expect(packets.last.length, 1);
    });
  });

  group("HaloPacketUtility.extractFromPayloadPacket", () {
    test("returns the element between the start and the end bytes", () {
      final elements = HaloPacketUtility.extractFromPayloadPacket(
        Uint8List.fromList([_startByte, 0x01, _endByte]),
      );

      expect(elements, [
        Uint8List.fromList([0x01]),
      ]);
    });

    test("returns the elements the separators tell apart", () {
      final elements = HaloPacketUtility.extractFromPayloadPacket(
        Uint8List.fromList([_startByte, 0x01, _elementSeparator, 0x02, _endByte]),
      );

      expect(elements, [
        Uint8List.fromList([0x01]),
        Uint8List.fromList([0x02]),
      ]);
    });

    test("returns no element for a packet which carries none", () {
      final elements = HaloPacketUtility.extractFromPayloadPacket(
        Uint8List.fromList([_startByte, _endByte]),
      );

      expect(elements, isEmpty);
    });

    test("returns null for an empty packet", () {
      expect(HaloPacketUtility.extractFromPayloadPacket(Uint8List(0)), isNull);
    });

    test("returns null for a packet which does not start with the start byte", () {
      expect(
        HaloPacketUtility.extractFromPayloadPacket(Uint8List.fromList([0x01, _endByte])),
        isNull,
      );
    });

    test("returns null for a packet which does not end with the end byte", () {
      expect(
        HaloPacketUtility.extractFromPayloadPacket(Uint8List.fromList([_startByte, 0x01])),
        isNull,
      );
    });

    test("warns about the packet it refuses", () {
      HaloPacketUtility.extractFromPayloadPacket(Uint8List(0));

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });
  });

  group("HaloPacketUtility.formatString", () {
    test("returns the characters of the string", () {
      expect(HaloPacketUtility.formatString("AB"), Uint8List.fromList([0x41, 0x42]));
    });

    test("escapes a character which could be read as a byte of the protocol", () {
      // The vertical bar is the byte which separates two elements
      expect(
        HaloPacketUtility.formatString("|"),
        Uint8List.fromList([_escapeElement, _elementSeparator ^ _escapeMask]),
      );
    });

    test("prepends the timestamp and its separator when one is given", () {
      final element = HaloPacketUtility.formatString("A", ts: DateTime.utc(2024));

      expect(element.length, 6);
      expect(element[4], _tsSeparator);
      expect(element.last, 0x41);
    });
  });

  group("HaloPacketUtility.getString", () {
    test("returns the string the element carries", () {
      final element = HaloPacketUtility.formatString("hello");

      expect(HaloPacketUtility.getString(element), ("hello", null));
    });

    test("returns the string of an element which carries escaped characters", () {
      final element = HaloPacketUtility.formatString("a|b");

      expect(HaloPacketUtility.getString(element), ("a|b", null));
    });

    test("returns the timestamp the element carries", () {
      final ts = DateTime.utc(2024, 5, 17, 10, 30);
      final element = HaloPacketUtility.formatString("hello", ts: ts);

      expect(HaloPacketUtility.getString(element), ("hello", ts));
    });

    test("returns an empty string for an element which carries nothing", () {
      expect(HaloPacketUtility.getString(Uint8List(0)), ("", null));
    });

    test("returns null when the element ends on an escape byte", () {
      expect(HaloPacketUtility.getString(Uint8List.fromList([0x41, _escapeElement])), isNull);
    });
  });

  group("HaloPacketUtility.formatBoolean", () {
    test("returns a single byte", () {
      expect(HaloPacketUtility.formatBoolean(true).length, 1);
    });

    test("tells the two values apart", () {
      expect(
        HaloPacketUtility.formatBoolean(true),
        isNot(HaloPacketUtility.formatBoolean(false)),
      );
    });
  });

  group("HaloPacketUtility.getBoolean", () {
    test("returns true for an element which carries a true", () {
      expect(HaloPacketUtility.getBoolean(HaloPacketUtility.formatBoolean(true)), (true, null));
    });

    test("returns false for an element which carries a false", () {
      expect(HaloPacketUtility.getBoolean(HaloPacketUtility.formatBoolean(false)), (false, null));
    });

    test("returns the timestamp the element carries", () {
      final ts = DateTime.utc(2024, 5, 17, 10, 30);

      expect(HaloPacketUtility.getBoolean(HaloPacketUtility.formatBoolean(true, ts: ts)), (
        true,
        ts,
      ));
    });

    test("returns false for a byte which is neither the true nor the false value", () {
      expect(HaloPacketUtility.getBoolean(Uint8List.fromList([0x42])), (false, null));
    });

    test("returns null for an element which carries nothing", () {
      expect(HaloPacketUtility.getBoolean(Uint8List(0)), isNull);
    });

    test("warns about the element it refuses", () {
      HaloPacketUtility.getBoolean(Uint8List(0));

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });
  });

  group("HaloPacketUtility.formatUInt8", () {
    test("returns a single byte", () {
      expect(HaloPacketUtility.formatUInt8(0x42)?.length, 1);
    });

    test("returns null for a number which overflows a byte", () {
      expect(HaloPacketUtility.formatUInt8(0x100), isNull);
    });

    test("returns null for a negative number", () {
      expect(HaloPacketUtility.formatUInt8(-1), isNull);
    });

    test("warns about the number it refuses", () {
      HaloPacketUtility.formatUInt8(-1);

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });
  });

  group("HaloPacketUtility.formatUInt16", () {
    test("returns two bytes, the least significant one first", () {
      expect(HaloPacketUtility.formatUInt16(0x0102), Uint8List.fromList([0x02, 0x01]));
    });

    test("returns null for a number which overflows two bytes", () {
      expect(HaloPacketUtility.formatUInt16(0x10000), isNull);
    });
  });

  group("HaloPacketUtility.formatUInt32", () {
    test("returns four bytes, the least significant one first", () {
      expect(
        HaloPacketUtility.formatUInt32(0x01020304),
        Uint8List.fromList([0x04, 0x03, 0x02, 0x01]),
      );
    });

    test("returns null for a number which overflows four bytes", () {
      expect(HaloPacketUtility.formatUInt32(0x100000000), isNull);
    });
  });

  group("HaloPacketUtility.formatInt8", () {
    test("returns the two's complement of a negative number", () {
      expect(HaloPacketUtility.formatInt8(-1), Uint8List.fromList([0xFF]));
    });

    test("returns null for a number which overflows a signed byte", () {
      expect(HaloPacketUtility.formatInt8(128), isNull);
    });
  });

  group("HaloPacketUtility.formatInt16", () {
    test("returns null for a number which overflows a signed short", () {
      expect(HaloPacketUtility.formatInt16(32768), isNull);
    });
  });

  group("HaloPacketUtility.formatInt32", () {
    test("returns null for a number which overflows a signed integer of 32 bits", () {
      expect(HaloPacketUtility.formatInt32(2147483648), isNull);
    });
  });

  group("HaloPacketUtility.formatInt64", () {
    test("returns eight bytes", () {
      expect(HaloPacketUtility.formatInt64(1)?.length, 8);
    });
  });

  group("HaloPacketUtility.getNumber", () {
    test("returns the unsigned number the element carries", () {
      final element = HaloPacketUtility.formatUInt16(0x0102)!;

      expect(HaloPacketUtility.getNumber(element, isSigned: false), (0x0102, null));
    });

    test("returns the signed number the element carries", () {
      final element = HaloPacketUtility.formatInt16(-2)!;

      expect(HaloPacketUtility.getNumber(element, isSigned: true), (-2, null));
    });

    test("reads a signed number as a large unsigned one when asked to", () {
      final element = HaloPacketUtility.formatInt8(-1)!;

      expect(HaloPacketUtility.getNumber(element, isSigned: false), (0xFF, null));
    });

    test("returns the number of an element whose bytes had to be escaped", () {
      final element = HaloPacketUtility.formatUInt8(_startByte)!;

      expect(HaloPacketUtility.getNumber(element, isSigned: false), (_startByte, null));
    });

    test("returns the timestamp the element carries", () {
      final ts = DateTime.utc(2024, 5, 17, 10, 30);
      final element = HaloPacketUtility.formatUInt8(0x05, ts: ts)!;

      expect(HaloPacketUtility.getNumber(element, isSigned: false), (0x05, ts));
    });

    test("returns the timestamp of an element whose timestamp had to be escaped", () {
      // The seconds of this instant hold a byte which the protocol reserves
      final ts = DateTime.fromMillisecondsSinceEpoch(_endByte * 1000, isUtc: true);
      final element = HaloPacketUtility.formatUInt8(0x05, ts: ts)!;

      expect(HaloPacketUtility.getNumber(element, isSigned: false), (0x05, ts));
    });

    test("drops the milliseconds of the timestamp, which the protocol does not carry", () {
      final element = HaloPacketUtility.formatUInt8(
        0x05,
        ts: DateTime.utc(2024, 5, 17, 10, 30, 20, 500),
      )!;

      expect(
        HaloPacketUtility.getNumber(element, isSigned: false),
        (0x05, DateTime.utc(2024, 5, 17, 10, 30, 20)),
      );
    });

    test("returns null when the element ends on an escape byte", () {
      expect(
        HaloPacketUtility.getNumber(
          Uint8List.fromList([0x41, _escapeElement]),
          isSigned: false,
        ),
        isNull,
      );
    });

    test("returns null for an element which carries more bytes than a number holds", () {
      expect(
        HaloPacketUtility.getNumber(Uint8List.fromList([0x01, 0x02, 0x03]), isSigned: false),
        isNull,
      );
    });
  });

  group("HaloPacketUtility.isLastElementPacket", () {
    test("returns true for a packet which ends on the end byte", () {
      expect(
        HaloPacketUtility.isLastElementPacket(Uint8List.fromList([0x01, _endByte])),
        isTrue,
      );
    });

    test("returns false for a packet which does not carry the end byte", () {
      expect(HaloPacketUtility.isLastElementPacket(Uint8List.fromList([0x01])), isFalse);
    });

    test("returns false for an empty packet", () {
      expect(HaloPacketUtility.isLastElementPacket(Uint8List(0)), isFalse);
    });

    test("returns null for a packet which carries the end byte in its middle", () {
      expect(
        HaloPacketUtility.isLastElementPacket(Uint8List.fromList([_endByte, 0x01])),
        isNull,
      );
    });

    test("warns about the packet whose end byte is in its middle", () {
      HaloPacketUtility.isLastElementPacket(Uint8List.fromList([_endByte, 0x01]));

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });
  });

  group("HaloPacketUtility.tryToCleanLastElementPacket", () {
    test("removes the padding which follows the end byte", () {
      expect(
        HaloPacketUtility.tryToCleanLastElementPacket(
          Uint8List.fromList([0x01, _endByte, 0x00, 0x00]),
        ),
        Uint8List.fromList([0x01, _endByte]),
      );
    });

    test("returns the packet untouched when the end byte is its last one", () {
      final packet = Uint8List.fromList([0x01, _endByte]);

      expect(HaloPacketUtility.tryToCleanLastElementPacket(packet), packet);
    });

    test("returns the packet untouched when it carries no end byte", () {
      final packet = Uint8List.fromList([0x01, 0x02]);

      expect(HaloPacketUtility.tryToCleanLastElementPacket(packet), packet);
    });

    test("returns null when the bytes which follow the end byte are not padding", () {
      expect(
        HaloPacketUtility.tryToCleanLastElementPacket(
          Uint8List.fromList([0x01, _endByte, 0x02]),
        ),
        isNull,
      );
    });

    test("warns about the padding it removes", () {
      HaloPacketUtility.tryToCleanLastElementPacket(
        Uint8List.fromList([0x01, _endByte, 0x00]),
      );

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });
  });

  group("HaloPacketUtility", () {
    test("escapes every byte which the protocol reserves", () {
      for (final reserved in [
        _startByte,
        _endByte,
        _tsSeparator,
        _elementSeparator,
        _escapeElement,
      ]) {
        expect(
          HaloPacketUtility.formatUInt8(reserved),
          Uint8List.fromList([_escapeElement, reserved ^ _escapeMask]),
          reason: "the byte ${reserved.toRadixString(16)} has to be escaped",
        );
      }
    });

    test("carries a string which holds every reserved byte through a whole exchange", () {
      final sent = String.fromCharCodes([
        _startByte,
        _endByte,
        _tsSeparator,
        _elementSeparator,
        _escapeElement,
      ]);

      final packets = HaloPacketUtility.formatPackets(
        escapedDataToSend: [HaloPacketUtility.formatString(sent)],
      );
      final elements = HaloPacketUtility.extractFromPayloadPacket(packets.single);

      expect(HaloPacketUtility.getString(elements!.single), (sent, null));
    });
  });
}
