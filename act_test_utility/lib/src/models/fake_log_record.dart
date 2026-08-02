// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:flutter/foundation.dart';

/// A message captured by a fake logger.
///
/// The record keeps everything which was given to the logger, so that a test can assert on the
/// level, on the message or on the error which was reported.
@immutable
class FakeLogRecord {
  /// The categories of the logger which recorded the message.
  ///
  /// The first category is the main category and the last one is the most specific.
  final List<String> categories;

  /// The error given with the message, if any.
  final Object? error;

  /// The level the message was logged at.
  final LogsLevel level;

  /// The logged message.
  final Object? message;

  /// The stack trace given with the message, if any.
  final StackTrace? stackTrace;

  /// Class constructor.
  const FakeLogRecord({
    required this.categories,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() =>
      "FakeLogRecord(level: $level, categories: $categories, message: $message, error: $error)";
}
