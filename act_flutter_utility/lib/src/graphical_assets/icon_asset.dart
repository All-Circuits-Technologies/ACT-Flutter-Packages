// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/src/graphical_assets/graphical_asset.dart';
import 'package:flutter/material.dart';

/// Icon Asset helps working with material icons
///
/// Icons are similar to vectorial assets.
/// Known issue: icons are always slightly smaller than their requested size
class IconAsset implements GraphicalAsset {
  /// Material icon identifier
  final IconData icon;

  /// Icon asset constructor
  const IconAsset(this.icon);

  /// Build associated widget
  ///
  /// This override accepts an optional extra color argument.
  /// Note that only squared icons are supported. If both [width] and [height] are given, they must
  /// be equal. It is fine to give only one of the two.
  @override
  Widget getWidget({double? width, double? height, Color? color}) {
    assert(
      (width == null || height == null) || width == height,
      "If both given, width and height must be equal",
    );
    final size = width ?? height;

    // Build icon with explicitly asked size,
    // or with a size which fills parent
    return size != null
        ? _getIcon(color: color, size: size)
        : FittedBox(child: _getIcon(color: color));
  }

  /// Icon builder
  Widget _getIcon({Color? color, double? size}) => Icon(icon, color: color, size: size);
}
