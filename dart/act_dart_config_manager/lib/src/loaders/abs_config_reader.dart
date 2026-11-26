// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This class reads the raw content of the config files from where a host keeps them.
///
/// The `ConfigLoader` knows which files to read and how to merge them; a reader only knows where
/// the files are. Derive this class to read them from another source (for instance the assets
/// bundle of a Flutter application, or a directory of the file system).
abstract class AbsConfigReader {
  /// Class constructor
  const AbsConfigReader();

  /// Get the location of the config file named [fileName].
  ///
  /// The location is given to [readRaw] and quoted in the errors about the file.
  String locate(String fileName);

  /// Read the raw content of the file at [location].
  ///
  /// The method returns null when the file doesn't exist.
  Future<String?> readRaw(String location);
}
