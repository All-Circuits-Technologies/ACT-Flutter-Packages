// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// This class represents a log message.
class LogMessage extends Equatable {
  /// The message of the log.
  final dynamic message;

  /// The categories of the log.
  final List<String> categories;

  /// Class constructor
  LogMessage({
    required this.message,
    required this.categories,
  });

  /// Log message properties
  @override
  List<Object?> get props => [message, categories];
}
