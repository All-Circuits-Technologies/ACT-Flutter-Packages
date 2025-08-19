// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Contains the theme to use in the action error retry widget
class ActionErrorRetryTheme extends Equatable {
  /// {@template act_flutter_utility.ActionErrorRetryTheme.headerContentColor}
  /// Color for the icon and the header text (if [headerTitleStyle] is not set)
  /// {@endtemplate}
  final Color? headerContentColor;

  /// {@template act_flutter_utility.ActionErrorRetryTheme.headerPadding}
  /// This is the padding to apply to the header
  ///
  /// This is only used if a padding is displayed.
  ///
  /// If null and [expandInParent] is equals to:
  /// - false: a default padding is applied
  /// - true: a default spacer is applied
  /// {@endtemplate}
  final EdgeInsets? headerPadding;

  /// {@template act_flutter_utility.ActionErrorRetryTheme.headerTitleStyle}
  /// This is the title style of the header
  ///
  /// If nothing is given, the headlineMedium is used, with the [headerContentColor]
  /// {@endtemplate}
  final TextStyle? headerTitleStyle;

  /// {@template act_flutter_utility.ActionErrorRetryTheme.expandInParent}
  /// True to expand the content in the parent widget
  /// False to not (to use when the widget is added in an infinite widget).
  ///
  /// If the widgets expands in parent the default paddings are spacers and not fixed values.
  /// {@endtemplate}
  final bool expandInParent;

  /// {@template act_flutter_utility.ActionErrorRetryTheme.topPadding}
  /// Top padding of the widget
  ///
  /// If null and [expandInParent] is equals to:
  /// - false: a default padding is applied
  /// - true: a default spacer is applied
  /// {@endtemplate}
  final double? topPadding;

  /// {@template act_flutter_utility.ActionErrorRetryTheme.bottomPadding}
  /// Bottom padding of the widget
  ///
  /// If null and [expandInParent] is equals to:
  /// - false: a default padding is applied
  /// - true: a default spacer is applied
  /// {@endtemplate}
  final double? bottomPadding;

  /// {@template act_flutter_utility.ActionErrorRetryTheme.contentPadding}
  /// This is the padding to apply to the content
  ///
  /// If null and [expandInParent] is equals to:
  /// - false: a default padding is applied
  /// - true: a default spacer is applied
  /// {@endtemplate}
  final EdgeInsets? contentPadding;

  /// {@template act_flutter_utility.ActionErrorRetryTheme.contentTextStyle}
  /// This is the text style of the content text
  ///
  /// If nothing is given, the bodyMedium is used.
  ///
  /// This is only used with the text content constructors
  /// {@endtemplate}
  final TextStyle? contentTextStyle;

  /// {@template act_flutter_utility.ActionErrorRetryTheme.buttonsSeparator}
  /// This is the separator height to apply between the buttons
  ///
  /// If null, a default size is used
  /// {@endtemplate}
  final double? buttonsSeparator;

  /// Class constructor
  const ActionErrorRetryTheme({
    required this.expandInParent,
    this.headerContentColor,
    this.headerPadding,
    this.headerTitleStyle,
    this.topPadding,
    this.bottomPadding,
    this.contentPadding,
    this.contentTextStyle,
    this.buttonsSeparator,
  });

  /// Copy with method to create a new instance of [ActionErrorRetryTheme]
  ActionErrorRetryTheme copyWith({
    bool? expandInParent,
    Color? headerContentColor,
    bool forceHeaderContentColorValue = false,
    EdgeInsets? headerPadding,
    bool forceHeaderPaddingValue = false,
    TextStyle? headerTitleStyle,
    bool forceHeaderTitleStyleValue = false,
    double? topPadding,
    bool forceToPaddingValue = false,
    double? bottomPadding,
    bool forceBottomPaddingValue = false,
    EdgeInsets? contentPadding,
    bool forceContentPaddingValue = false,
    TextStyle? contentTextStyle,
    bool forceContentTextStyleValue = false,
    double? buttonsSeparator,
    bool forceButtonsSeparatorValue = false,
  }) =>
      ActionErrorRetryTheme(
          expandInParent: expandInParent ?? this.expandInParent,
          headerContentColor:
              headerContentColor ?? (forceHeaderContentColorValue ? null : this.headerContentColor),
          topPadding: topPadding ?? (forceToPaddingValue ? null : this.topPadding),
          headerPadding: headerPadding ?? (forceHeaderPaddingValue ? null : this.headerPadding),
          headerTitleStyle:
              headerTitleStyle ?? (forceHeaderTitleStyleValue ? null : this.headerTitleStyle),
          bottomPadding: bottomPadding ?? (forceBottomPaddingValue ? null : this.bottomPadding),
          contentPadding: contentPadding ?? (forceContentPaddingValue ? null : this.contentPadding),
          contentTextStyle:
              contentTextStyle ?? (forceContentTextStyleValue ? null : this.contentTextStyle),
          buttonsSeparator:
              buttonsSeparator ?? (forceButtonsSeparatorValue ? null : this.buttonsSeparator));

  /// Class properties
  @override
  List<Object?> get props => [
        expandInParent,
        headerContentColor,
        headerPadding,
        headerTitleStyle,
        topPadding,
        bottomPadding,
        contentPadding,
        contentTextStyle,
        buttonsSeparator
      ];
}
