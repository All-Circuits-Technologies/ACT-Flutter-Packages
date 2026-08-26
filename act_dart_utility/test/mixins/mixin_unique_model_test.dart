// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';

/// A model whose identifier is only one of its properties.
class _User extends Equatable with MixinUniqueModel {
  final String id;
  final String name;

  const _User({required this.id, required this.name});

  @override
  String get uniqueId => id;

  @override
  List<Object?> get props => [id, name];
}

void main() {
  group("MixinUniqueModel.uniqueId", () {
    test("returns the identifier the model chose", () {
      const user = _User(id: "42", name: "a name");

      expect(user.uniqueId, "42");
    });

    test("stays the same for two models which only differ by another property", () {
      const user = _User(id: "42", name: "a name");
      const otherUser = _User(id: "42", name: "another name");

      expect(user.uniqueId, otherUser.uniqueId);
      expect(user, isNot(otherUser));
    });

    test("lets a model be found among others", () {
      const users = [_User(id: "1", name: "a"), _User(id: "2", name: "b")];

      expect(
        users.firstWhere((user) => user.uniqueId == "2").name,
        "b",
      );
    });
  });
}
