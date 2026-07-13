// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/src/errors/act_exception.dart';

/// Base class for all the ACT specific errors.
///
/// An [ActError] represents a programming error (e.g. a precondition violation, an unimplemented
/// method, a misused API, etc.) that should not be caught in production code, as opposed to
/// [ActException] which represents a recoverable runtime condition.
abstract class ActError extends Error {
  /// A human readable description of the error
  final String message;

  /// Class constructor
  ActError(this.message);

  /// Display a representation of the error
  @override
  String toString() => message;
}
