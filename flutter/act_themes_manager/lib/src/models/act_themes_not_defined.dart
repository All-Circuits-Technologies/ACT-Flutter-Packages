// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This error is thrown when no theme has been defined for the application.
class ActThemesNotDefinedError extends Error {
  /// Display a representation of the error
  @override
  String toString() =>
      "No theme has been defined for the application, please define at least one theme in the "
      "registration of the ActThemesManager";
}
