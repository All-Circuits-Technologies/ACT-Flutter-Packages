// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves [elements] by pages of at most `limit` elements, and records the calls it received.
class _PagedSource {
  final List<int> elements;
  final List<({int offset, int limit})> calls = [];

  _PagedSource(this.elements);

  Future<List<int>?> request(int offset, int limit) async {
    calls.add((offset: offset, limit: limit));
    return ListUtility.safeSublistFromLength(elements, offset, limit);
  }
}

void main() {
  group("LoopUtility.requestAllInMultipart", () {
    test("gathers the elements of every page", () async {
      final source = _PagedSource(List.generate(7, (index) => index));

      final elements = await LoopUtility.requestAllInMultipart(
        offset: 0,
        elementsLimit: 3,
        request: source.request,
      );

      expect(elements, [0, 1, 2, 3, 4, 5, 6]);
    });

    test("asks for the pages one after the other", () async {
      final source = _PagedSource(List.generate(7, (index) => index));

      await LoopUtility.requestAllInMultipart(
        offset: 0,
        elementsLimit: 3,
        request: source.request,
      );

      expect(source.calls, [
        (offset: 0, limit: 3),
        (offset: 3, limit: 3),
        (offset: 6, limit: 3),
      ]);
    });

    test("stops as soon as a page is not full", () async {
      final source = _PagedSource(List.generate(2, (index) => index));

      await LoopUtility.requestAllInMultipart(
        offset: 0,
        elementsLimit: 3,
        request: source.request,
      );

      expect(source.calls.length, 1);
    });

    test("asks once more when the last page is full", () async {
      final source = _PagedSource(List.generate(3, (index) => index));

      final elements = await LoopUtility.requestAllInMultipart(
        offset: 0,
        elementsLimit: 3,
        request: source.request,
      );

      expect(source.calls.length, 2);
      expect(elements, [0, 1, 2]);
    });

    test("returns an empty list when there is nothing to gather", () async {
      final source = _PagedSource([]);

      expect(
        await LoopUtility.requestAllInMultipart(
          offset: 0,
          elementsLimit: 3,
          request: source.request,
        ),
        isEmpty,
      );
    });

    test("returns null as soon as a request fails", () async {
      var calls = 0;

      final elements = await LoopUtility.requestAllInMultipart<int>(
        offset: 0,
        elementsLimit: 2,
        request: (offset, limit) async {
          calls++;
          return (calls == 1) ? [0, 1] : null;
        },
      );

      expect(elements, isNull);
      expect(calls, 2);
    });

    test("counts the elements it already has instead of the given offset", () async {
      final source = _PagedSource(List.generate(4, (index) => index));

      await LoopUtility.requestAllInMultipart(
        offset: 10,
        elementsLimit: 3,
        request: source.request,
      );

      expect(source.calls.first.offset, 0);
    });
  });
}
