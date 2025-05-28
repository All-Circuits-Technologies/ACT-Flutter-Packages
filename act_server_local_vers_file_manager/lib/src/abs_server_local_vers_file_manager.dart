// SPDX-FileCopyrightText: 2025 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_local_vers_file_manager/src/utilities/localized_file_utility.dart';
import 'package:act_server_local_vers_file_manager/src/utilities/localized_versioned_file_utility.dart';
import 'package:act_server_local_vers_file_manager/src/utilities/versioned_file_utility.dart';
import 'package:act_server_storage_manager/act_server_storage_manager.dart';
import 'package:flutter/material.dart';

/// Abstract class for a localized and versioned file manager builder.
///
/// It specifies the other managers [AbsServerLocalVersFileManager] depends on.
/// It is made abstract to enforce projects to subclass their own accurately-named manager(s).
abstract class AbsServerLocalVersFileBuilder<T extends AbsServerLocalVersFileManager,
    S extends AbsServerStorageManager> extends AbsManagerBuilder<T> {
  /// Class constructor
  AbsServerLocalVersFileBuilder(super.factory);

  /// List of managers [AbsServerLocalVersFileManager] depends on.
  @override
  @mustCallSuper
  Iterable<Type> dependsOn() => [
        S,
        LoggerManager,
      ];
}

/// Abstract server Localized Versioned File Manager class.
///
/// This manager is the entry point of current package.
/// It is abstract to enforce accurately-named project-specific subclasses.
abstract class AbsServerLocalVersFileManager extends AbsWithLifeCycle {
  /// Getter function used to lately retrieve storage manager
  final AbsServerStorageManager Function() _storageManagerGetter;

  /// Optional default locales to search localized files with.
  /// See also [systemLocale] which may be enough.
  final List<Locale>? defaultLocales;

  /// Optional default function for the computation of a file name given a version
  final String Function(String)? defaultVersionToFileName;

  /// Optional default caching of version files requests
  final bool? defaultCacheVersion;

  /// Optional default caching of final files requests
  final bool? defaultCacheFile;

  /// Storage to query
  late final AbsServerStorageManager _storageManager;

  /// System locale is used as a last-resort single locales fallback
  @protected
  Locale get systemLocale;

  /// Constructor for [AbsServerLocalVersFileManager].
  ///
  /// [storageManagerGetter] is a getter for the [AbsServerStorageManager] this manager instance
  /// must browse into. [defaultLocales], [defaultVersionToFileName], [defaultCacheVersion] and
  /// [defaultCacheFile] are optional default values used by manager methods.
  AbsServerLocalVersFileManager({
    required AbsServerStorageManager Function() storageManagerGetter,
    this.defaultLocales,
    this.defaultVersionToFileName,
    this.defaultCacheVersion,
    this.defaultCacheFile,
  })  : _storageManagerGetter = storageManagerGetter,
        super();

  /// Initialize the manager
  @override
  @mustCallSuper
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _storageManager = _storageManagerGetter();
  }

  /// Get a localized [fileName] within [dirId] folder.
  ///
  /// Localized files are expected to follow a specific filesystem layout:
  /// - Any localized file must be handled within a dedicated folder
  /// - Such folder must contain one sub-folder per locale, joined with underscore and lowercase
  /// - Wanted file must exist in all local sub-folders, with the same [fileName]
  ///
  /// Example:
  /// - my_file/fr_fr/my_file.md
  /// - my_file/fr/my_file.md
  /// - my_file/en_us/my_file.md
  ///
  /// That is, find first [dirId]/$locale/[fileName] based on sorted [locales], [defaultLocales]
  /// or [systemLocale] with $locale in "en_us" format (underscore, lowercase).
  ///
  /// Result can be cached or not by storage using [useCache] or [defaultCacheFile],
  /// defaulting to true when choice is left null.
  Future<
      ({
        StorageRequestResult result,
        ({Locale locale, String filePath, File file})? data,
      })> getLocalizedFile({
    required String dirId,
    required String fileName,
    List<Locale>? locales,
    bool? useCache,
  }) async =>
      LocalizedFileUtility.getLocalizedFile(
        storage: _storageManager,
        dirId: dirId,
        fileName: fileName,
        locales: locales ?? defaultLocales ?? [systemLocale],
        useCache: useCache ?? defaultCacheFile ?? true,
      );

  /// Get a versioned file within [dirId] folder.
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
  ///
  /// Name of the file to find is computed from its version using [versionToFileName], otherwise
  /// [defaultVersionToFileName], otherwise file name is expected to exactly match version.
  ///
  /// An explicit [versionOverride] can be given to retrieve this version of the file instead of
  /// current version of it. This can also be used as an accelerator when caller already know
  /// the current version, saving one read operation.
  ///
  /// Intermediate and result can be cached or not by storage using [cacheVersion] and [cacheFile],
  /// or [defaultCacheVersion] and [defaultCacheFile], defaulting to true when choice is left null.
  Future<
      ({
        StorageRequestResult result,
        ({String version, String filePath, File file})? data,
      })> getVersionedFile({
    required String dirId,
    String Function(String)? versionToFileName,
    String? versionOverride,
    bool? cacheVersion,
    bool? cacheFile,
  }) async =>
      VersionedFileUtility.getVersionedFile(
        storage: _storageManager,
        dirId: dirId,
        versionToFileName: versionToFileName ?? defaultVersionToFileName ?? (version) => version,
        cacheVersion: cacheVersion ?? defaultCacheVersion ?? true,
        cacheFile: cacheFile ?? defaultCacheFile ?? true,
      );

  /// Get a localized and versioned file within [dirId] folder.
  ///
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
  ///
  /// That is:
  /// - find first localized "current" file within [dirId]
  ///    (first "$locale/current" file based on sorted [locales], [defaultLocales],
  ///     or [systemLocale] with $locale in "en_us" format, underscore, lowercase),
  /// - find sibling versioned file, from [explicitVersion] or from "current" version
  ///
  /// Sibling file name is computed from version to fetch using [versionToFileName],
  /// or [defaultVersionToFileName], defaulting to version itself.
  ///
  /// Intermediate and result can be cached or not by storage using [cacheVersion] and [cacheFile],
  /// or [defaultCacheVersion] and [defaultCacheFile], defaulting to true when choice is left null.
  Future<
      ({
        StorageRequestResult result,
        ({Locale locale, String version, String filePath, File file})? data,
      })> getLocalizedVersionedFile({
    required String dirId,
    String Function(String)? versionToFileName,
    List<Locale>? locales,
    String? explicitVersion,
    bool? cacheVersion,
    bool? cacheFile,
  }) async =>
      LocalizedVersionedFileTool.getLocalizedVersionedFile(
        storage: _storageManager,
        dirId: dirId,
        versionToFileName: versionToFileName ?? defaultVersionToFileName ?? (version) => version,
        locales: locales ?? defaultLocales ?? [systemLocale],
        explicitVersion: explicitVersion,
        cacheVersion: cacheVersion ?? defaultCacheVersion ?? true,
        cacheFile: cacheFile ?? defaultCacheFile ?? true,
      );
}
