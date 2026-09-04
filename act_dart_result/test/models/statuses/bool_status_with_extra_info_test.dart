// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("BoolStatusWithExtraInfo", () {
    test("is a status with extra information", () {
      const status = BoolStatusWithExtraInfo(status: BoolResultStatus.success);

      expect(status, isA<StatusWithExtraInfo<BoolResultStatus>>());
    });
  });

  group("BoolStatusWithExtraInfo.fromBoolValue", () {
    test("builds a success from true", () {
      final status = BoolStatusWithExtraInfo.fromBoolValue(boolResult: true);

      expect(status.status, BoolResultStatus.success);
      expect(status.isSuccess, isTrue);
    });

    test("builds an error from false", () {
      final status = BoolStatusWithExtraInfo.fromBoolValue(boolResult: false);

      expect(status.status, BoolResultStatus.error);
      expect(status.isError, isTrue);
    });

    test("keeps the extra information it is given", () {
      final status = BoolStatusWithExtraInfo.fromBoolValue(
        boolResult: false,
        extraInfo: "the server is unreachable",
      );

      expect(status.extraInfo, "the server is unreachable");
    });

    test("has no extra information when none is given", () {
      final status = BoolStatusWithExtraInfo.fromBoolValue(boolResult: true);

      expect(status.extraInfo, isNull);
    });
  });

  group("BoolStatusWithExtraInfo.convertAsyncBoolReturn", () {
    test("builds a success when the future resolves to true", () async {
      final status = await BoolStatusWithExtraInfo.convertAsyncBoolReturn(
        boolPromise: Future.value(true),
      );

      expect(status.status, BoolResultStatus.success);
    });

    test("builds an error when the future resolves to false", () async {
      final status = await BoolStatusWithExtraInfo.convertAsyncBoolReturn(
        boolPromise: Future.value(false),
      );

      expect(status.status, BoolResultStatus.error);
    });

    test("builds a status without any extra information", () async {
      final status = await BoolStatusWithExtraInfo.convertAsyncBoolReturn(
        boolPromise: Future.value(false),
      );

      expect(status.extraInfo, isNull);
    });

    test("forwards the error of the future", () {
      expect(
        BoolStatusWithExtraInfo.convertAsyncBoolReturn(boolPromise: Future.error(Exception("boom"))),
        throwsException,
      );
    });
  });
}
