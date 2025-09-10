// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// This class allows to extend the [TextStyle] style of the [Text] widget
class ExtendedTextStyle extends Equatable {
  /// This is the style to apply to the text widget
  final TextStyle? style;

  /// This is the alignment to apply to the text widget
  final TextAlign? align;

  /// Class constructor
  const ExtendedTextStyle({
    this.style,
    this.align,
  });

  /// Copy the current object and update the wanted properties
  ExtendedTextStyle copyWith({
    TextStyle? style,
    bool forceStyleValue = false,
    TextAlign? align,
    bool forceAlignValue = false,
  }) =>
      ExtendedTextStyle(
        style: style ?? (forceStyleValue ? null : this.style),
        align: align ?? (forceAlignValue ? null : this.align),
      );

  /// Class properties
  @override
  List<Object?> get props => [style, align];
}
