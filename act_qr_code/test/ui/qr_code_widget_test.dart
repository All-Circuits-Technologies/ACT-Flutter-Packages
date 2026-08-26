// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_qr_code/act_qr_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Builds the widget with the values given and returns the picture it drew.
  Future<SvgPicture> pumpQrCode(
    WidgetTester tester, {
    String text = "a code",
    Color color = const Color(0xFF000000),
    double size = 100,
    BarcodeQRCorrectionLevel level = BarcodeQRCorrectionLevel.low,
  }) async {
    await tester.pumpWidget(
      QrCodeImage(text: text, color: color, size: size, errorCorrectLevel: level),
    );

    return tester.widget<SvgPicture>(find.byType(SvgPicture));
  }

  /// The picture of the widget currently in the tree.
  SvgPicture currentPicture(WidgetTester tester) =>
      tester.widget<SvgPicture>(find.byType(SvgPicture));

  group("QrCodeImage", () {
    testWidgets("draws the code as a picture of the size asked for", (tester) async {
      final picture = await pumpQrCode(tester, size: 120);

      expect(picture.width, 120);
      expect(picture.height, 120);
    });

    testWidgets("draws a different code for a different text", (tester) async {
      final first = await pumpQrCode(tester);
      final second = await pumpQrCode(tester, text: "another code");

      expect(first.bytesLoader, isNot(second.bytesLoader));
    });

    testWidgets("draws a different code for a different correction level", (tester) async {
      final low = await pumpQrCode(tester);
      final high = await pumpQrCode(tester, level: BarcodeQRCorrectionLevel.high);

      expect(low.bytesLoader, isNot(high.bytesLoader));
    });

    testWidgets("draws the code in the colour asked for", (tester) async {
      final black = await pumpQrCode(tester);
      final blue = await pumpQrCode(tester, color: const Color(0xFF0000FF));

      expect(black.bytesLoader, isNot(blue.bytesLoader));
    });

    testWidgets("draws the code again when the text changes", (tester) async {
      final first = await pumpQrCode(tester);

      await pumpQrCode(tester, text: "another code");

      expect(currentPicture(tester).bytesLoader, isNot(first.bytesLoader));
    });

    testWidgets("draws the code again when the colour changes", (tester) async {
      final first = await pumpQrCode(tester);

      await pumpQrCode(tester, color: const Color(0xFF0000FF));

      expect(currentPicture(tester).bytesLoader, isNot(first.bytesLoader));
    });

    testWidgets("draws the code again when the correction level changes", (tester) async {
      final first = await pumpQrCode(tester);

      await pumpQrCode(tester, level: BarcodeQRCorrectionLevel.quartile);

      expect(currentPicture(tester).bytesLoader, isNot(first.bytesLoader));
    });

    testWidgets("keeps the code it has already drawn when only the size changes", (tester) async {
      final first = await pumpQrCode(tester);

      await pumpQrCode(tester, size: 200);

      expect(currentPicture(tester).bytesLoader, first.bytesLoader);
      expect(currentPicture(tester).width, 200);
    });

    testWidgets("keeps the code it has already drawn when nothing changes", (tester) async {
      final first = await pumpQrCode(tester);

      await pumpQrCode(tester);

      expect(currentPicture(tester).bytesLoader, first.bytesLoader);
    });

    testWidgets("draws a code for an empty text", (tester) async {
      await pumpQrCode(tester, text: "");

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets("draws the code with the lowest correction level by default", (tester) async {
      await tester.pumpWidget(
        const QrCodeImageDefaults(),
      );

      final byDefault = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final low = await pumpQrCode(tester);

      expect(byDefault.bytesLoader, low.bytesLoader);
    });
  });
}

/// The widget built without asking for any correction level.
class QrCodeImageDefaults extends StatelessWidget {
  /// Class constructor
  const QrCodeImageDefaults({super.key});

  @override
  Widget build(BuildContext context) =>
      QrCodeImage(text: "a code", color: const Color(0xFF000000), size: 100);
}
