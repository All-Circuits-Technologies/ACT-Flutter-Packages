// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';

/// A model whose identity is its own identifier.
class _User extends Equatable with MixinUniqueModel {
  final String name;

  const _User(this.name);

  @override
  String get uniqueId => name;

  @override
  List<Object?> get props => [name];
}

void main() {
  group("UpdatedUniqueModelEvent.newObjectCreated", () {
    test("carries the new object and no previous identifier", () {
      const event = UpdatedUniqueModelEvent<_User>.newObjectCreated(current: _User("a name"));

      expect(event.current, const _User("a name"));
      expect(event.previousUniqueId, isNull);
      expect(event.isObjectCreated, isTrue);
    });
  });

  group("UpdatedUniqueModelEvent.objectUpdated", () {
    test("takes the previous identifier from the object itself", () {
      final event = UpdatedUniqueModelEvent<_User>.objectUpdated(current: const _User("a name"));

      expect(event.previousUniqueId, "a name");
      expect(event.isObjectUpdated, isTrue);
    });
  });

  group("UpdatedUniqueModelEvent.objectDeleted", () {
    test("carries the identifier of the object which is gone", () {
      const event = UpdatedUniqueModelEvent<_User>.objectDeleted(previousUniqueId: "a name");

      expect(event.previousUniqueId, "a name");
      expect(event.current, isNull);
      expect(event.isObjectDeleted, isTrue);
    });
  });

  group("UpdatedUniqueModelEvent", () {
    test("is an event on a model whose identifier is a string", () {
      const event = UpdatedUniqueModelEvent<_User>.newObjectCreated(current: _User("a name"));

      expect(event, isA<UpdatedModelEvent<_User, String>>());
    });
  });
}
