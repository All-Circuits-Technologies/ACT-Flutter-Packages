// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/src/errors/act_error.dart';

/// This error is thrown when the [T] type isn't supported
class ActUnsupportedTypeError<T> extends ActError {
  /// This allows to add an extra context to the error
  final String? context;

  /// Class constructor
  ActUnsupportedTypeError({this.context})
    : super(
        context != null
            ? "The type: $T, isn't supported, context: $context"
            : "The type: $T, isn't supported",
      );
}
