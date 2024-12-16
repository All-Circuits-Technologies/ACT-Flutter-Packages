// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui' as ui;

import 'package:act_flutter_utility/src/graphical_assets/graphical_asset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// SVG Asset helps working with SVG (vectorial) images
class SvgAsset implements GraphicalAsset {
  /// Path to SVG file
  final String path;

  /// SVG asset constructor
  const SvgAsset(this.path);

  /// Build associated widget
  /// This override accepts an optional extra color argument. If not null, only shape and opacity
  /// of SVG asset is used, with given color instead of original asset color(s).
  @override
  Widget getWidget({double? width, double? height, Color? color}) => SvgPicture.asset(
        path,
        width: width,
        height: height,
        colorFilter: color != null ? ui.ColorFilter.mode(color, ui.BlendMode.srcIn) : null,
      );
}
