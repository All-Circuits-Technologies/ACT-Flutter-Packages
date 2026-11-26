// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Exception used to send logs debug sessions to crashlytics
class FirebaseCrashDebugSessionException implements Exception {
  /// The debug identifier use for the log sessions
  final String identifier;

  /// Class constructor
  FirebaseCrashDebugSessionException(this.identifier);

  /// To string method for the exception class
  @override
  String toString() => "Firebase - crashlytics: logs linked to identifier: $identifier";
}
