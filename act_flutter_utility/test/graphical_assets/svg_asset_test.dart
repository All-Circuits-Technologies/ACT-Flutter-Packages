// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const asset = SvgAsset("assets/a_drawing.svg");

  group("SvgAsset.getWidget", () {
    test("draws the picture at the size it is given", () {
      final widget = asset.getWidget(width: 20, height: 10) as SvgPicture;

      expect(widget.width, 20);
      expect(widget.height, 10);
    });

    test("reads the picture from the path it was built with", () {
      final widget = asset.getWidget() as SvgPicture;

      expect((widget.bytesLoader as SvgAssetLoader).assetName, "assets/a_drawing.svg");
    });

    test("keeps the colors of the picture when it is given none", () {
      final widget = asset.getWidget() as SvgPicture;

      expect(widget.colorFilter, isNull);
    });

    test("replaces the colors of the picture by the one it is given", () {
      final widget = asset.getWidget(color: Colors.red) as SvgPicture;

      expect(widget.colorFilter, const ColorFilter.mode(Colors.red, BlendMode.srcIn));
    });
  });
}
