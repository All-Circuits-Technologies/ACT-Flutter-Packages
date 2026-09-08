// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This utility class contains useful methods to manage things in loop
sealed class LoopUtility {
  /// Requests all items in a loop, using the provided request function.
  ///
  /// This method allows to get all by multiple calls and getting the elements by part.
  ///
  /// If [request] method returns null, it means that an error occurred and so we have to stop here.
  ///
  /// At each request, we don't ask more than the [elementsLimit]
  ///
  /// We know we have retrieved all when the number of elements received are less than the
  /// [elementsLimit] asked.
  ///
  /// If [waitBetweenCalls] isn't equal to null, we wait between this duration between the requests.
  static Future<List<T>?> requestAllInMultipart<T>({
    required int offset,
    required int elementsLimit,
    required Future<List<T>?> Function(int offset, int limit) request,
    Duration? waitBetweenCalls,
  }) async {
    var elementsNbGot = 0;
    var weRequestAll = false;
    final retrievedElements = <T>[];
    while (!weRequestAll) {
      final elements = await request(
        elementsNbGot,
        elementsLimit,
      );
      if (elements == null) {
        return null;
      }

      final length = elements.length;
      weRequestAll = (length < elementsLimit);

      retrievedElements.addAll(elements);
      elementsNbGot += length;

      if (!weRequestAll && waitBetweenCalls != null) {
        // We only wait if we haven't retrieved all
        await Future.delayed(waitBetweenCalls);
      }
    }

    return retrievedElements;
  }
}
