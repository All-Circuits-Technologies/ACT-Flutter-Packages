// SPDX-FileCopyrightText: 2025 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';
import 'dart:ui';

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_remote_local_vers_file_manager/src/constants/remote_local_vers_file_constants.dart'
    as server_local_vers_file_constants;
import 'package:act_remote_local_vers_file_manager/src/utilities/localized_file_utility.dart';
import 'package:act_remote_local_vers_file_manager/src/utilities/versioned_file_utility.dart';
import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as path;

/// This pseudo-class contains localized and versioned file helper static functions.
///
/// {@template act_remote_local_vers_file_manager.LocalizedVersionedFileUtility.serverRequirements}
/// Localized and versioned files are expected to follow a specific filesystem layout:
/// - they must be handled within a dedicated folder
/// - Such folder must contain one sub-folder per locale, joined with underscore and lowercase
/// - Per-locale sub-folder must contain a "current" stamp file as well as wanted sibling file
///   whose name is computed from the content of "current" stamp file.
///
/// Example:
/// - my_file/fr_fr/current   # ex: "v2"
/// - my_file/fr_fr/v1.md
/// - my_file/fr_fr/v2.md
/// - my_file/en_us/...
/// {@endtemplate}
sealed class LocalizedVersionedFileUtility {
  /// Fetch current version of a localized and versioned file.
  ///
  /// That is, read "version" file within [storage] [dirId] $locale folder, optionally caching
  /// result using [cacheVersion].
  static Future<
      ({
        StorageRequestResult result,
        ({Locale locale, String version})? data,
      })> getFileLocalizedCurrentVersion({
    required AbsRemoteStorageManager storage,
    required String dirId,
    required List<Locale> locales,
    required bool cacheVersion,
    required LogsHelper logsHelper,
  }) async {
    // Peek versioned file unconditionally (even with explicit version) since it is the entry point
    // to search sibling final file.
    final localizedVersionResult = await LocalizedFileUtility.getLocalizedFile(
      storage: storage,
      dirId: dirId,
      fileName: server_local_vers_file_constants.currentVersionStampFileName,
      locales: locales,
      useCache: cacheVersion,
      logsHelper: logsHelper,
    );

    if (localizedVersionResult.result != StorageRequestResult.success) {
      return (result: localizedVersionResult.result, data: null);
    }

    if (localizedVersionResult.data == null) {
      logsHelper.e("A successful localized file utility result should always have a valid data");
      assert(false, "Should never fire");
      return (result: StorageRequestResult.genericError, data: null);
    }

    final currentVersionResult = await VersionedFileUtility.getFileCurrentVersion(
      storage: storage,
      dirId: path.dirname(localizedVersionResult.data!.filePath),
      cacheVersion: cacheVersion,
      logsHelper: logsHelper,
    );

    if (currentVersionResult.requestResult != StorageRequestResult.success) {
      return (result: currentVersionResult.requestResult, data: null);
    }

    return (
      result: StorageRequestResult.success,
      data: (
        locale: localizedVersionResult.data!.locale,
        version: currentVersionResult.version!,
      ),
    );
  }

  /// Get a localized and versioned file within [dirId] of [storage].
  ///
  /// That is:
  /// - find first localized "current" file within [storage] [dirId]
  ///    (first "$locale/current" file based on sorted [locales],
  ///     with $locale in "en_us" format, underscore, lowercase),
  /// - find sibling versioned file, from [explicitVersion] or from "current" version
  ///
  /// Sibling file name is computed from version to fetch using [versionToFileName].
  static Future<
      ({
        StorageRequestResult result,
        ({Locale locale, String version, String filePath, File file})? data,
      })> getLocalizedVersionedFile({
    required AbsRemoteStorageManager storage,
    required String dirId,
    required String Function(String) versionToFileName,
    required List<Locale> locales,
    String? explicitVersion,
    required bool cacheVersion,
    required bool cacheFile,
    required LogsHelper logsHelper,
  }) async {
    // Peek versioned file unconditionally (even with explicit version) since it is the entry point
    // to search sibling final file.
    final localizedVersionResult = await LocalizedFileUtility.getLocalizedFile(
      storage: storage,
      dirId: dirId,
      fileName: server_local_vers_file_constants.currentVersionStampFileName,
      locales: locales,
      useCache: cacheVersion,
      logsHelper: logsHelper,
    );

    if (localizedVersionResult.result != StorageRequestResult.success) {
      return (result: localizedVersionResult.result, data: null);
    }

    if (localizedVersionResult.data == null) {
      logsHelper.e("A successful localized file utility result should always have a valid data");
      assert(false, "Should never fire");
      return (result: StorageRequestResult.genericError, data: null);
    }

    // Note that we always override version in order to save a useless fetch call since
    // current version file is already fetched just above.
    final versionedFileResult = await VersionedFileUtility.getVersionedFile(
      storage: storage,
      dirId: path.dirname(localizedVersionResult.data!.filePath),
      versionToFileName: versionToFileName,
      cacheVersion: cacheVersion,
      cacheFile: cacheFile,
      versionOverride:
          explicitVersion ?? (await localizedVersionResult.data!.file.readAsString()).trim(),
      logsHelper: logsHelper,
    );

    if (versionedFileResult.result != StorageRequestResult.success) {
      return (result: versionedFileResult.result, data: null);
    }

    if (versionedFileResult.data == null) {
      logsHelper.e("A successful versioned file utility result should always have a valid data");
      assert(false, "Should never fire");
      return (result: StorageRequestResult.genericError, data: null);
    }

    return (
      result: StorageRequestResult.success,
      data: (
        locale: localizedVersionResult.data!.locale,
        version: versionedFileResult.data!.version,
        filePath: versionedFileResult.data!.filePath,
        file: versionedFileResult.data!.file,
      ),
    );
  }
}
