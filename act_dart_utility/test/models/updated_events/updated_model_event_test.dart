// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';

/// A model which only carries a name.
class _User extends Equatable {
  final String name;

  const _User(this.name);

  @override
  List<Object?> get props => [name];
}

void main() {
  group("UpdatedModelEvent.newObjectCreated", () {
    test("carries the new object and no previous identifier", () {
      const event = UpdatedModelEvent<_User, String>.newObjectCreated(current: _User("a name"));

      expect(event.current, const _User("a name"));
      expect(event.previousUniqueId, isNull);
    });

    test("reports a creation and nothing else", () {
      const event = UpdatedModelEvent<_User, String>.newObjectCreated(current: _User("a name"));

      expect(event.isObjectCreated, isTrue);
      expect(event.isObjectUpdated, isFalse);
      expect(event.isObjectDeleted, isFalse);
    });
  });

  group("UpdatedModelEvent.objectUpdated", () {
    test("carries the new object and the previous identifier", () {
      const event = UpdatedModelEvent<_User, String>.objectUpdated(
        current: _User("a new name"),
        previousUniqueId: "an old name",
      );

      expect(event.current, const _User("a new name"));
      expect(event.previousUniqueId, "an old name");
    });

    test("reports an update and nothing else", () {
      const event = UpdatedModelEvent<_User, String>.objectUpdated(
        current: _User("a new name"),
        previousUniqueId: "an old name",
      );

      expect(event.isObjectUpdated, isTrue);
      expect(event.isObjectCreated, isFalse);
      expect(event.isObjectDeleted, isFalse);
    });
  });

  group("UpdatedModelEvent.objectDeleted", () {
    test("carries the previous identifier and no object", () {
      const event = UpdatedModelEvent<_User, String>.objectDeleted(previousUniqueId: "a name");

      expect(event.previousUniqueId, "a name");
      expect(event.current, isNull);
    });

    test("reports a deletion and nothing else", () {
      const event = UpdatedModelEvent<_User, String>.objectDeleted(previousUniqueId: "a name");

      expect(event.isObjectDeleted, isTrue);
      expect(event.isObjectCreated, isFalse);
      expect(event.isObjectUpdated, isFalse);
    });
  });

  group("UpdatedModelEvent equality", () {
    test("considers two events of the same kind on the same object as equal", () {
      expect(
        const UpdatedModelEvent<_User, String>.newObjectCreated(current: _User("a name")),
        const UpdatedModelEvent<_User, String>.newObjectCreated(current: _User("a name")),
      );
    });

    test("tells a creation and an update apart", () {
      expect(
        const UpdatedModelEvent<_User, String>.newObjectCreated(current: _User("a name")),
        isNot(
          const UpdatedModelEvent<_User, String>.objectUpdated(
            current: _User("a name"),
            previousUniqueId: "a name",
          ),
        ),
      );
    });
  });
}
