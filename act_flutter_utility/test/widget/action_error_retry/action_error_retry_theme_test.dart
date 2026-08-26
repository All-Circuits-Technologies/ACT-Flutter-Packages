// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const theme = ActionErrorRetryTheme(
    expandInParent: true,
    headerContentColor: Colors.red,
    headerPadding: EdgeInsets.all(4),
    headerTitleStyle: TextStyle(fontSize: 20),
    topPadding: 10,
    bottomPadding: 20,
    contentPadding: EdgeInsets.all(8),
    contentTextStyle: TextStyle(fontSize: 12),
    buttonsSeparator: 30,
  );

  group("ActionErrorRetryTheme.copyWith", () {
    test("keeps the values the caller did not give", () {
      expect(theme.copyWith(), theme);
    });

    test("replaces the values the caller gave", () {
      final copy = theme.copyWith(expandInParent: false, buttonsSeparator: 40);

      expect(copy.expandInParent, isFalse);
      expect(copy.buttonsSeparator, 40);
      expect(copy.topPadding, 10);
    });

    test("drops the paddings the caller asks to drop", () {
      final copy = theme.copyWith(
        forceToPaddingValue: true,
        forceBottomPaddingValue: true,
        forceHeaderPaddingValue: true,
        forceContentPaddingValue: true,
      );

      expect(copy.topPadding, isNull);
      expect(copy.bottomPadding, isNull);
      expect(copy.headerPadding, isNull);
      expect(copy.contentPadding, isNull);
    });

    test("drops the styles the caller asks to drop", () {
      final copy = theme.copyWith(
        forceHeaderContentColorValue: true,
        forceHeaderTitleStyleValue: true,
        forceContentTextStyleValue: true,
        forceButtonsSeparatorValue: true,
      );

      expect(copy.headerContentColor, isNull);
      expect(copy.headerTitleStyle, isNull);
      expect(copy.contentTextStyle, isNull);
      expect(copy.buttonsSeparator, isNull);
    });

    test("keeps the value the caller gave over the drop it asked for", () {
      final copy = theme.copyWith(topPadding: 50, forceToPaddingValue: true);

      expect(copy.topPadding, 50);
    });
  });
}
