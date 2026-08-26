// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HaloCmdId", () {
    test("gives the same raw value to the read and to the pull commands", () {
      expect(HaloCmdId.read.rawValue, HaloCmdId.pull.rawValue);
    });

    test("gives the same raw value to the write, push and call commands", () {
      expect(HaloCmdId.write.rawValue, HaloCmdId.push.rawValue);
      expect(HaloCmdId.write.rawValue, HaloCmdId.call.rawValue);
    });
  });

  group("HaloCmdId.parseValue", () {
    test("returns the read command by default for the raw value it shares with the pull", () {
      expect(HaloCmdId.parseValue(HaloCmdId.read.rawValue), HaloCmdId.read);
    });

    test("returns the pull command when the exchange is not a read or a write", () {
      expect(
        HaloCmdId.parseValue(HaloCmdId.pull.rawValue, isParsingReadWrite: false),
        HaloCmdId.pull,
      );
    });

    test("returns the write command by default for the raw value it shares", () {
      expect(HaloCmdId.parseValue(HaloCmdId.write.rawValue), HaloCmdId.write);
    });

    test("returns the call command when the exchange is a request", () {
      expect(
        HaloCmdId.parseValue(
          HaloCmdId.call.rawValue,
          isParsingReadWrite: false,
          isParsingRequest: true,
        ),
        HaloCmdId.call,
      );
    });

    test("returns the push command when the exchange is neither a write nor a request", () {
      expect(
        HaloCmdId.parseValue(HaloCmdId.push.rawValue, isParsingReadWrite: false),
        HaloCmdId.push,
      );
    });

    test("returns the request flag to the read and write one, which has the last word", () {
      expect(
        HaloCmdId.parseValue(HaloCmdId.write.rawValue, isParsingRequest: true),
        HaloCmdId.write,
      );
    });

    test("returns the command which carries a raw value shared by no other one", () {
      expect(HaloCmdId.parseValue(HaloCmdId.ack.rawValue), HaloCmdId.ack);
    });

    test("returns unknown when no command carries the raw value given", () {
      expect(HaloCmdId.parseValue(0x42), HaloCmdId.unknown);
    });
  });
}
