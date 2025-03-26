// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/material.dart';

/// This represents the type of information to display in the info banner
enum BannerInformationType {
  /// This represents an error banner
  error(
    basePriorityWeight: 500,
    defaultIcon: Icons.error_outline_rounded,
  ),

  /// This represents a warning banner
  warning(
    basePriorityWeight: 400,
    defaultIcon: Icons.warning_amber_rounded,
  ),

  /// This represents a success banner
  success(
    basePriorityWeight: 300,
    defaultIcon: Icons.done_rounded,
  ),

  /// This represents an information banner
  info(
    basePriorityWeight: 200,
    defaultIcon: Icons.info_outline_rounded,
  ),

  /// This represents a debug banner
  debug(
    basePriorityWeight: 100,
    defaultIcon: Icons.emoji_nature_rounded,
  );

  /// This is the default icon linked to the [BannerInformationType], equals to null, if no icon
  /// has to be displayed
  final IconData? defaultIcon;

  /// This is base for the priority weight linked to the [BannerInformationType]. More the weight
  /// is important, more the banner has to be displayed in priority
  final int basePriorityWeight;

  /// Class constructor
  const BannerInformationType({
    required this.basePriorityWeight,
    this.defaultIcon,
  });
}
