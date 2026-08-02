// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("BoolResultWithRequiredValue", () {
    test("is a result whose value is required and whose status is a boolean one", () {
      const result = BoolResultWithRequiredValue<int>(
        status: BoolResultStatus.success,
        value: 42,
      );

      expect(result, isA<ResultWithRequiredValue<BoolResultStatus, int>>());
    });

    test("is an error when the status is a success but the value is null", () {
      const result = BoolResultWithRequiredValue<int>(status: BoolResultStatus.success);

      expect(result.isError, isTrue);
    });
  });

  group("BoolResultWithRequiredValue.fromValue", () {
    test("builds a success when the value is not null", () {
      const result = BoolResultWithRequiredValue<int>.fromValue(value: 42);

      expect(result.status, BoolResultStatus.success);
      expect(result.isSuccess, isTrue);
    });

    test("builds an error when the value is null", () {
      const result = BoolResultWithRequiredValue<int>.fromValue(value: null);

      expect(result.status, BoolResultStatus.error);
      expect(result.isError, isTrue);
    });

    test("keeps the extra information it is given", () {
      const result = BoolResultWithRequiredValue<int>.fromValue(
        value: null,
        extraInfo: "the server is unreachable",
      );

      expect(result.extraInfo, "the server is unreachable");
    });
  });

  group("BoolResultWithRequiredValue.error", () {
    test("builds an error without any value", () {
      const result = BoolResultWithRequiredValue<int>.error();

      expect(result.status, BoolResultStatus.error);
      expect(result.value, isNull);
    });

    test("keeps the extra information it is given", () {
      const result = BoolResultWithRequiredValue<int>.error(extraInfo: "the value is out of range");

      expect(result.extraInfo, "the value is out of range");
    });
  });

  group("BoolResultWithRequiredValue.fromStatus", () {
    test("takes the status and the extra information of the given status", () {
      const status = BoolStatusWithExtraInfo(
        status: BoolResultStatus.error,
        extraInfo: "the server is unreachable",
      );

      final result = BoolResultWithRequiredValue<int>.fromStatus(statusWitExtraInfo: status);

      expect(result.status, BoolResultStatus.error);
      expect(result.extraInfo, "the server is unreachable");
    });

    test("adds the value to the status it is built from", () {
      const status = BoolStatusWithExtraInfo(status: BoolResultStatus.success);

      final result = BoolResultWithRequiredValue<int>.fromStatus(
        statusWitExtraInfo: status,
        value: 42,
      );

      expect(result.isSuccess, isTrue);
      expect(result.value, 42);
    });
  });

  group("BoolResultWithRequiredValue.fromFuture", () {
    test("builds a success when the future resolves to a value", () async {
      final result = await BoolResultWithRequiredValue.fromFuture(Future.value(42));

      expect(result.status, BoolResultStatus.success);
      expect(result.value, 42);
    });

    test("builds an error when the future resolves to null", () async {
      final result = await BoolResultWithRequiredValue.fromFuture(Future<int?>.value());

      expect(result.status, BoolResultStatus.error);
      expect(result.value, isNull);
    });

    test("forwards the error of the future", () {
      expect(
        BoolResultWithRequiredValue.fromFuture(Future<int?>.error(Exception("boom"))),
        throwsException,
      );
    });
  });
}
