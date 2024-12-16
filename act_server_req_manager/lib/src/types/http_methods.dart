// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The available HTTP methods
enum HttpMethods {
  connect(str: "CONNECT"),
  delete(str: "DELETE"),
  get(str: "GET"),
  head(str: "HEAD"),
  options(str: "OPTIONS"),
  post(str: "POST"),
  put(str: "PUT"),
  trace(str: "TRACE"),
  patch(str: "PATCH");

  /// Returns a string representation of the HTTP method, which can be used for external libraries
  final String str;

  /// Class constructor
  const HttpMethods({required this.str});
}
