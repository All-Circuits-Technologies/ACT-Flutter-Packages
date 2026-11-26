// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("StatusWithExtraInfo", () {
    test("takes the success of its status", () {
      const status = StatusWithExtraInfo(status: BoolResultStatus.success);

      expect(status.isSuccess, isTrue);
      expect(status.isError, isFalse);
    });

    test("takes the error of its status", () {
      const status = StatusWithExtraInfo(status: BoolResultStatus.error);

      expect(status.isSuccess, isFalse);
      expect(status.isError, isTrue);
    });

    test("takes the retry policy of its status", () {
      const status = StatusWithExtraInfo(status: BoolResultStatus.success);

      expect(status.canBeRetried, isTrue);
    });

    test("has no extra information when none is given", () {
      const status = StatusWithExtraInfo(status: BoolResultStatus.error);

      expect(status.extraInfo, isNull);
    });

    test("keeps the extra information it is given", () {
      const status = StatusWithExtraInfo(
        status: BoolResultStatus.error,
        extraInfo: "the server is unreachable",
      );

      expect(status.extraInfo, "the server is unreachable");
    });

    test("accepts an extra information which is not a string", () {
      final error = Exception("boom");
      final status = StatusWithExtraInfo(status: BoolResultStatus.error, extraInfo: error);

      expect(status.extraInfo, error);
    });
  });

  group("StatusWithExtraInfo equality", () {
    test("considers two statuses with the same values as equal", () {
      const status = StatusWithExtraInfo(status: BoolResultStatus.error, extraInfo: "boom");
      const otherStatus = StatusWithExtraInfo(status: BoolResultStatus.error, extraInfo: "boom");

      expect(status, otherStatus);
    });

    test("considers two statuses with different statuses as different", () {
      const status = StatusWithExtraInfo(status: BoolResultStatus.error);
      const otherStatus = StatusWithExtraInfo(status: BoolResultStatus.success);

      expect(status, isNot(otherStatus));
    });

    test("considers two statuses with different extra information as different", () {
      const status = StatusWithExtraInfo(status: BoolResultStatus.error, extraInfo: "boom");
      const otherStatus = StatusWithExtraInfo(status: BoolResultStatus.error);

      expect(status, isNot(otherStatus));
    });
  });
}
