// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

/// The different types of HTTP body we can have
enum HttpBodyTypes {
  /// No body
  none,

  /// The body is a String
  string,

  /// The body is an Uint8List or List\<int\>
  binary,

  /// The body is a Map\<String, String\>
  mapStringString,

  /// The body is a JSON object represented as a String (which can be decoded to a
  /// Map\<String, dynamic\> or a List\<dynamic\>)
  json;

  /// Tries to guess the body type based on its runtime type
  /// Returns null if the body type is not recognized
  // The body is of unknown type that's why is of dynamic type
  // ignore: avoid_annotating_with_dynamic
  static HttpBodyTypes? tryToGuessBodyType(dynamic body) {
    // We use a for and a switch to be sure we receive an error if we add a new type and don't
    // handle it here
    for (final value in HttpBodyTypes.values) {
      switch (value) {
        case HttpBodyTypes.none:
          if (body == null) {
            return HttpBodyTypes.none;
          }
          break;
        case HttpBodyTypes.string:
          if (body is String) {
            return HttpBodyTypes.string;
          }
          break;
        case HttpBodyTypes.binary:
          if (body is Uint8List || body is List<int>) {
            return HttpBodyTypes.binary;
          }
          break;
        case HttpBodyTypes.mapStringString:
          if (body is Map<String, String>) {
            return HttpBodyTypes.mapStringString;
          }
          break;
        case HttpBodyTypes.json:
          if (body is Map<String, dynamic> || body is List<dynamic>) {
            return HttpBodyTypes.json;
          }
          break;
      }
    }

    return null;
  }
}
