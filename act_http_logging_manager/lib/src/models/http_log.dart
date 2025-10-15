// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:equatable/equatable.dart';

/// Contains the log of an http request
class HttpLog extends Equatable {
  /// Separator used to separate the extra source info in the log message
  static const extraSourceInfoSeparator = "/";

  /// The timestamp of the log
  final DateTime timestamp;

  /// This is the unique id of the request
  final String requestId;

  /// Optional source info to add to the log message
  final String? sourceInfo;

  /// The route of the request called
  final String route;

  /// The HTTP method of the request
  final String method;

  /// The log level of the message
  final Level logLevel;

  /// The message of the log
  final String message;

  /// Get a formatted log message
  String get formattedLogMsg {
    String requestInfo;
    if (sourceInfo != null) {
      requestInfo = "$sourceInfo$extraSourceInfoSeparator$requestId";
    } else {
      requestInfo = requestId;
    }

    return "[$requestInfo] - $route - $method - $message";
  }

  /// Constructor
  const HttpLog({
    required this.timestamp,
    required this.requestId,
    required this.route,
    required this.method,
    required this.logLevel,
    required this.message,
    this.sourceInfo,
  });

  /// Create a new HttpLog
  ///
  /// The [timestamp] is set to the current time in UTC
  HttpLog.now({
    required this.requestId,
    required this.route,
    required this.method,
    required this.logLevel,
    required this.message,
    this.sourceInfo,
  }) : timestamp = DateTime.now().toUtc();

  /// Create a copy of the current HttpLog with the given parameters
  HttpLog copyWith({
    DateTime? timestamp,
    String? requestId,
    String? route,
    String? method,
    Level? logLevel,
    String? message,
    String? sourceInfo,
  }) => HttpLog(
    timestamp: timestamp ?? this.timestamp,
    requestId: requestId ?? this.requestId,
    route: route ?? this.route,
    method: method ?? this.method,
    logLevel: logLevel ?? this.logLevel,
    message: message ?? this.message,
    sourceInfo: sourceInfo ?? this.sourceInfo,
  );

  /// {@macro equatable_props}
  @override
  List<Object?> get props => [timestamp, requestId, route, method, logLevel, message, sourceInfo];
}
