// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const asset = PngAsset("assets/a_picture.png");

  /// The ratio between the pixels of the screen and the ones of the picture to decode.
  double devicePixelRatio() =>
      WidgetsBinding.instance.platformDispatcher.implicitView!.devicePixelRatio;

  group("PngAsset.getWidget", () {
    test("draws the picture at the size it is given", () {
      final widget = asset.getWidget(width: 20, height: 10) as Image;

      expect(widget.width, 20);
      expect(widget.height, 10);
    });

    test("decodes the picture at the resolution of the screen", () {
      final widget = asset.getWidget(width: 20, height: 10) as Image;

      final resized = widget.image as ResizeImage;
      expect(resized.width, (20 * devicePixelRatio()).toInt());
      expect(resized.height, (10 * devicePixelRatio()).toInt());
    });

    test("reads the picture from the path it was built with", () {
      final widget = asset.getWidget(width: 20) as Image;

      final resized = widget.image as ResizeImage;
      expect((resized.imageProvider as AssetImage).assetName, "assets/a_picture.png");
    });

    test("decodes the picture as it is when it is given no size", () {
      final widget = asset.getWidget() as Image;

      expect((widget.image as AssetImage).assetName, "assets/a_picture.png");
    });

    test("draws the picture in the color it is given", () {
      final widget = asset.getWidget(color: Colors.red) as Image;

      expect(widget.color, Colors.red);
    });

    test("keeps the whole picture inside the size it is given", () {
      final widget = asset.getWidget(width: 20, height: 10) as Image;

      expect(widget.fit, BoxFit.contain);
    });
  });
}
