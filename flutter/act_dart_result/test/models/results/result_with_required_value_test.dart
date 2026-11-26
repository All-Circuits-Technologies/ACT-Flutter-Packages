// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ResultWithRequiredValue.isSuccess", () {
    test("returns true when the status is a success and the value is not null", () {
      const result = ResultWithRequiredValue<BoolResultStatus, int>(
        status: BoolResultStatus.success,
        value: 42,
      );

      expect(result.isSuccess, isTrue);
    });

    test("returns false when the status is a success but the value is null", () {
      const result = ResultWithRequiredValue<BoolResultStatus, int>(
        status: BoolResultStatus.success,
      );

      expect(result.isSuccess, isFalse);
      expect(result.isError, isTrue);
    });

    test("returns false when the status is an error and the value is not null", () {
      const result = ResultWithRequiredValue<BoolResultStatus, int>(
        status: BoolResultStatus.error,
        value: 42,
      );

      expect(result.isSuccess, isFalse);
    });
  });

  group("ResultWithRequiredValue.canBeRetried", () {
    test("only depends on the status and not on the value", () {
      const result = ResultWithRequiredValue<BoolResultStatus, int>(
        status: BoolResultStatus.success,
      );

      expect(result.isSuccess, isFalse);
      expect(result.canBeRetried, isTrue);
    });
  });

  group("ResultWithRequiredValue.fromStatus", () {
    test("takes the status and the extra information of the given status", () {
      const status = BoolStatusWithExtraInfo(
        status: BoolResultStatus.error,
        extraInfo: "the server is unreachable",
      );

      final result = ResultWithRequiredValue<BoolResultStatus, int>.fromStatus(
        statusWitExtraInfo: status,
      );

      expect(result.status, BoolResultStatus.error);
      expect(result.extraInfo, "the server is unreachable");
    });

    test("stays an error when no value is added to a successful status", () {
      const status = BoolStatusWithExtraInfo(status: BoolResultStatus.success);

      final result = ResultWithRequiredValue<BoolResultStatus, int>.fromStatus(
        statusWitExtraInfo: status,
      );

      expect(result.isError, isTrue);
    });
  });
}
