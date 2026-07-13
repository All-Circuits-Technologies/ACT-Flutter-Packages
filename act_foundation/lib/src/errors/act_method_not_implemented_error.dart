// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/src/errors/act_error.dart';

/// This error is thrown when a `method` hasn't been implemented/overridden by a class which was
/// expected to do so (e.g. an optional method of a mixin that a third party service doesn't
/// support).
class ActMethodNotImplementedError extends ActError {
  /// Class constructor
  ActMethodNotImplementedError({required Object caller, required String method})
    : super("${caller.runtimeType} does not implement $method");

  /// This trap forcibly crashes the app (in debug mode) when an unimplemented method is reached, and
  /// throws an [ActMethodNotImplementedError] in release mode.
  ///
  /// [caller] is the instance on which the missing [method] was called (used to add context to the
  /// error, generally `this`).
  ///
  /// Services either miss this method implementation or they do not support it at all. If a service
  /// can support the missing method but doesn't implement it yet, developer may want to implement it
  /// and return a dedicated `notSupportedYet` result instead of using this trap.
  static Never crash({required Object caller, required String method}) {
    final error = ActMethodNotImplementedError(caller: caller, method: method);
    assert(false, error.message);
    throw error;
  }
}
