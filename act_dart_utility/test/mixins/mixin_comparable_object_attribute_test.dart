// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// A model which can be sorted by more than one of its properties.
class _User {
  final String name;
  final int age;

  const _User(this.name, this.age);
}

/// The properties a list of users can be sorted by.
enum _UserAttribute with MixinComparableObjectAttribute<_User> {
  name,
  age;

  @override
  int compareTo(_User base, _User toCompareWith) => switch (this) {
    _UserAttribute.name => base.name.compareTo(toCompareWith.name),
    _UserAttribute.age => base.age.compareTo(toCompareWith.age),
  };
}

const _alice = _User("alice", 40);
const _bob = _User("bob", 30);

void main() {
  group("MixinComparableObjectAttribute.compareTo", () {
    test("compares the objects on the attribute it carries", () {
      expect(_UserAttribute.name.compareTo(_alice, _bob), lessThan(0));
      expect(_UserAttribute.age.compareTo(_alice, _bob), greaterThan(0));
    });

    test("says two objects are equal on an attribute they share", () {
      expect(_UserAttribute.age.compareTo(_alice, const _User("carol", 40)), 0);
    });

    test("sorts a list on the attribute", () {
      final users = [_alice, _bob]..sort(_UserAttribute.age.compareTo);

      expect(users.map((user) => user.name).toList(), ["bob", "alice"]);
    });
  });

  group("MixinComparableObjectAttribute.invertCompareTo", () {
    test("returns the opposite of the comparison", () {
      expect(_UserAttribute.name.invertCompareTo(_alice, _bob), greaterThan(0));
    });

    test("keeps two equal objects equal", () {
      expect(_UserAttribute.age.invertCompareTo(_alice, const _User("carol", 40)), 0);
    });

    test("sorts a list in the reverse order", () {
      final users = [_bob, _alice]..sort(_UserAttribute.age.invertCompareTo);

      expect(users.map((user) => user.name).toList(), ["alice", "bob"]);
    });
  });
}
