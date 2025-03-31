// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The available HTTP methods
enum HttpMethods {
  /// Connect http method
  connect(str: "CONNECT"),

  /// Delete http method
  delete(str: "DELETE"),

  /// Get http method
  get(str: "GET"),

  /// Head http method
  head(str: "HEAD"),

  /// Options http method
  options(str: "OPTIONS"),

  /// Post http method
  post(str: "POST"),

  /// Put http method
  put(str: "PUT"),

  /// Trace http method
  trace(str: "TRACE"),

  /// Patch http method
  patch(str: "PATCH");

  /// Returns a string representation of the HTTP method, which can be used for external libraries
  final String str;

  /// Class constructor
  const HttpMethods({required this.str});
}
