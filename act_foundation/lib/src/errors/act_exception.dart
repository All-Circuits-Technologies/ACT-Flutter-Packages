// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Base class for all the ACT specific exceptions.
///
/// An [ActException] represents a recoverable runtime condition (e.g. invalid data, a failed I/O
/// operation, a missing configuration, etc.), as opposed to `ActError` which represents a
/// programming error.
abstract class ActException implements Exception {
  /// A human readable description of the exception
  final String message;

  /// Class constructor
  const ActException(this.message);

  /// Display a representation of the exception
  @override
  String toString() => message;
}
