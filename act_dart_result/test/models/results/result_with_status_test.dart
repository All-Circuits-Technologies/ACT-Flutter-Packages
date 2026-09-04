// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ResultWithStatus", () {
    test("keeps the value it is given", () {
      const result = ResultWithStatus<BoolResultStatus, int>(
        status: BoolResultStatus.success,
        value: 42,
      );

      expect(result.value, 42);
    });

    test("has no value when none is given", () {
      const result = ResultWithStatus<BoolResultStatus, int>(status: BoolResultStatus.error);

      expect(result.value, isNull);
    });

    test("stays a success when the status is a success and the value is null", () {
      const result = ResultWithStatus<BoolResultStatus, int>(status: BoolResultStatus.success);

      expect(result.isSuccess, isTrue);
    });

    test("stays an error when the status is an error and the value is not null", () {
      const result = ResultWithStatus<BoolResultStatus, int>(
        status: BoolResultStatus.error,
        value: 42,
      );

      expect(result.isError, isTrue);
    });
  });

  group("ResultWithStatus.fromStatus", () {
    test("takes the status and the extra information of the given status", () {
      const status = BoolStatusWithExtraInfo(
        status: BoolResultStatus.error,
        extraInfo: "the server is unreachable",
      );

      final result = ResultWithStatus<BoolResultStatus, int>.fromStatus(
        statusWitExtraInfo: status,
      );

      expect(result.status, BoolResultStatus.error);
      expect(result.extraInfo, "the server is unreachable");
    });

    test("adds the value to the status it is built from", () {
      const status = BoolStatusWithExtraInfo(status: BoolResultStatus.success);

      final result = ResultWithStatus<BoolResultStatus, int>.fromStatus(
        statusWitExtraInfo: status,
        value: 42,
      );

      expect(result.value, 42);
    });
  });

  group("ResultWithStatus equality", () {
    test("considers two results with the same values as equal", () {
      const result = ResultWithStatus<BoolResultStatus, int>(
        status: BoolResultStatus.success,
        value: 42,
      );
      const otherResult = ResultWithStatus<BoolResultStatus, int>(
        status: BoolResultStatus.success,
        value: 42,
      );

      expect(result, otherResult);
    });

    test("considers two results with different values as different", () {
      const result = ResultWithStatus<BoolResultStatus, int>(
        status: BoolResultStatus.success,
        value: 42,
      );
      const otherResult = ResultWithStatus<BoolResultStatus, int>(
        status: BoolResultStatus.success,
        value: 43,
      );

      expect(result, isNot(otherResult));
    });

    test("compares the status and the extra information along with the value", () {
      const result = ResultWithStatus<BoolResultStatus, int>(
        status: BoolResultStatus.success,
        value: 42,
      );
      const otherResult = ResultWithStatus<BoolResultStatus, int>(
        status: BoolResultStatus.success,
        value: 42,
        extraInfo: "from the cache",
      );

      expect(result, isNot(otherResult));
    });
  });
}
