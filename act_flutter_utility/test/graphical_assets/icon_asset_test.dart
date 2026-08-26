// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const asset = IconAsset(Icons.done_rounded);

  group("IconAsset.getWidget", () {
    test("draws the icon at the width it is given", () {
      final widget = asset.getWidget(width: 24);

      expect((widget as Icon).size, 24);
    });

    test("draws the icon at the height it is given", () {
      final widget = asset.getWidget(height: 24);

      expect((widget as Icon).size, 24);
    });

    test("draws the icon in the color it is given", () {
      final widget = asset.getWidget(width: 24, color: Colors.red);

      expect((widget as Icon).color, Colors.red);
    });

    test("fills its parent when it is given no size", () {
      final widget = asset.getWidget();

      expect(widget, isA<FittedBox>());
    });

    test("refuses a width and a height which differ", () {
      expect(() => asset.getWidget(width: 24, height: 25), throwsAssertionError);
    });

    test("accepts a width and a height which are equal", () {
      final widget = asset.getWidget(width: 24, height: 24);

      expect((widget as Icon).size, 24);
    });
  });
}
