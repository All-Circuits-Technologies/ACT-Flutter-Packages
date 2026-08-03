// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_consent_manager/act_consent_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ConsentStateEnum.isAccepted", () {
    test("says that a consent which was accepted is accepted", () {
      expect(ConsentStateEnum.accepted.isAccepted, isTrue);
    });

    test("says that a consent nothing is known of is not standing in the way", () {
      expect(ConsentStateEnum.unknown.isAccepted, isTrue);
    });

    test("says that a consent which was refused is not accepted", () {
      expect(ConsentStateEnum.notAccepted.isAccepted, isFalse);
    });
  });

  group("ConsentStateEnum.isNotAccepted", () {
    test("only says of a consent which was refused that it was refused", () {
      expect(
        ConsentStateEnum.values.where((state) => state.isNotAccepted),
        [ConsentStateEnum.notAccepted],
      );
    });
  });
}
