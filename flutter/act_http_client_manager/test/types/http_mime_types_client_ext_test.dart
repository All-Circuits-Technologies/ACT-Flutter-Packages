// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_http_core/act_http_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HttpMimeTypesClientExt.toMediaType", () {
    test("builds the media type a MIME type names", () {
      final mediaType = HttpMimeTypes.json.toMediaType();

      expect(mediaType.type, "application");
      expect(mediaType.subtype, "json");
    });

    test("adds the parameters the caller asked for", () {
      final mediaType = HttpMimeTypes.plainText.toMediaType(parameters: {"charset": "utf-8"});

      expect(mediaType.toString(), "text/plain; charset=utf-8");
    });

    test("carries no parameter when the caller asked for none", () {
      final mediaType = HttpMimeTypes.plainText.toMediaType();

      expect(mediaType.parameters, isEmpty);
    });
  });
}
