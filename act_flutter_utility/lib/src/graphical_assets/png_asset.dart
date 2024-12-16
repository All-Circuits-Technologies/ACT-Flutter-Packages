// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/src/graphical_assets/graphical_asset.dart';
import 'package:flutter/material.dart';

/// PNG Asset helps working with PNG (matricial) images
class PngAsset implements GraphicalAsset {
  /// Path to PNG file
  final String path;

  /// PNG asset constructor
  const PngAsset(this.path);

  /// Build associated widget
  @override
  Widget getWidget({
    double? width,
    double? height,
  }) {
    final devicePixelRatio =
        WidgetsBinding.instance.platformDispatcher.implicitView?.devicePixelRatio ?? 1;

    return Image(
      image: ResizeImage.resizeIfNeeded(
        (width != null) ? (width * devicePixelRatio).toInt() : null,
        (height != null) ? (height * devicePixelRatio).toInt() : null,
        AssetImage(path),
      ),
      fit: BoxFit.contain,
      height: height,
      width: width,
    );
  }
}
