// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_core/act_http_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HttpMimeTypes.stringValue", () {
    test("returns the mime type as a server writes it", () {
      expect(HttpMimeTypes.json.stringValue, "application/json");
      expect(HttpMimeTypes.plainText.stringValue, "text/plain");
      expect(HttpMimeTypes.formUrlEncoded.stringValue, "application/x-www-form-urlencoded");
    });

    test("gives an empty value to the absence of a mime type", () {
      expect(HttpMimeTypes.empty.stringValue, "");
    });
  });

  group("HttpMimeTypes.bodyType", () {
    test("says how the body of each mime type is carried", () {
      expect(HttpMimeTypes.empty.bodyType, HttpBodyTypes.none);
      expect(HttpMimeTypes.json.bodyType, HttpBodyTypes.json);
      expect(HttpMimeTypes.plainText.bodyType, HttpBodyTypes.string);
      expect(HttpMimeTypes.gzip.bodyType, HttpBodyTypes.binary);
      expect(HttpMimeTypes.formUrlEncoded.bodyType, HttpBodyTypes.mapStringString);
    });
  });

  group("HttpMimeTypes.getDefaultValueByBodyType", () {
    test("returns a mime type for every body type", () {
      for (final bodyType in HttpBodyTypes.values) {
        expect(HttpMimeTypes.getDefaultValueByBodyType(bodyType), isNotNull);
      }
    });

    test("returns the usual mime type of each body type", () {
      expect(HttpMimeTypes.getDefaultValueByBodyType(HttpBodyTypes.none), HttpMimeTypes.empty);
      expect(HttpMimeTypes.getDefaultValueByBodyType(HttpBodyTypes.json), HttpMimeTypes.json);
      expect(
        HttpMimeTypes.getDefaultValueByBodyType(HttpBodyTypes.binary),
        HttpMimeTypes.applicationOctetStream,
      );
      expect(
        HttpMimeTypes.getDefaultValueByBodyType(HttpBodyTypes.files),
        HttpMimeTypes.multipartFormData,
      );
    });
  });

  group("HttpMimeTypes.parseFromValue", () {
    test("finds the mime type named by the value", () {
      expect(HttpMimeTypes.parseFromValue("application/json"), HttpMimeTypes.json);
    });

    test("ignores the case of the value", () {
      expect(HttpMimeTypes.parseFromValue("APPLICATION/JSON"), HttpMimeTypes.json);
    });

    test("returns null when the value names no mime type", () {
      expect(HttpMimeTypes.parseFromValue("application/xml"), isNull);
    });

    test("returns null when the value is null", () {
      expect(HttpMimeTypes.parseFromValue(null), isNull);
    });

    test("reads an empty value as the absence of a mime type", () {
      expect(HttpMimeTypes.parseFromValue(""), HttpMimeTypes.empty);
    });
  });
}
