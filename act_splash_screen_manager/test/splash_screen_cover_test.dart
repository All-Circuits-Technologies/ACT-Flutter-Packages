// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui' as ui;

import 'package:act_splash_screen_manager/act_splash_screen_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("SplashScreenCover", () {
    testWidgets("draws the image it is given over the whole space", (tester) async {
      final image = _AnImage();

      await tester.pumpWidget(SplashScreenCover(image: image));

      final displayed = tester.widget<Image>(find.byType(Image));
      expect(displayed.image, image);
      expect(displayed.fit, BoxFit.cover);
      expect(
        tester.getSize(find.byType(Image)),
        tester.view.physicalSize / tester.view.devicePixelRatio,
      );
    });

    testWidgets("draws the background colour behind the image", (tester) async {
      await tester.pumpWidget(
        SplashScreenCover(image: _AnImage(), backgroundColor: const Color(0xFF123456)),
      );

      expect(tester.widget<ColoredBox>(find.byType(ColoredBox)).color, const Color(0xFF123456));
    });
  });
}

/// Image which needs neither a file nor a network to be resolved.
class _AnImage extends ImageProvider<_AnImage> {
  @override
  Future<_AnImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_AnImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(_aFrame());

  /// Builds the single frame of the image.
  Future<ImageInfo> _aFrame() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder);
    final image = await recorder.endRecording().toImage(1, 1);

    return ImageInfo(image: image);
  }
}
