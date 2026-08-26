// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_core/act_http_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("HeaderUtilities.formatHeaderValue", () {
    test("writes a value without any key as it is", () {
      expect(
        HeaderUtilities.formatHeaderValue(values: const [(value: "attachment", key: null)]),
        "attachment",
      );
    });

    test("joins a key and its value with an equal sign", () {
      expect(
        HeaderUtilities.formatHeaderValue(
          values: const [
            (value: "attachment", key: null),
            (value: "filename.jpg", key: "filename"),
          ],
        ),
        "attachment; filename=filename.jpg",
      );
    });

    test("joins the values with the given separator", () {
      expect(
        HeaderUtilities.formatHeaderValue(
          values: const [(value: "a", key: null), (value: "b", key: null)],
          valuesSeparator: ", ",
        ),
        "a, b",
      );
    });

    test("returns an empty value when there is nothing to write", () {
      expect(HeaderUtilities.formatHeaderValue(values: const []), "");
    });
  });

  group("HeaderUtilities.parseHeaderValue", () {
    test("reads a value without any key", () {
      expect(HeaderUtilities.parseHeaderValue(value: "attachment"), const [
        (value: "attachment", key: null),
      ]);
    });

    test("reads the keys and the values", () {
      expect(
        HeaderUtilities.parseHeaderValue(value: "attachment; filename=filename.jpg"),
        const [(value: "attachment", key: null), (value: "filename.jpg", key: "filename")],
      );
    });

    test("trims the spaces around the keys and the values", () {
      expect(HeaderUtilities.parseHeaderValue(value: "  a  =  b  "), const [
        (value: "b", key: "a"),
      ]);
    });

    test("removes the double quotes around a value", () {
      expect(
        HeaderUtilities.parseHeaderValue(value: 'filename="a file.jpg"'),
        const [(value: "a file.jpg", key: "filename")],
      );
    });

    test("removes the single quotes around a value", () {
      expect(
        HeaderUtilities.parseHeaderValue(value: "filename='a file.jpg'"),
        const [(value: "a file.jpg", key: "filename")],
      );
    });

    test("returns an empty list for an empty value", () {
      expect(HeaderUtilities.parseHeaderValue(value: ""), isEmpty);
    });

    test("splits on the given separator", () {
      expect(
        HeaderUtilities.parseHeaderValue(value: "a=1, b=2", valuesSeparator: ","),
        const [(value: "1", key: "a"), (value: "2", key: "b")],
      );
    });

    test("reads back what the formatting produced", () {
      const values = [
        (value: "attachment", key: null),
        (value: "filename.jpg", key: "filename"),
      ];

      expect(
        HeaderUtilities.parseHeaderValue(
          value: HeaderUtilities.formatHeaderValue(values: values),
        ),
        values,
      );
    });
  });

  group("HeaderUtilities.getHeaderValue", () {
    test("reads the value stored at the header key", () {
      expect(
        HeaderUtilities.getHeaderValue(
          headers: const {"Content-Disposition": "attachment; filename=a.jpg"},
          headerKey: HeaderConstants.contentDispositionHeaderKey,
        ),
        const [(value: "attachment", key: null), (value: "a.jpg", key: "filename")],
      );
    });

    test("finds a header key written in lower case", () {
      expect(
        HeaderUtilities.getHeaderValue(
          headers: const {"content-disposition": "attachment"},
          headerKey: HeaderConstants.contentDispositionHeaderKey,
        ),
        const [(value: "attachment", key: null)],
      );
    });

    test("returns null when the header is not there", () {
      expect(
        HeaderUtilities.getHeaderValue(
          headers: const {},
          headerKey: HeaderConstants.contentDispositionHeaderKey,
        ),
        isNull,
      );
    });

    test("returns an empty list when the header holds no value", () {
      expect(
        HeaderUtilities.getHeaderValue(
          headers: const {"Content-Disposition": ""},
          headerKey: HeaderConstants.contentDispositionHeaderKey,
        ),
        isEmpty,
      );
    });
  });

  group("HeaderUtilities.getFileNameFromHeaders", () {
    test("returns the file name of the content disposition header", () {
      expect(
        HeaderUtilities.getFileNameFromHeaders(
          headers: const {"Content-Disposition": "attachment; filename=a.jpg"},
        ),
        "a.jpg",
      );
    });

    test("removes the quotes around the file name", () {
      expect(
        HeaderUtilities.getFileNameFromHeaders(
          headers: const {"Content-Disposition": 'attachment; filename="a file.jpg"'},
        ),
        "a file.jpg",
      );
    });

    test("returns null when the header is not there", () {
      expect(HeaderUtilities.getFileNameFromHeaders(headers: const {}), isNull);
    });

    test("returns null when the header carries no file name", () {
      expect(
        HeaderUtilities.getFileNameFromHeaders(
          headers: const {"Content-Disposition": "attachment"},
        ),
        isNull,
      );
    });

    test("ignores the encoded file name key, which it does not manage", () {
      expect(
        HeaderUtilities.getFileNameFromHeaders(
          headers: const {"Content-Disposition": "attachment; filename*=UTF-8''a.jpg"},
        ),
        isNull,
      );
    });
  });
}
