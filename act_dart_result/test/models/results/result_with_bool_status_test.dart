// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ResultWithBoolStatus", () {
    test("is a result whose status is a boolean one", () {
      const result = ResultWithBoolStatus<int>(status: BoolResultStatus.success, value: 42);

      expect(result, isA<ResultWithStatus<BoolResultStatus, int>>());
    });

    test("stays a success when the value is null", () {
      const result = ResultWithBoolStatus<int>(status: BoolResultStatus.success);

      expect(result.isSuccess, isTrue);
      expect(result.value, isNull);
    });

    test("keeps the extra information it is given", () {
      const result = ResultWithBoolStatus<int>(
        status: BoolResultStatus.error,
        extraInfo: "the server is unreachable",
      );

      expect(result.extraInfo, "the server is unreachable");
    });
  });

  group("ResultWithBoolStatus.fromStatus", () {
    test("takes the status and the extra information of the given status", () {
      const status = BoolStatusWithExtraInfo(
        status: BoolResultStatus.error,
        extraInfo: "the server is unreachable",
      );

      final result = ResultWithBoolStatus<int>.fromStatus(statusWitExtraInfo: status);

      expect(result.status, BoolResultStatus.error);
      expect(result.extraInfo, "the server is unreachable");
      expect(result.value, isNull);
    });

    test("adds the value to the status it is built from", () {
      const status = BoolStatusWithExtraInfo(status: BoolResultStatus.success);

      final result = ResultWithBoolStatus<int>.fromStatus(statusWitExtraInfo: status, value: 42);

      expect(result.value, 42);
    });
  });
}
