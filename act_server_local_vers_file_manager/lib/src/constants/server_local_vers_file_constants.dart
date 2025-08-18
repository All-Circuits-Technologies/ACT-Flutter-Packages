// SPDX-FileCopyrightText: 2025 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This class centralizes package constants
library;

/// We use underscores as stringified locale codes separator.
/// Ex: American english locale variant would be named "en_us".
const localeCodesSep = "_";

/// Name of stamp file used to hold current active version of a versioned file
const currentVersionStampFileName = "current.txt";

/// This defines a function to parse a version string into a file name.
typedef VersionToFileNameParser = String Function(String version);
