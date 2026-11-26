// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_provider.dart';

void main() {
  late FakeProvider provider;

  setUp(() {
    FakeGlobalManager.install();
    provider = FakeProvider(List.generate(10, (index) => index));
  });

  group("ElementLoader.loadFromProvider", () {
    test("asks the callback it was built with for the elements", () async {
      final loader = ElementLoader<int>(callback: provider.load);

      expect(await loader.load(offset: 0, limit: 3), [0, 1, 2]);
      expect(provider.calls.single, (offset: 0, limit: 3));
    });
  });

  group("ElementLoader.clearLoadedElements", () {
    test("forgets how many of its elements were used", () async {
      final loader = ElementLoader<int>(callback: provider.load);
      await loader.load(offset: 0, limit: 3);
      loader.elementsSizeReallyUsed = 3;

      await loader.clearLoadedElements();

      expect(loader.elementsSizeReallyUsed, 0);
      expect(loader.loadedElements, isEmpty);
    });
  });
}
