// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_flutter_utility/src/widget/action_error_retry/action_error_retry_theme.dart';
import 'package:flutter/material.dart';

/// This widget is used to display a message when an error occurred with a retry button.
class ActionErrorRetryWidget extends StatelessWidget {
  /// An icon to display before the content widget
  /// If null, nothing is displayed
  final IconData? headerIcon;

  /// This is a header title to display before the content widget
  /// If null, nothing is displayed
  final String? headerTitle;

  /// This is the theme of the [ActionErrorRetryWidget]
  final ActionErrorRetryTheme theme;

  /// This is the list of buttons to display in the end of the retry widget
  final List<Widget> buttons;

  /// This is the content widget to display in the view
  final Widget content;

  /// Class constructor
  const ActionErrorRetryWidget({
    super.key,
    required this.theme,
    required this.content,
    required this.buttons,
    this.headerIcon,
    this.headerTitle,
  });

  /// This is the factory to create a view with a text as [content]
  factory ActionErrorRetryWidget.textContent({
    Key? key,
    required ActionErrorRetryTheme theme,
    required String text,
    required List<Widget> buttons,
  }) =>
      ActionErrorRetryWidget(
        key: key,
        theme: theme,
        content: Text(text, style: theme.contentTextStyle),
        buttons: buttons,
      );

  /// This is the factory to create a view with a text as [content] and a header text/icon
  factory ActionErrorRetryWidget.textContentWithHeader({
    Key? key,
    required ActionErrorRetryTheme theme,
    required String text,
    required List<Widget> buttons,
    IconData? headerIcon,
    String? headerTitle,
  }) =>
      ActionErrorRetryWidget(
        key: key,
        headerIcon: headerIcon ?? Icons.error_outline,
        headerTitle: headerTitle,
        theme: theme,
        content: Text(text, style: theme.contentTextStyle),
        buttons: buttons,
      );

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Column(
      children: [
        _buildDefaultSizedBoxOrSpacer(
          userHeight: theme.topPadding,
          defaultHeight: 90,
          defaultFlexSpacer: 6,
        ),
        if (headerIcon != null || headerTitle != null) ...[
          _wrapPadding(
            padding: theme.headerPadding,
            child: Column(
              children: [
                if (headerIcon != null)
                  Icon(
                    headerIcon,
                    color: theme.headerContentColor,
                    size: 100,
                  ),
                if (headerTitle != null)
                  Text(
                    headerTitle!,
                    style: theme.headerTitleStyle ??
                        themeData.textTheme.headlineMedium?.copyWith(
                          color: theme.headerContentColor,
                        ),
                  ),
              ],
            ),
          ),
          if (theme.headerPadding == null)
            _buildDefaultSizedBoxOrSpacer(
              userHeight: null,
              defaultHeight: 130,
              defaultFlexSpacer: 6,
            ),
        ],
        _wrapPadding(
          padding: theme.contentPadding,
          child: content,
        ),
        // We add a default spacer between the buttons and the content if [expandInParent] is equals
        // to true, because the user can't add himself a flex spacer.
        if (theme.expandInParent && theme.contentPadding == null) const Spacer(flex: 4),
        ...ListUtility.interleaveWithBuilder(
            buttons, () => SizedBox(height: theme.buttonsSeparator ?? 15)),
        _buildDefaultSizedBoxOrSpacer(
          userHeight: theme.bottomPadding,
          defaultHeight: 15,
          defaultFlexSpacer: 1,
        ),
      ],
    );
  }

  /// Wrap the [child] with a [Padding] widget if the given [padding] is not null
  Widget _wrapPadding({
    required EdgeInsets? padding,
    required Widget child,
  }) {
    if (padding == null) {
      return child;
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }

  /// Build a widget to add a space between elements.
  ///
  /// If [theme].expandInParent is equals to true, this tries to add a Spacer, with the
  /// [defaultFlexSpacer] as flex value.
  /// If [theme].expandInParent is equals to false, this adds a SizedBox, with the [userHeight] or
  /// the [defaultHeight] (if [userHeight] is null) as height value.
  ///
  /// If [userHeight] is different than null, this adds a SizedBox (even if [theme].expandInParent
  /// is equals to true).
  Widget _buildDefaultSizedBoxOrSpacer({
    required double? userHeight,
    required double defaultHeight,
    required int defaultFlexSpacer,
  }) {
    if (userHeight != null || !theme.expandInParent) {
      return SizedBox(height: userHeight ?? defaultHeight);
    }

    return Spacer(flex: defaultFlexSpacer);
  }
}
