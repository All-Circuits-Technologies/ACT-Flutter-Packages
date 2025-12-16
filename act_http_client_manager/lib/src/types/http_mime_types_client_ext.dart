// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_core/act_http_core.dart';
import 'package:http/http.dart' show MediaType;

/// This extends the MIME types features for the client library
extension HttpMimeTypesClientExt on HttpMimeTypes {
  /// Create a media type from the Mime Type
  MediaType toMediaType({
    Map<String, String>? parameters,
  }) {
    final type = MediaType.parse(stringValue);
    type.change(clearParameters: true, parameters: parameters);
    return type;
  }
}
