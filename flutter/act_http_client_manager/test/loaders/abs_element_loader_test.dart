// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_provider.dart';

/// A loader which reads its elements from the provider of the test.
class _Loader extends AbsElementLoader<int> {
  /// The provider the loader reads its elements from.
  final FakeProvider provider;

  /// Class constructor
  _Loader(this.provider, {super.preventLoadingFewElements});

  /// Reads from the provider the elements which are at [offset], [limit] of them at most.
  @override
  Future<List<int>?> loadFromProvider({required int offset, required int limit}) =>
      provider.load(offset: offset, limit: limit);
}

void main() {
  late FakeProvider provider;

  setUp(() {
    FakeGlobalManager.install();
    provider = FakeProvider(List.generate(10, (index) => index));
  });

  group("AbsElementLoader.load", () {
    test("asks the provider for the elements it does not have yet", () async {
      final loader = _Loader(provider);

      expect(await loader.load(offset: 0, limit: 3), [0, 1, 2]);
      expect(provider.calls.single, (offset: 0, limit: 3));
    });

    test("keeps the elements it read, and reads them again from memory", () async {
      final loader = _Loader(provider);
      await loader.load(offset: 0, limit: 3);

      expect(await loader.load(offset: 0, limit: 3), [0, 1, 2]);
      expect(provider.calls.length, 1);
    });

    test("asks the provider from where it stopped", () async {
      final loader = _Loader(provider);
      await loader.load(offset: 0, limit: 3);

      expect(await loader.load(offset: 3, limit: 3), [3, 4, 5]);
      expect(provider.calls.last, (offset: 3, limit: 3));
    });

    test("fills the gap between what it has and what is asked", () async {
      final loader = _Loader(provider, preventLoadingFewElements: false);
      await loader.load(offset: 0, limit: 3);

      expect(await loader.load(offset: 5, limit: 2), [5, 6]);
      expect(provider.calls.last, (offset: 3, limit: 4));
      expect(loader.loadedElements, [0, 1, 2, 3, 4, 5, 6]);
    });

    test("asks the provider for a whole page rather than for the few elements it misses", () async {
      final loader = _Loader(provider);
      await loader.load(offset: 0, limit: 3);

      expect(await loader.load(offset: 2, limit: 3), [2, 3, 4]);
      expect(provider.calls.last, (offset: 3, limit: 3));
    });

    test("asks the provider for the few elements it misses when it is told to", () async {
      final loader = _Loader(provider, preventLoadingFewElements: false);
      await loader.load(offset: 0, limit: 3);

      expect(await loader.load(offset: 2, limit: 3), [2, 3, 4]);
      expect(provider.calls.last, (offset: 3, limit: 2));
    });

    test("gives back what it has when the provider has nothing more", () async {
      final loader = _Loader(provider);

      expect(await loader.load(offset: 0, limit: 20), List.generate(10, (index) => index));
      expect(loader.isAllLoaded, isTrue);
    });

    test("asks the provider nothing more once it has everything", () async {
      final loader = _Loader(provider);
      await loader.load(offset: 0, limit: 20);

      expect(await loader.load(offset: 10, limit: 5), isEmpty);
      expect(provider.calls.length, 1);
    });

    test("gives back nothing when the provider failed", () async {
      final loader = _Loader(provider);
      provider.fails = true;

      expect(await loader.load(offset: 0, limit: 3), isNull);
      expect(loader.loadedElements, isEmpty);
    });
  });

  group("AbsElementLoader.clearLoadedElements", () {
    test("forgets what it read, and reads it again from the provider", () async {
      final loader = _Loader(provider);
      await loader.load(offset: 0, limit: 20);

      await loader.clearLoadedElements();

      expect(loader.loadedElements, isEmpty);
      expect(loader.isAllLoaded, isFalse);
      expect(await loader.load(offset: 0, limit: 3), [0, 1, 2]);
    });
  });

  group("AbsElementLoader.updatedElement", () {
    test("replaces the element which is found", () async {
      final loader = _Loader(provider);
      await loader.load(offset: 0, limit: 3);

      loader.updatedElement((item) => item == 1, (current) => current * 10);

      expect(loader.loadedElements, [0, 10, 2]);
    });

    test("changes nothing when no element is found", () async {
      final loader = _Loader(provider);
      await loader.load(offset: 0, limit: 3);

      loader.updatedElement((item) => item == 7, (current) => current * 10);

      expect(loader.loadedElements, [0, 1, 2]);
    });
  });

  group("AbsElementLoader.deletedElement", () {
    test("forgets the element which is found", () async {
      final loader = _Loader(provider);
      await loader.load(offset: 0, limit: 3);

      expect(loader.deletedElement((item) => item == 1), isTrue);
      expect(loader.loadedElements, [0, 2]);
    });

    test("says that it deleted nothing when no element is found", () async {
      final loader = _Loader(provider);
      await loader.load(offset: 0, limit: 3);

      expect(loader.deletedElement((item) => item == 7), isFalse);
      expect(loader.loadedElements, [0, 1, 2]);
    });
  });
}
