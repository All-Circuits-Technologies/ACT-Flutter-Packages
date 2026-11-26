// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_routes.dart';

void main() {
  group("MixinRoute.path", () {
    test("returns the name of a page at the root of the tree, behind a separator", () {
      expect(FakeRoute.home.path, "/home");
    });

    test("returns the path of the parents of a nested page", () {
      expect(FakeRoute.profile.path, "/settings/profile");
    });
  });

  group("MixinRoute.oneLevelPath", () {
    test("returns the name of a page at the root of the tree, behind a separator", () {
      expect(FakeRoute.settings.oneLevelPath, "/settings");
    });

    test("returns only the name of a nested page, which its parent prefixes", () {
      expect(FakeRoute.profile.oneLevelPath, "profile");
    });
  });

  group("MixinRoute.parent", () {
    test("returns nothing for a page at the root of the tree", () {
      expect(FakeRoute.home.parent, isNull);
    });

    test("returns the page a nested page hangs under", () {
      expect(FakeRoute.profile.parent, FakeRoute.settings);
    });
  });
}
