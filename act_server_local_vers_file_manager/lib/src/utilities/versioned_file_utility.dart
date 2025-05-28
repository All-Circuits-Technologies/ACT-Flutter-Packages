// SPDX-FileCopyrightText: 2025 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_server_storage_manager/act_server_storage_manager.dart';

/// This pseudo-class contains versioned file helper static functions.
///
/// Versioned files are expected to follow a specific filesystem layout:
/// - they must be handled within a dedicated folder
/// - Such folder must contain a "current" stamp file as well as wanted sibling file
///   whose name is computed from the content of "current" stamp file.
///
/// Example:
/// - my_file/current   # ex: "v2"
/// - my_file/v1.md
/// - my_file/v2.md
sealed class VersionedFileUtility {
  /// Name of stamp file used to hold current active version
  static const String currentVersionStampFileName = "current";

  /// Get a versioned file within [storage] [dirId] folder.
  ///
  /// Name of the file to find is computed from its version using [versionToFileName].
  /// An explicit [versionOverride] can be given to retrieve this version of the file instead of
  /// current version of it. This can also be used as an accelerator when caller already know
  /// the current version, saving one read operation.
  ///
  /// Result can be cached or not by [storage] using [cacheVersion] and [cacheFile] which
  /// respectively enable caching of the content of "current" file or of result versioned file.
  static Future<
      ({
        StorageRequestResult result,
        ({String version, String filePath, File file})? data,
      })> getVersionedFile({
    required AbsServerStorageManager storage,
    required String dirId,
    required String Function(String) versionToFileName,
    String? versionOverride,
    required bool cacheVersion,
    required bool cacheFile,
  }) async {
    var versionToFetch = versionOverride;

    // Conditionally fetch current version from storage server
    if (versionToFetch == null) {
      final versionRequestResult = await getFileCurrentVersion(
        storage: storage,
        dirId: dirId,
        useCache: cacheVersion,
      );

      if (versionRequestResult.requestResult != StorageRequestResult.success) {
        return (result: versionRequestResult.requestResult, data: null);
      }

      versionToFetch = versionRequestResult.version;
    }

    if (versionToFetch == null) {
      assert(false, "Should never fire");
      return (result: StorageRequestResult.genericError, data: null);
    }

    // Fetched versioned file
    final versionedFileName = versionToFileName(versionToFetch);
    final versionedFilePath = "$dirId/$versionedFileName";
    final fileFetchResult = await storage.getFile(
      versionedFilePath,
      useCache: cacheFile,
    );

    if (fileFetchResult.result != StorageRequestResult.success) {
      return (result: fileFetchResult.result, data: null);
    }

    if (fileFetchResult.file == null) {
      assert(false, "Should never fire");
      return (result: StorageRequestResult.genericError, data: null);
    }

    return (
      result: StorageRequestResult.success,
      data: (
        version: versionToFetch,
        filePath: versionedFilePath,
        file: fileFetchResult.file!,
      ),
    );
  }

  /// Fetch current version of a versioned file.
  ///
  /// That is, read "version" file within [storage] [dirId] folder, optionally caching result
  /// using [useCache].
  static Future<
      ({
        StorageRequestResult requestResult,
        String? version,
      })> getFileCurrentVersion({
    required AbsServerStorageManager storage,
    required String dirId,
    required bool useCache,
  }) async {
    // Get "current" file, fail upon any issue
    final requestResult = await storage.getFile(
      "$dirId/$currentVersionStampFileName",
      useCache: useCache,
    );

    if (requestResult.result != StorageRequestResult.success) {
      return (requestResult: requestResult.result, version: null);
    }

    if (requestResult.file == null) {
      assert(false, "Should never fire");
      return (requestResult: StorageRequestResult.genericError, version: null);
    }

    // Read "current" file, fail upon any issue
    final version = await requestResult.file!.readAsString();

    if (version.isEmpty) {
      return (requestResult: StorageRequestResult.genericError, version: null);
    }

    // Success
    return (
      requestResult: StorageRequestResult.success,
      version: version,
    );
  }
}
