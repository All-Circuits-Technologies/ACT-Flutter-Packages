// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_provider.dart';

/// Sorts the elements of the sources from the smallest to the biggest.
int _ascending(int first, int second) => first.compareTo(second);

/// Keeps the elements which are even.
bool _isEven(int model) => model.isEven;

void main() {
  late FakeProvider provider;

  setUp(() => provider = FakeProvider([0, 1, 2]));

  /// The config of a companion which reads from the provider of the test.
  ElementLoaderConfig<int> aConfig() =>
      ElementLoaderConfig<int>(callbacks: [provider.load], sortItems: _ascending);

  group("ElementLoaderConfig", () {
    test("keeps no filter when it was given none", () {
      expect(aConfig().extraAppFilters, isEmpty);
    });

    test("is the same config as another one which reads and sorts the same way", () {
      expect(aConfig(), aConfig());
    });

    test("is another config as soon as it sorts another way", () {
      expect(aConfig(), isNot(aConfig().copyWith(sortItems: (first, second) => 0)));
    });
  });

  group("ElementLoaderConfig.copyWith", () {
    test("keeps what is not named", () {
      final config = aConfig();

      final copy = config.copyWith();

      expect(copy.callbacks, config.callbacks);
      expect(copy.sortItems, config.sortItems);
      expect(copy.extraAppFilters, config.extraAppFilters);
    });

    test("replaces what is named", () {
      final anotherProvider = FakeProvider([3]);

      final copy = aConfig().copyWith(
        callbacks: [anotherProvider.load],
        extraAppFilters: [_isEven],
      );

      expect(copy.callbacks, [anotherProvider.load]);
      expect(copy.extraAppFilters, [_isEven]);
    });
  });
}
