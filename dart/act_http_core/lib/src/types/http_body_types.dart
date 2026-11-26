// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

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
  json,

  /// The body is a list of files represented as MultipartFile
  files,
}
