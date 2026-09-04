// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const style = ExtendedTextStyle(style: TextStyle(fontSize: 12), align: TextAlign.center);

  group("ExtendedTextStyle.copyWith", () {
    test("keeps the values the caller did not give", () {
      final copy = style.copyWith();

      expect(copy, style);
    });

    test("replaces the style the caller gave", () {
      final copy = style.copyWith(style: const TextStyle(fontSize: 14));

      expect(copy.style?.fontSize, 14);
      expect(copy.align, TextAlign.center);
    });

    test("replaces the alignment the caller gave", () {
      final copy = style.copyWith(align: TextAlign.end);

      expect(copy.align, TextAlign.end);
      expect(copy.style, style.style);
    });

    test("drops the style when the caller asks for it", () {
      final copy = style.copyWith(forceStyleValue: true);

      expect(copy.style, isNull);
      expect(copy.align, TextAlign.center);
    });

    test("drops the alignment when the caller asks for it", () {
      final copy = style.copyWith(forceAlignValue: true);

      expect(copy.align, isNull);
      expect(copy.style, style.style);
    });

    test("keeps the value the caller gave over the drop it asked for", () {
      final copy = style.copyWith(align: TextAlign.end, forceAlignValue: true);

      expect(copy.align, TextAlign.end);
    });
  });
}
