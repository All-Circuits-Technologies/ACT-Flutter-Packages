// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:flutter_test/flutter_test.dart';

/// A status which only says what it was built with, to exercise what the mixin derives from it.
class _Status with MixinResultStatus {
  @override
  final bool isSuccess;

  @override
  final bool canBeRetried;

  const _Status({required this.isSuccess, required this.canBeRetried});
}

void main() {
  group("MixinResultStatus.isError", () {
    test("returns false when the status is a success", () {
      const status = _Status(isSuccess: true, canBeRetried: false);

      expect(status.isError, isFalse);
    });

    test("returns true when the status is not a success", () {
      const status = _Status(isSuccess: false, canBeRetried: false);

      expect(status.isError, isTrue);
    });
  });

  group("MixinResultStatus.canBeRetried", () {
    test("is independent from the success of the status", () {
      const status = _Status(isSuccess: false, canBeRetried: true);

      expect(status.isError, isTrue);
      expect(status.canBeRetried, isTrue);
    });
  });
}
