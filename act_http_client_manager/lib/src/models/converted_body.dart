// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';
import 'dart:typed_data';

import 'package:act_http_core/act_http_core.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:equatable/equatable.dart';

/// Contains the request body which can be used by the external http lib
class ConvertedBody extends Equatable {
  /// The converted body and usable by the external http lib
  final Object? body;

  /// The [HttpMimeTypes] of the body
  final HttpMimeTypes contentType;

  /// Default class constructor
  const ConvertedBody({
    required this.body,
    required this.contentType,
  });

  /// Creates a string body
  const ConvertedBody.string({
    required String this.body,
  }) : contentType = HttpMimeTypes.plainText;

  /// Creates a formUrlEncoded body
  const ConvertedBody.formUrlEncoded({
    required Map<String, String> this.body,
  }) : contentType = HttpMimeTypes.formUrlEncoded;

  /// Creates a multipart form data body, from an [Uint8List]
  const ConvertedBody.multipartFormData({
    required Uint8List this.body,
  }) : contentType = HttpMimeTypes.multipartFormData;

  /// Creates a multipart form data body, from an int [List]
  ConvertedBody.multipartFormDataIntList({
    required List<int> body,
  })  : contentType = HttpMimeTypes.multipartFormData,
        body = Uint8List.fromList(body);

  /// Creates an empty body
  const ConvertedBody.empty()
      : body = null,
        contentType = HttpMimeTypes.empty;

  /// Try to parse a json object to a json encoded [String]
  static ConvertedBody? tryParseJson(
    // We use a dynamic value here because we get it from a json
    // ignore: avoid_annotating_with_dynamic
    dynamic body, {
    required LogsHelper logsHelper,
  }) {
    String? bodyStr;

    try {
      bodyStr = jsonEncode(body);
    } catch (error) {
      logsHelper.w("A problem occurred when tried to stringify the request JSON body");
    }

    if (bodyStr == null) {
      return null;
    }

    return ConvertedBody(body: bodyStr, contentType: HttpMimeTypes.json);
  }

  @override
  List<Object?> get props => [body, contentType];
}
