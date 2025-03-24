// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/material.dart';

/// This is the SnackBar for the ACT projects
class ActSnackBar extends SnackBar {
  /// This is the duration to use for displaying the snack bar
  static const _snackBarDuration = Duration(milliseconds: 3500);

  /// This is the indefinite duration when we want to force the user to acknowledge the snack bar
  static const _indefiniteSnackBarDuration = Duration(days: 365);

  /// Class constructor
  ActSnackBar({
    super.key,
    required ThemeData theme,
    required String text,
    String? errorText,
    bool isOnError = false,
    bool forceAckByUser = false,
    super.padding,
  }) : super(
          duration: forceAckByUser ? _indefiniteSnackBarDuration : _snackBarDuration,
          content: Text(
            (errorText != null && isOnError) ? errorText : text,
            textAlign: TextAlign.center,
            style: isOnError
                ? theme.snackBarTheme.contentTextStyle?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onError,
                  )
                : null,
          ),
          backgroundColor: isOnError ? theme.colorScheme.error : null,
          showCloseIcon: forceAckByUser,
          closeIconColor: isOnError ? theme.colorScheme.onError : null,
        );

  /// {@template act_flutter_utility.ActSnackBar.showActSnackBar}
  /// Helpful method to simplify the display of the ACT snack bar
  ///
  /// If [extraAction] is given, it's called when the snack bar is closed (by clicking on the
  /// ack button or waiting for the snack bar end).
  /// {@endtemplate}
  static Future<SnackBarClosedReason> showActSnackBar({
    required BuildContext context,
    required String text,
    String? errorText,
    bool isOnError = false,
    bool forceAckByUser = false,
    EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    VoidCallback? extraAction,
  }) =>
      showExtSnackBar(
        context: context,
        snackBarFactory: () => ActSnackBar(
          text: text,
          errorText: errorText,
          theme: Theme.of(context),
          isOnError: isOnError,
          forceAckByUser: forceAckByUser,
          padding: padding,
        ),
        extraAction: extraAction,
      );

  /// {@macro act_flutter_utility.ActSnackBar.showActSnackBar}
  ///
  /// Create the snack bar widget thanks to the [snackBarFactory] callback.
  @protected
  static Future<SnackBarClosedReason> showExtSnackBar<T extends ActSnackBar>({
    required BuildContext context,
    required T Function() snackBarFactory,
    VoidCallback? extraAction,
  }) async {
    final ctrl = ScaffoldMessenger.of(context).showSnackBar(snackBarFactory());

    final reason = await ctrl.closed;

    if (extraAction != null) {
      extraAction();
    }

    return reason;
  }
}
