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

  /// This is the file extension for the rauc binary file
  static const String raucBinary = "raucb";

  /// This is the file extension for tar files
  static const String tar = "tar";

  /// This is the file extension for gz files
  static const String gz = "gz";

  /// This is the file extension for tar.gz files
  static const String tarGz = "$tar.$gz";

  /// This is the file extension for tgz files (tgz is a common shorthand for tar.gz)
  static const String tgz = "tgz";

  /// Returns the file extension with a leading dot.
  static String getFileExtensionWithDot(String extension) => '.$extension';
}
