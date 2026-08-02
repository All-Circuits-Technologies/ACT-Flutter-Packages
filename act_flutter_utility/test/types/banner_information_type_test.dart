// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("BannerInformationType", () {
    test("weighs the types from the most to the least important", () {
      final weights = BannerInformationType.values.map((type) => type.basePriorityWeight).toList();

      expect(weights, [500, 400, 300, 200, 100]);
    });

    test("leaves room between two types for a banner to be moved between them", () {
      expect(
        BannerInformationType.error.basePriorityWeight -
            BannerInformationType.warning.basePriorityWeight,
        100,
      );
    });

    test("gives every type an icon of its own", () {
      final icons = BannerInformationType.values.map((type) => type.defaultIcon).toSet();

      expect(icons.length, BannerInformationType.values.length);
    });
  });
}
