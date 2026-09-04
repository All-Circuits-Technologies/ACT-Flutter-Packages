// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("UriUtility.formatPathFromSegments", () {
    test("joins the segments with the path separator", () {
      expect(
        UriUtility.formatPathFromSegments(segments: ["api", "v1", "users"]),
        "api/v1/users",
      );
    });

    test("joins the segments with the given separator", () {
      expect(
        UriUtility.formatPathFromSegments(segments: ["a", "b"], separator: "-"),
        "a-b",
      );
    });

    test("replaces the parameters it finds in the path", () {
      expect(
        UriUtility.formatPathFromSegments(
          segments: ["users", ":id", "profile"],
          parameters: {":id": "42"},
        ),
        "users/42/profile",
      );
    });

    test("replaces every occurrence of a parameter", () {
      expect(
        UriUtility.formatPathFromSegments(
          segments: [":id", ":id"],
          parameters: {":id": "42"},
        ),
        "42/42",
      );
    });

    test("leaves an unknown parameter in the path", () {
      expect(
        UriUtility.formatPathFromSegments(segments: ["users", ":id"]),
        "users/:id",
      );
    });

    test("returns an empty path when there is no segment", () {
      expect(UriUtility.formatPathFromSegments(segments: []), "");
    });
  });

  group("UriUtility.formatRelativeUrlPathFromSegments", () {
    test("joins the segments as the path formatting does", () {
      expect(
        UriUtility.formatRelativeUrlPathFromSegments(segments: ["api", "users"]),
        "api/users",
      );
    });

    test("encodes the characters which are not allowed in a url", () {
      expect(
        UriUtility.formatRelativeUrlPathFromSegments(segments: ["a b", "c"]),
        "a%20b/c",
      );
    });

    test("encodes the value a parameter was replaced with", () {
      expect(
        UriUtility.formatRelativeUrlPathFromSegments(
          segments: [":name"],
          parameters: {":name": "a name"},
        ),
        "a%20name",
      );
    });
  });

  group("UriUtility.appendPathSegmentsToUri", () {
    test("adds the segments after the ones of the reference", () {
      expect(
        UriUtility.appendPathSegmentsToUri(
          reference: Uri.parse("https://example.com/api"),
          segmentsToAppend: ["v1", "users"],
        ).toString(),
        "https://example.com/api/v1/users",
      );
    });

    test("keeps the scheme, the host and the port of the reference", () {
      final uri = UriUtility.appendPathSegmentsToUri(
        reference: Uri.parse("https://example.com:8443/api"),
        segmentsToAppend: ["v1"],
      );

      expect(uri.scheme, "https");
      expect(uri.host, "example.com");
      expect(uri.port, 8443);
    });

    test("keeps the query parameters of the reference", () {
      final uri = UriUtility.appendPathSegmentsToUri(
        reference: Uri.parse("https://example.com/api?page=1&page=2&size=10"),
        segmentsToAppend: ["users"],
      );

      expect(uri.queryParametersAll, {
        "page": ["1", "2"],
        "size": ["10"],
      });
    });

    test("keeps the fragment of the reference", () {
      final uri = UriUtility.appendPathSegmentsToUri(
        reference: Uri.parse("https://example.com/api#section"),
        segmentsToAppend: ["users"],
      );

      expect(uri.fragment, "section");
    });

    test("returns the same path when there is nothing to append", () {
      expect(
        UriUtility.appendPathSegmentsToUri(
          reference: Uri.parse("https://example.com/api"),
          segmentsToAppend: [],
        ).path,
        "/api",
      );
    });
  });

  group("UriUtility.isHttpsUri", () {
    test("returns true for a secured url", () {
      expect(UriUtility.isHttpsUri(Uri.parse("https://example.com")), isTrue);
    });

    test("returns false for a plain url", () {
      expect(UriUtility.isHttpsUri(Uri.parse("http://example.com")), isFalse);
    });

    test("ignores the case of the scheme", () {
      expect(UriUtility.isHttpsUri(Uri.parse("HTTPS://example.com")), isTrue);
    });
  });
}
