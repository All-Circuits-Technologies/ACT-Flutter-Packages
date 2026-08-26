// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_consent_manager/act_consent_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ConsentLoadStatus", () {
    test("says that only the load which succeeded is a success", () {
      expect(
        ConsentLoadStatus.values.where((status) => status.isSuccess),
        [ConsentLoadStatus.success],
      );
    });

    test("says that a load which failed for good is the only one not to try again", () {
      expect(
        ConsentLoadStatus.values.where((status) => !status.canBeRetried),
        [ConsentLoadStatus.failed],
      );
    });
  });
}
