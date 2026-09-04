// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:flutter_test/flutter_test.dart';

const _success = ResultWithBoolStatus<int>(status: BoolResultStatus.success, value: 42);
const _failure = ResultWithBoolStatus<int>(status: BoolResultStatus.error);

void main() {
  group("AsyncCallStatus.init", () {
    test("is neither loading nor holding a result", () {
      const status = AsyncCallStatus<ResultWithBoolStatus<int>>.init();

      expect(status.loading, isFalse);
      expect(status.result, isNull);
    });

    test("is neither a success nor an error", () {
      const status = AsyncCallStatus<ResultWithBoolStatus<int>>.init();

      expect(status.isSuccess, isFalse);
      expect(status.isError, isFalse);
    });

    test("cannot be retried", () {
      const status = AsyncCallStatus<ResultWithBoolStatus<int>>.init();

      expect(status.canBeRetried, isFalse);
    });
  });

  group("AsyncCallStatus.initLoading", () {
    test("is loading and holds no result", () {
      const status = AsyncCallStatus<ResultWithBoolStatus<int>>.initLoading();

      expect(status.loading, isTrue);
      expect(status.result, isNull);
    });
  });

  group("AsyncCallStatus", () {
    test("takes the success of its result", () {
      const status = AsyncCallStatus(loading: false, result: _success);

      expect(status.isSuccess, isTrue);
      expect(status.isError, isFalse);
    });

    test("takes the error of its result", () {
      const status = AsyncCallStatus(loading: false, result: _failure);

      expect(status.isSuccess, isFalse);
      expect(status.isError, isTrue);
    });

    test("takes the retry policy of its result", () {
      const status = AsyncCallStatus(loading: false, result: _success);

      expect(status.canBeRetried, isTrue);
    });
  });

  group("AsyncCallStatus.copyWith", () {
    test("keeps the values which are not given", () {
      const status = AsyncCallStatus(loading: true, result: _success);

      final copy = status.copyWith();

      expect(copy.loading, isTrue);
      expect(copy.result, _success);
    });

    test("replaces the loading state", () {
      const status = AsyncCallStatus(loading: true, result: _success);

      final copy = status.copyWith(loading: false);

      expect(copy.loading, isFalse);
      expect(copy.result, _success);
    });

    test("replaces the result", () {
      const status = AsyncCallStatus(loading: false, result: _success);

      final copy = status.copyWith(result: _failure);

      expect(copy.result, _failure);
    });

    test("keeps the result when no new one is given", () {
      const status = AsyncCallStatus(loading: false, result: _success);

      final copy = status.copyWith(loading: true);

      expect(copy.result, _success);
    });

    test("drops the result when it is forced without a new one", () {
      const status = AsyncCallStatus(loading: false, result: _success);

      final copy = status.copyWith(forceResultValue: true);

      expect(copy.result, isNull);
    });

    test("keeps the new result even when the drop is forced", () {
      const status = AsyncCallStatus(loading: false, result: _success);

      final copy = status.copyWith(result: _failure, forceResultValue: true);

      expect(copy.result, _failure);
    });
  });

  group("AsyncCallStatus.copyWithLoading", () {
    test("starts loading and forgets the previous result", () {
      const status = AsyncCallStatus(loading: false, result: _success);

      final copy = status.copyWithLoading();

      expect(copy.loading, isTrue);
      expect(copy.result, isNull);
    });
  });

  group("AsyncCallStatus.copyWithResult", () {
    test("stores the result and stops the loading", () {
      const status = AsyncCallStatus<ResultWithBoolStatus<int>>.initLoading();

      final copy = status.copyWithResult(result: _success);

      expect(copy.loading, isFalse);
      expect(copy.result, _success);
    });
  });

  group("AsyncCallStatus.copyWithReset", () {
    test("goes back to a state without any result and without loading", () {
      const status = AsyncCallStatus(loading: true, result: _success);

      final copy = status.copyWithReset();

      expect(copy.loading, isFalse);
      expect(copy.result, isNull);
    });

    test("can reset to a loading state", () {
      const status = AsyncCallStatus(loading: false, result: _success);

      final copy = status.copyWithReset(loading: true);

      expect(copy.loading, isTrue);
      expect(copy.result, isNull);
    });
  });

  group("AsyncCallStatus equality", () {
    test("considers two statuses with the same values as equal", () {
      const status = AsyncCallStatus(loading: false, result: _success);
      const otherStatus = AsyncCallStatus(loading: false, result: _success);

      expect(status, otherStatus);
    });

    test("considers two statuses with different loading states as different", () {
      const status = AsyncCallStatus(loading: false, result: _success);
      const otherStatus = AsyncCallStatus(loading: true, result: _success);

      expect(status, isNot(otherStatus));
    });

    test("considers two statuses with different results as different", () {
      const status = AsyncCallStatus(loading: false, result: _success);
      const otherStatus = AsyncCallStatus(loading: false, result: _failure);

      expect(status, isNot(otherStatus));
    });

    test("considers the initial state and the initial loading state as different", () {
      const status = AsyncCallStatus<ResultWithBoolStatus<int>>.init();
      const otherStatus = AsyncCallStatus<ResultWithBoolStatus<int>>.initLoading();

      expect(status, isNot(otherStatus));
    });
  });
}
