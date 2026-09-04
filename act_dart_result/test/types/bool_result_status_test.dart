// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_result/act_dart_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("BoolResultStatus", () {
    test("says the success is a success", () {
      expect(BoolResultStatus.success.isSuccess, isTrue);
      expect(BoolResultStatus.success.isError, isFalse);
    });

    test("says the error is not a success", () {
      expect(BoolResultStatus.error.isSuccess, isFalse);
      expect(BoolResultStatus.error.isError, isTrue);
    });

    test("only allows a retry after a success", () {
      expect(BoolResultStatus.success.canBeRetried, isTrue);
      expect(BoolResultStatus.error.canBeRetried, isFalse);
    });
  });

  group("BoolResultStatus.convertBoolReturn", () {
    test("returns the success for true", () {
      expect(BoolResultStatus.convertBoolReturn(true), BoolResultStatus.success);
    });

    test("returns the error for false", () {
      expect(BoolResultStatus.convertBoolReturn(false), BoolResultStatus.error);
    });
  });

  group("BoolResultStatus.convertAsyncBoolReturn", () {
    test("returns the success when the future resolves to true", () async {
      expect(
        await BoolResultStatus.convertAsyncBoolReturn(Future.value(true)),
        BoolResultStatus.success,
      );
    });

    test("returns the error when the future resolves to false", () async {
      expect(
        await BoolResultStatus.convertAsyncBoolReturn(Future.value(false)),
        BoolResultStatus.error,
      );
    });

    test("waits for the future to resolve", () async {
      final completer = Completer<bool>();
      final future = BoolResultStatus.convertAsyncBoolReturn(completer.future);
      var resolved = false;
      unawaited(future.then((_) => resolved = true));

      await pumpEventQueue();

      expect(resolved, isFalse);

      completer.complete(true);

      expect(await future, BoolResultStatus.success);
    });

    test("forwards the error of the future", () async {
      expect(
        BoolResultStatus.convertAsyncBoolReturn(Future.error(Exception("boom"))),
        throwsException,
      );
    });
  });
}
