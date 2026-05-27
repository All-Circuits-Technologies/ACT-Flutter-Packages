// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:equatable/equatable.dart';

/// This class represents a semantic version, as defined in https://semver.org/
class SemanticVersion extends Equatable {
  /// This is the regular expression used to parse a semantic version string.
  /// See: https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
  static final regexExp = RegExp(
    r"^(?<major>0|[1-9]\d*)\.(?<minor>0|[1-9]\d*)\.(?<patch>0|[1-9]\d*)"
    r"(?:-(?<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)"
    r"(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?"
    r"(?:\+(?<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$",
  );

  /// This is the key to extract the major version number from the regular expression match.
  static const majorRegexKey = "major";

  /// This is the key to extract the minor version number from the regular expression match.
  static const minorRegexKey = "minor";

  /// This is the key to extract the patch version number from the regular expression match.
  static const patchRegexKey = "patch";

  /// This is the key to extract the prerelease version string from the regular expression match.
  static const prereleaseRegexKey = "prerelease";

  /// This is the key to extract the build metadata string from the regular expression match.
  static const buildMetadataRegexKey = "buildmetadata";

  /// The separator used to separate the major, minor and patch version numbers.
  static const majorMinorPatchSeparator = ".";

  /// The separator used to separate the prerelease version from the main version.
  static const prereleaseSeparator = "-";

  /// The separator used to separate the build metadata from the main version.
  static const buildMetadataSeparator = "+";

  /// The major version number.
  final int major;

  /// The minor version number.
  final int minor;

  /// The patch version number.
  final int patch;

  /// The prerelease version string, if any.
  final String? prerelease;

  /// The build metadata string, if any.
  final String? buildMetadata;

  /// Class constructor
  const SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.prerelease,
    this.buildMetadata,
  });

  /// Create a copy of this semantic version with the given properties replaced by the new values.
  SemanticVersion copyWith({
    int? major,
    int? minor,
    int? patch,
    String? prerelease,
    bool forcePrereleaseValue = false,
    String? buildMetadata,
    bool forceBuildMetadataValue = false,
  }) => SemanticVersion(
    major: major ?? this.major,
    minor: minor ?? this.minor,
    patch: patch ?? this.patch,
    prerelease: prerelease ?? (forcePrereleaseValue ? null : this.prerelease),
    buildMetadata: buildMetadata ?? (forceBuildMetadataValue ? null : this.buildMetadata),
  );

  /// Convert this semantic version to a string.
  ///
  /// The [includePrerelease] and [includeBuildMetadata] parameters control whether the prerelease
  /// and build metadata parts are included in the resulting string, respectively.
  ///
  /// By default, both parts are included if they are present.
  @override
  String toString({bool includePrerelease = true, bool includeBuildMetadata = true}) {
    var prereleasePart = "";
    var buildMetadataPart = "";

    if (includePrerelease && prerelease != null) {
      prereleasePart = "$prereleaseSeparator$prerelease";
    }

    if (includeBuildMetadata && buildMetadata != null) {
      buildMetadataPart = "$buildMetadataSeparator$buildMetadata";
    }

    return "$major$majorMinorPatchSeparator$minor$majorMinorPatchSeparator$patch"
        "$prereleasePart$buildMetadataPart";
  }

  /// Try to parse a semantic version from the given string.
  ///
  /// If the string does not contain a valid semantic version, null is returned.
  static SemanticVersion? tryToParse(String source, {MixinActLogger? logger}) {
    final match = regexExp.firstMatch(source);

    if (match == null) {
      return null;
    }

    final major = _tryParseInt(match.namedGroup(majorRegexKey));
    final minor = _tryParseInt(match.namedGroup(minorRegexKey));
    final patch = _tryParseInt(match.namedGroup(patchRegexKey));
    final prerelease = match.namedGroup(prereleaseRegexKey);
    final buildMetadata = match.namedGroup(buildMetadataRegexKey);

    if (major == null || minor == null || patch == null) {
      logger?.w(
        "The string given: '$source' does not contain a valid semantic version (invalid major, "
        "minor or patch version number)",
      );
      return null;
    }

    return SemanticVersion(
      major: major,
      minor: minor,
      patch: patch,
      prerelease: prerelease,
      buildMetadata: buildMetadata,
    );
  }

  /// Try to parse an integer from the given string.
  ///
  /// If the string is null or does not contain a valid integer, null is returned.
  static int? _tryParseInt(String? value) {
    if (value == null) {
      return null;
    }
    return int.tryParse(value);
  }

  /// Class properties
  @override
  List<Object?> get props => [major, minor, patch, prerelease, buildMetadata];
}
