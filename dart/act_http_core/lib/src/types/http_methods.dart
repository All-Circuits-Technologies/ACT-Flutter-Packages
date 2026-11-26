// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';

/// The available HTTP methods
enum HttpMethods with MixinStringValueType {
  /// Connect http method
  connect(stringValueOverride: "CONNECT"),

  /// Delete http method
  delete(stringValueOverride: "DELETE"),

  /// Get http method
  get(stringValueOverride: "GET", isSafe: true),

  /// Head http method
  head(stringValueOverride: "HEAD", isSafe: true),

  /// Options http method
  options(stringValueOverride: "OPTIONS", isSafe: true),

  /// Post http method
  post(stringValueOverride: "POST"),

  /// Put http method
  put(stringValueOverride: "PUT"),

  /// Trace http method
  trace(stringValueOverride: "TRACE", isSafe: true),

  /// Patch http method
  patch(stringValueOverride: "PATCH");

  /// {@macro act_dart_utility.MixinStringValueType.stringValueOverride}
  @override
  final String? stringValueOverride;

  /// If true, it means that the method can update information in the server and it's not safe to
  /// call it without knowing what you are doing.
  final bool isSafe;

  /// Class constructor
  const HttpMethods({this.stringValueOverride, this.isSafe = false});

  /// Parse the [HttpMethods] from the [value] given.
  ///
  /// Return null if [value] is null or unknown
  static HttpMethods? parseFromValue(String? value) =>
      MixinStringValueType.tryToParseFromStringValue(value: value, values: values);
}
