// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_provider.dart';

/// Sorts the elements of the sources from the smallest to the biggest.
int _ascending(int first, int second) => first.compareTo(second);

void main() {
  late FakeProvider even;
  late FakeProvider odd;

  setUp(() {
    FakeGlobalManager.install();
    even = FakeProvider([0, 2, 4, 6, 8]);
    odd = FakeProvider([1, 3, 5, 7, 9]);
  });

  /// A companion which reads from the two providers of the test.
  ElementLoadersCompanion<int> aCompanion({List<bool Function(int model)> filters = const []}) =>
      ElementLoadersCompanion<int>(
        ElementLoaderConfig<int>(
          callbacks: [even.load, odd.load],
          sortItems: _ascending,
          extraAppFilters: filters,
        ),
      );

  group("ElementLoadersCompanion.load", () {
    test("merges what the sources answered, in the order the config sorts them", () async {
      final companion = aCompanion();

      expect(await companion.load(offset: 0, limit: 4), [0, 1, 2, 3]);
    });

    test("asks each source from where the elements it answered were used", () async {
      final companion = aCompanion();
      await companion.load(offset: 0, limit: 4);

      expect(await companion.load(offset: 4, limit: 4), [4, 5, 6, 7]);
    });

    test("gives back what is left when the sources have nothing more", () async {
      final companion = aCompanion();
      await companion.load(offset: 0, limit: 4);
      await companion.load(offset: 4, limit: 4);

      expect(await companion.load(offset: 8, limit: 4), [8, 9]);
      expect(companion.isAllLoaded, isTrue);
    });

    test("gives back the elements it already has without asking the sources again", () async {
      final companion = aCompanion();
      await companion.load(offset: 0, limit: 4);
      final callsNb = even.calls.length;

      expect(await companion.load(offset: 0, limit: 4), [0, 1, 2, 3]);
      expect(even.calls.length, callsNb);
    });

    test("keeps only the elements the filters of the config accept", () async {
      final companion = aCompanion(filters: [(model) => model.isEven]);

      expect(await companion.load(offset: 0, limit: 4), [0, 2, 4, 6]);
    });

    test("asks a source again until it has enough elements the filters accept", () async {
      final companion = aCompanion(filters: [(model) => model.isEven]);

      await companion.load(offset: 0, limit: 4);

      expect(odd.calls.length, greaterThan(1));
    });

    test("gives back nothing when a source failed", () async {
      final companion = aCompanion();
      odd.fails = true;

      expect(await companion.load(offset: 0, limit: 4), isNull);
    });

    test("answers two calls which are made at the same time one after the other", () async {
      final companion = aCompanion();

      final pages = await Future.wait([
        companion.load(offset: 0, limit: 4),
        companion.load(offset: 4, limit: 4),
      ]);

      expect(pages, [
        [0, 1, 2, 3],
        [4, 5, 6, 7],
      ]);
    });
  });

  group("ElementLoadersCompanion.clearLoadedElements", () {
    test("forgets what it read, and reads it again from the sources", () async {
      final companion = aCompanion();
      await companion.load(offset: 0, limit: 4);

      await companion.clearLoadedElements();

      expect(companion.loadedElements, isEmpty);
      expect(await companion.load(offset: 0, limit: 4), [0, 1, 2, 3]);
      expect(even.calls.length, 2);
    });
  });

  group("ElementLoadersCompanion.updatedElement", () {
    test("replaces the element it has and the one the source it comes from has", () async {
      final companion = aCompanion();
      await companion.load(offset: 0, limit: 4);

      companion.updatedElement((item) => item == 2, (current) => current * 10);

      expect(companion.loadedElements, [0, 1, 20, 3]);
    });
  });

  group("ElementLoadersCompanion.deletedElement", () {
    test("forgets the element which is found", () async {
      final companion = aCompanion();
      await companion.load(offset: 0, limit: 4);

      expect(companion.deletedElement((item) => item == 2), isTrue);
      expect(companion.loadedElements, [0, 1, 3]);
    });

    test("says that it deleted nothing when no element is found", () async {
      final companion = aCompanion();
      await companion.load(offset: 0, limit: 4);

      expect(companion.deletedElement((item) => item == 20), isFalse);
    });

    test("goes on where it stopped once an element was deleted", () async {
      final companion = aCompanion();
      await companion.load(offset: 0, limit: 4);
      companion.deletedElement((item) => item == 2);

      expect(await companion.load(offset: 3, limit: 2), [4, 5]);
    });
  });
}
