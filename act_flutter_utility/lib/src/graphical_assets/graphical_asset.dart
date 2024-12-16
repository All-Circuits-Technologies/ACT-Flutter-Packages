// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/material.dart';

/// This abstract class serves as a type and an interface for graphical assets
abstract interface class GraphicalAsset {
  /// Build a widget for the asset
  Widget getWidget({double? width, double? height});
}
