// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Constants for common file extensions used in file transfers
sealed class FileExtensions {
  /// This is the file extension for ZIP files
  static const String zip = 'zip';

  /// This is the file extension for CSV files
  static const String csv = 'csv';

  /// This is the file extension for JSON files
  static const String json = 'json';

  /// This is the file extension for XML files
  static const String xml = 'xml';

  /// Returns the file extension with a leading dot.
  static String getFileExtensionWithDot(String extension) => '.$extension';
}
