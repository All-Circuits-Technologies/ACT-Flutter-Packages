// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("FutureUtility.waitGlobalBooleanSuccess", () {
    test("returns true when every future succeeded", () async {
      expect(
        await FutureUtility.waitGlobalBooleanSuccess([Future.value(true), Future.value(true)]),
        isTrue,
      );
    });

    test("returns false when one future failed", () async {
      expect(
        await FutureUtility.waitGlobalBooleanSuccess([Future.value(true), Future.value(false)]),
        isFalse,
      );
    });

    test("returns true when there is nothing to wait for", () async {
      expect(await FutureUtility.waitGlobalBooleanSuccess(const []), isTrue);
    });

    test("waits for every future, even after one has failed", () async {
      var completed = 0;
      Future<bool> track({required bool result}) async {
        completed++;
        return result;
      }

      await FutureUtility.waitGlobalBooleanSuccess([
        track(result: false),
        track(result: true),
      ]);

      expect(completed, 2);
    });
  });

  group("FutureUtility.waitGlobalNotNullableSuccess", () {
    test("returns true when every future returned a value", () async {
      expect(
        await FutureUtility.waitGlobalNotNullableSuccess([Future.value(1), Future.value("a")]),
        isTrue,
      );
    });

    test("returns false when one future returned nothing", () async {
      expect(
        await FutureUtility.waitGlobalNotNullableSuccess([Future.value(1), Future<int?>.value()]),
        isFalse,
      );
    });

    test("returns true when there is nothing to wait for", () async {
      expect(await FutureUtility.waitGlobalNotNullableSuccess(const []), isTrue);
    });
  });

  group("FutureUtility.waitForResults", () {
    test("returns the results when every future returned a value", () async {
      final result = await FutureUtility.waitForResults([Future.value(1), Future.value(2)]);

      expect(result.success, isTrue);
      expect(result.results, [1, 2]);
    });

    test("keeps the results in the order of the futures", () async {
      final result = await FutureUtility.waitForResults([
        Future.delayed(const Duration(milliseconds: 20), () => 1),
        Future.value(2),
      ]);

      expect(result.results, [1, 2]);
    });

    test("returns no result at all when one future returned nothing", () async {
      final result = await FutureUtility.waitForResults([Future.value(1), Future<int?>.value()]);

      expect(result.success, isFalse);
      expect(result.results, isEmpty);
    });

    test("succeeds with no result when there is nothing to wait for", () async {
      final result = await FutureUtility.waitForResults(const <Future<int?>>[]);

      expect(result.success, isTrue);
      expect(result.results, isEmpty);
    });
  });

  group("FutureUtility.waitGlobalResult", () {
    test("gives every result to the aggregation function", () async {
      expect(
        await FutureUtility.waitGlobalResult(
          [Future.value(1), Future.value(2)],
          (results) => results.fold<int>(0, (sum, result) => sum + result),
        ),
        3,
      );
    });

    test("gives an empty list to the aggregation function when there is nothing to wait for", () {
      expect(
        FutureUtility.waitGlobalResult(const <Future<int>>[], (results) => results.length),
        completion(0),
      );
    });

    test("lets the error of a future reach the caller", () {
      expect(
        FutureUtility.waitGlobalResult(
          [Future<int>.error(Exception("boom"))],
          (results) => results.length,
        ),
        throwsException,
      );
    });
  });
}
