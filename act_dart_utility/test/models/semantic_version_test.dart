// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("SemanticVersion.tryToParse", () {
    test("reads the major, the minor and the patch numbers", () {
      final version = SemanticVersion.tryToParse("1.2.3");

      expect(version, const SemanticVersion(major: 1, minor: 2, patch: 3));
    });

    test("reads the prerelease part", () {
      final version = SemanticVersion.tryToParse("1.2.3-alpha.1");

      expect(version!.prerelease, "alpha.1");
      expect(version.buildMetadata, isNull);
    });

    test("reads the build metadata part", () {
      final version = SemanticVersion.tryToParse("1.2.3+build.42");

      expect(version!.buildMetadata, "build.42");
      expect(version.prerelease, isNull);
    });

    test("reads both optional parts at once", () {
      final version = SemanticVersion.tryToParse("1.2.3-rc.1+build.42");

      expect(version!.prerelease, "rc.1");
      expect(version.buildMetadata, "build.42");
    });

    test("accepts a version made of zeros", () {
      expect(SemanticVersion.tryToParse("0.0.0"), const SemanticVersion(major: 0, minor: 0, patch: 0));
    });

    test("returns null when a part is missing", () {
      expect(SemanticVersion.tryToParse("1.2"), isNull);
    });

    test("returns null when a number has a leading zero", () {
      expect(SemanticVersion.tryToParse("01.2.3"), isNull);
    });

    test("returns null when a number is not a number", () {
      expect(SemanticVersion.tryToParse("1.2.x"), isNull);
    });

    test("returns null when the version is prefixed", () {
      expect(SemanticVersion.tryToParse("v1.2.3"), isNull);
    });

    test("returns null for an empty value", () {
      expect(SemanticVersion.tryToParse(""), isNull);
    });

    test("warns through the logger when the value is not a version", () {
      final logger = FakeLogger();

      SemanticVersion.tryToParse("not a version", logger: logger);

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("logs nothing when the value is a version", () {
      final logger = FakeLogger();

      SemanticVersion.tryToParse("1.2.3", logger: logger);

      expect(logger.records, isEmpty);
    });
  });

  group("SemanticVersion.toString", () {
    test("writes the three numbers separated by dots", () {
      expect(const SemanticVersion(major: 1, minor: 2, patch: 3).toString(), "1.2.3");
    });

    test("appends the prerelease and the build metadata by default", () {
      const version = SemanticVersion(
        major: 1,
        minor: 2,
        patch: 3,
        prerelease: "rc.1",
        buildMetadata: "build.42",
      );

      expect(version.toString(), "1.2.3-rc.1+build.42");
    });

    test("leaves the prerelease out when it is asked to", () {
      const version = SemanticVersion(major: 1, minor: 2, patch: 3, prerelease: "rc.1");

      expect(version.toString(includePrerelease: false), "1.2.3");
    });

    test("leaves the build metadata out when it is asked to", () {
      const version = SemanticVersion(major: 1, minor: 2, patch: 3, buildMetadata: "build.42");

      expect(version.toString(includeBuildMetadata: false), "1.2.3");
    });

    test("is read back by the parsing", () {
      const version = SemanticVersion(
        major: 1,
        minor: 2,
        patch: 3,
        prerelease: "rc.1",
        buildMetadata: "build.42",
      );

      expect(SemanticVersion.tryToParse(version.toString()), version);
    });
  });

  group("SemanticVersion.copyWith", () {
    test("keeps the parts which are not given", () {
      const version = SemanticVersion(major: 1, minor: 2, patch: 3, prerelease: "rc.1");

      expect(version.copyWith(), version);
    });

    test("replaces the numbers it is given", () {
      const version = SemanticVersion(major: 1, minor: 2, patch: 3);

      expect(
        version.copyWith(minor: 5),
        const SemanticVersion(major: 1, minor: 5, patch: 3),
      );
    });

    test("drops the prerelease when it is forced without a new one", () {
      const version = SemanticVersion(major: 1, minor: 2, patch: 3, prerelease: "rc.1");

      expect(version.copyWith(forcePrereleaseValue: true).prerelease, isNull);
    });

    test("drops the build metadata when it is forced without a new one", () {
      const version = SemanticVersion(major: 1, minor: 2, patch: 3, buildMetadata: "build.42");

      expect(version.copyWith(forceBuildMetadataValue: true).buildMetadata, isNull);
    });

    test("keeps the new prerelease even when the drop is forced", () {
      const version = SemanticVersion(major: 1, minor: 2, patch: 3, prerelease: "rc.1");

      expect(
        version.copyWith(prerelease: "rc.2", forcePrereleaseValue: true).prerelease,
        "rc.2",
      );
    });
  });

  group("SemanticVersion equality", () {
    test("considers two versions with the same parts as equal", () {
      expect(
        const SemanticVersion(major: 1, minor: 2, patch: 3),
        const SemanticVersion(major: 1, minor: 2, patch: 3),
      );
    });

    test("considers two versions with different numbers as different", () {
      expect(
        const SemanticVersion(major: 1, minor: 2, patch: 3),
        isNot(const SemanticVersion(major: 1, minor: 2, patch: 4)),
      );
    });

    test("considers the prerelease and the build metadata as part of the version", () {
      expect(
        const SemanticVersion(major: 1, minor: 2, patch: 3),
        isNot(const SemanticVersion(major: 1, minor: 2, patch: 3, prerelease: "rc.1")),
      );
      expect(
        const SemanticVersion(major: 1, minor: 2, patch: 3),
        isNot(const SemanticVersion(major: 1, minor: 2, patch: 3, buildMetadata: "build.42")),
      );
    });
  });
}
