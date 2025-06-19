// SPDX-FileCopyrightText: 2025 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This class centralizes package constants
sealed class ServerLocalVersFileConstants {
  /// Storage is expected to support folders, with this separator
  // TODO(aloiseau): get path separator from the storage service
  static const storagePathSep = "/";

  /// We use underscores as stringified locale codes separator.
  /// Ex: American english locale variant would be named "en_us".
  static const localeCodesSep = "_";

  /// Name of stamp file used to hold current active version of a versioned file
  static const currentVersionStampFileName = "current";
}
