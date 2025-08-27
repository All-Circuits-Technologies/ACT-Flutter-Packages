// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/material.dart';

/// This abstract class serves as a type and an interface for graphical assets
abstract interface class GraphicalAsset {
  /// Build a widget for the asset
  ///
  /// The [color] parameter may be managed differently following the derived asset class. But the
  /// main principle is to color the asset with it.
  Widget getWidget({double? width, double? height, Color? color});
}
