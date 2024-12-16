// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/src/types/banner_information_type.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Represents an info banner to display above pages
class BannerInformationModel extends Equatable {
  /// This is the offset to apply to the priority weight, the offset is added to the
  /// [type.basePriorityWeight] value
  final int priorityWeightOffset;

  /// The type of the banner information
  final BannerInformationType type;

  /// The content of the banner
  final String text;

  /// If not null, this icon is displayed at the left of the text.
  final Widget? icon;

  /// If not null, this widget is displayed at the right of text
  /// This can be used to add a button in the banner
  final Widget? action;

  /// This is the color of the banner foreground
  final Color foregroundColor;

  /// This is the color of the banner background
  final Color backgroundColor;

  /// Returns the priority weight of the banner, more the value is high, more the banner is
  /// important
  int get priorityWeight => type.basePriorityWeight + priorityWeightOffset;

  /// Class constructor
  const BannerInformationModel({
    required this.type,
    required this.text,
    required this.foregroundColor,
    required this.backgroundColor,
    this.priorityWeightOffset = 0,
    this.icon,
    this.action,
  });

  @override
  List<Object?> get props => [
        priorityWeightOffset,
        type,
        text,
        action,
        icon,
        foregroundColor,
        backgroundColor,
      ];
}
