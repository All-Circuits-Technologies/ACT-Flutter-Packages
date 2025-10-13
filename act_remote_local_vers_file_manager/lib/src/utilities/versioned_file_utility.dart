// SPDX-FileCopyrightText: 2025 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_remote_local_vers_file_manager/src/constants/remote_local_vers_file_constants.dart'
    as server_local_vers_file_constants;
import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';

/// This pseudo-class contains versioned file helper static functions.
///
/// {@template act_remote_local_vers_file_manager.VersionedFileUtility.serverRequirements}
/// Versioned files are expected to follow a specific filesystem layout:
/// - they must be handled within a dedicated folder
/// - Such folder must contain a "current" stamp file as well as wanted sibling file
///   whose name is computed from the content of "current" stamp file.
///
/// Example:
/// - my_file/current   # ex: "v2"
/// - my_file/v1.md
/// - my_file/v2.md
/// {@endtemplate}
sealed class VersionedFileUtility {
  /// Get a versioned file within [storage] [dirId] folder.
  ///
  /// Name of the file to find is computed from its version using [versionToFileName].
  ///
  /// {@template act_server_local_vers_file_manager.VersionedFileUtility.versionOverride}
  /// An explicit [versionOverride] can be given to retrieve this version of the file instead of
  /// current version of it. This can also be used as an accelerator when caller already know
  /// the current version, saving one read operation.
  /// {@endtemplate}
  ///
  /// Result can be cached or not by [storage] using [cacheVersion] and [cacheFile] which
  /// respectively enable caching of the content of "current" file or of result versioned file.
  static Future<
      ({
        StorageRequestResult result,
        ({String version, String filePath, File file})? data,
      })> getVersionedFile({
    required AbsRemoteStorageManager storage,
    required String dirId,
    required String Function(String) versionToFileName,
    String? versionOverride,
    required bool cacheVersion,
    required bool cacheFile,
    required LogsHelper logsHelper,
  }) async {
    var versionToFetch = versionOverride;

    // Conditionally fetch current version from storage server
    if (versionToFetch == null) {
      final versionRequestResult = await getFileCurrentVersion(
        storage: storage,
        dirId: dirId,
        cacheVersion: cacheVersion,
        logsHelper: logsHelper,
      );

      if (versionRequestResult.requestResult != StorageRequestResult.success) {
        return (result: versionRequestResult.requestResult, data: null);
      }

      versionToFetch = versionRequestResult.version;

      if (versionToFetch == null) {
        logsHelper.e("A successful getFileCurrentVersion call should always return a version");
        assert(false, "Should never fire");
        return (result: StorageRequestResult.genericError, data: null);
      }
    }

    // Fetched versioned file
    final versionedFileName = versionToFileName(versionToFetch);
    final versionedFilePath = [dirId, versionedFileName].join(storage.getPathSeparator());
    final fileFetchResult = await storage.getFile(
      versionedFilePath,
      useCache: cacheFile,
    );

    if (fileFetchResult.result != StorageRequestResult.success) {
      return (result: fileFetchResult.result, data: null);
    }

    if (fileFetchResult.file == null) {
      logsHelper.e("A successful storage download result should always have a file");
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
  /// using [cacheVersion].
  static Future<
      ({
        StorageRequestResult requestResult,
        String? version,
      })> getFileCurrentVersion({
    required AbsRemoteStorageManager storage,
    required String dirId,
    required bool cacheVersion,
    required LogsHelper logsHelper,
  }) async {
    // Get "current" file, fail upon any issue
    final requestResult = await storage.getFile(
      [dirId, server_local_vers_file_constants.currentVersionStampFileName]
          .join(storage.getPathSeparator()),
      useCache: cacheVersion,
    );

    if (requestResult.result != StorageRequestResult.success) {
      return (requestResult: requestResult.result, version: null);
    }

    if (requestResult.file == null) {
      logsHelper.e("A successful storage download result should always have a file");
      assert(false, "Should never fire");
      return (requestResult: StorageRequestResult.genericError, version: null);
    }

    // Read "current" file, fail upon any issue
    final version = (await requestResult.file!.readAsString()).trim();

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
