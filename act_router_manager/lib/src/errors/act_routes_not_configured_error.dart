// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';

/// This error is thrown when some routes haven't been set with the `on` method of the routes
/// helper; therefore, some pages won't be displayed correctly.
class ActRoutesNotConfiguredError extends ActError {
  /// This is the default error message for this error
  static const _errorMessage =
      "Some routes haven't been set with the 'on' method; therefore, some pages won't be "
      "displayed correctly";

  /// Class constructor
  ActRoutesNotConfiguredError() : super(_errorMessage);

  /// This trap forcibly crashes the app (in debug mode) when a route isn't configured, and
  /// throws an [ActRoutesNotConfiguredError] in release mode.
  static Never crash() {
    assert(false, _errorMessage);
    throw ActRoutesNotConfiguredError();
  }
}
