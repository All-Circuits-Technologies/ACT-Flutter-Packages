// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/widgets.dart';

/// Widget displaying the image of the splash screen of the platform.
///
/// The platform removes its splash screen at a moment the application does not choose, and the
/// first frame it uncovers may not be the one the application wants to be seen first. Displaying
/// the same image in the first view makes that moment invisible: the screen shows the same thing
/// before and after.
///
/// The widget draws the image and nothing else. Which view displays it, and until when, belongs to
/// the application.
class SplashScreenCover extends StatelessWidget {
  /// Image of the splash screen, the very one the platform draws.
  final ImageProvider image;

  /// How the image occupies the space it is given.
  final BoxFit fit;

  /// Color drawn behind the image, seen where the image does not reach.
  final Color backgroundColor;

  /// Class constructor
  const SplashScreenCover({
    required this.image,
    this.fit = BoxFit.cover,
    this.backgroundColor = const Color(0xFF000000),
    super.key,
  });

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: backgroundColor,
    child: SizedBox.expand(
      child: Image(image: image, fit: fit),
    ),
  );
}
