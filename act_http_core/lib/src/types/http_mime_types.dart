// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';

/// The mime types managed by this package
enum HttpMimeTypes with MixinStringValueType {
  /// No mime types
  empty(stringValueOverride: ""),

  /// This is a plain text mime type
  plainText(stringValueOverride: "text/plain"),

  /// This is a json mime types
  json(stringValueOverride: "application/json"),

  /// This is a form url encoded mime type
  formUrlEncoded(stringValueOverride: "application/x-www-form-urlencoded"),

  /// This is a multipart form data mime type
  multipartFormData(stringValueOverride: "multipart/form-data");

  /// {@macro act_dart_utility.MixinStringValueType.stringValueOverride}
  @override
  final String? stringValueOverride;

  /// Class constructor
  const HttpMimeTypes({required this.stringValueOverride});

  /// Parse the [HttpMimeTypes] from the [value] given.
  ///
  /// Return null if [value] is null or unknown
  static HttpMimeTypes? parseFromValue(String? value) =>
      MixinStringValueType.tryToParseFromStringValue(value: value, values: values);
}
