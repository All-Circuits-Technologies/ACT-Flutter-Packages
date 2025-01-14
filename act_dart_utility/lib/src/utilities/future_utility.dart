// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Contains useful methods to manage specific elements with [Future]
sealed class FutureUtility {
  /// This method does the same thing as [Future.wait] method but aggregates the results of all the
  /// [Future] and returns false if at least one has returned false.
  /// Returns true if all has returned true.
  static Future<bool> waitGlobalBooleanSuccess(Iterable<Future<bool>> results) => waitGlobalResult(
        results,
        (results) {
          for (final result in results) {
            if (!result) {
              return false;
            }
          }

          return true;
        },
      );

  /// This method does the same thing as [Future.wait] method but aggregates the results of all the
  /// [Future] and returns false if at least one has returned a null value.
  /// Returns true if all has returned a value different of null.
  ///
  /// This method considers that you don't want to get the result of the [Future].
  static Future<bool> waitGlobalNotNullableSuccess(Iterable<Future<dynamic>> results) =>
      waitGlobalResult(
        results,
        (results) {
          for (final result in results) {
            if (result == null) {
              return false;
            }
          }

          return true;
        },
      );

  /// This method does the same thing as [Future.wait] method but aggregates the results of all the
  /// [Future] and returns false if at least one has returned a null value.
  /// Returns true if all has returned a value different of null.
  ///
  /// If the method returns false, the results value linked will be an empty list.
  static Future<({bool success, List<T> results})> waitForResults<T>(
          Iterable<Future<T?>> results) =>
      waitGlobalResult(
        results,
        (results) {
          for (final result in results) {
            if (result == null) {
              return (success: false, results: []);
            }
          }

          return (success: true, results: results.cast());
        },
      );

  /// This method does the same thing as [Future.wait] method but aggregates the results of all the
  /// [Future] and calls [generalizeResults] method.
  /// Returns the result of the [generalizeResults] method.
  static Future<Y> waitGlobalResult<T, Y>(
    Iterable<Future<T>> results,
    Y Function(List<T> results) generalizeResults,
  ) async {
    final tmpResults = await Future.wait(results);
    return generalizeResults(tmpResults);
  }
}
