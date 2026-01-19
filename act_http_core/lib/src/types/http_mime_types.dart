// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_http_core/act_http_core.dart';

/// The mime types managed by this package
enum HttpMimeTypes with MixinStringValueType {
  /// No mime types
  empty(stringValueOverride: "", bodyType: HttpBodyTypes.none),

  /// This is a csv text mime type
  csvText(stringValueOverride: "text/csv", bodyType: HttpBodyTypes.binary),

  /// This is a plain text mime type
  plainText(stringValueOverride: "text/plain", bodyType: HttpBodyTypes.string),

  /// This is a json mime type
  json(stringValueOverride: "application/json", bodyType: HttpBodyTypes.json),

  /// This is an application gzip mime type
  gzip(stringValueOverride: "application/gzip", bodyType: HttpBodyTypes.binary),

  /// This is a form url encoded mime type
  formUrlEncoded(
    stringValueOverride: "application/x-www-form-urlencoded",
    bodyType: HttpBodyTypes.mapStringString,
  ),

  /// This is an application octet stream mime type
  applicationOctetStream(
    stringValueOverride: "application/octet-stream",
    bodyType: HttpBodyTypes.binary,
  ),

  /// This is a multipart form data mime type
  multipartFormData(stringValueOverride: "multipart/form-data", bodyType: HttpBodyTypes.binary);

  /// {@macro act_dart_utility.MixinStringValueType.stringValueOverride}
  @override
  final String? stringValueOverride;

  /// The body type associated to this mime type
  final HttpBodyTypes bodyType;

  /// Class constructor
  const HttpMimeTypes({required this.stringValueOverride, required this.bodyType});

  /// Get the default [HttpMimeTypes] for the given [bodyType]
  static HttpMimeTypes getDefaultValueByBodyType(HttpBodyTypes bodyType) => switch (bodyType) {
    HttpBodyTypes.none => HttpMimeTypes.empty,
    HttpBodyTypes.string => HttpMimeTypes.plainText,
    HttpBodyTypes.json => HttpMimeTypes.json,
    HttpBodyTypes.mapStringString => HttpMimeTypes.formUrlEncoded,
    HttpBodyTypes.binary => HttpMimeTypes.applicationOctetStream,
    HttpBodyTypes.files => HttpMimeTypes.multipartFormData,
  };

  /// Parse the [HttpMimeTypes] from the [value] given.
  ///
  /// Return null if [value] is null or unknown
  static HttpMimeTypes? parseFromValue(String? value) =>
      MixinStringValueType.tryToParseFromStringValue(value: value, values: values);
}
