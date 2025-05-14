// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This error is thrown when the [T] type isn't supported
class ActUnsupportedTypeError<T> extends Error {
  /// This allows to add an extra context to the error
  final String? context;

  /// Class constructor
  ActUnsupportedTypeError({
    this.context,
  });

  /// Display a representation of the error
  @override
  String toString() {
    var error = "The type: $T, isn't supported";

    if (context != null) {
      error = "$error, context: $context";
    }

    return error;
  }
}
