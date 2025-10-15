// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_logging_manager/act_http_logging_manager.dart';
import 'package:shelf/shelf.dart';

/// This class represents a log entry for an HTTP request.
class HttpRequestLog extends HttpLog {
  /// Class constructor
  const HttpRequestLog({
    required super.timestamp,
    required super.requestId,
    required super.route,
    required super.method,
    required super.logLevel,
    required super.message,
  });

  /// Class constructor with the current time as timestamp
  HttpRequestLog.now({
    required super.requestId,
    required super.route,
    required super.method,
    required super.logLevel,
    required super.message,
  }) : super.now();

  /// Class constructor with the current time as timestamp and a [Request] object to extract the
  /// method and route
  HttpRequestLog.requestNow({
    required super.requestId,
    required Request request,
    required super.logLevel,
    required super.message,
  }) : super(
         method: request.method,
         route: request.url.toString(),
         timestamp: DateTime.now().toUtc(),
       );
}
