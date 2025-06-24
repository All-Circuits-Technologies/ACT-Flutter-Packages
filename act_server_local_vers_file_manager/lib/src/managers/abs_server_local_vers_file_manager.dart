// SPDX-FileCopyrightText: 2025 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io' show File;
import 'dart:ui' show Locale;

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_local_vers_file_manager/src/models/server_local_dir_config.dart';
import 'package:act_server_local_vers_file_manager/src/models/server_local_dir_options.dart';
import 'package:act_server_local_vers_file_manager/src/types/mixin_server_local_vers_file_config.dart';
import 'package:act_server_local_vers_file_manager/src/types/mixin_server_local_vers_file_type.dart';
import 'package:act_server_local_vers_file_manager/src/utilities/localized_file_utility.dart';
import 'package:act_server_local_vers_file_manager/src/utilities/localized_versioned_file_utility.dart';
import 'package:act_server_local_vers_file_manager/src/utilities/versioned_file_utility.dart';
import 'package:act_server_storage_manager/act_server_storage_manager.dart';
import 'package:flutter/foundation.dart';

/// Abstract class for a localized and versioned file manager builder.
///
/// It specifies the other managers [AbsServerLocalVersFileManager] depends on.
/// It is made abstract to enforce projects to subclass their own accurately-named manager(s).
abstract class AbsServerLocalVersFileBuilder<D extends MixinServerLocalVersFileType,
    T extends AbsServerLocalVersFileManager<D>> extends AbsManagerBuilder<T> {
  /// Class constructor
  AbsServerLocalVersFileBuilder(super.factory);

  /// List of managers [AbsServerLocalVersFileManager] depends on.
  @override
  @mustCallSuper
  Iterable<Type> dependsOn() => [
        LoggerManager,
      ];
}

/// Abstract class for a localized and versioned file manager.
/// This allows to manage multiple folders in a same storage server or in different servers.
abstract class AbsServerLocalVersFileManager<D extends MixinServerLocalVersFileType>
    extends AbsWithLifeCycle {
  /// Logs helper category
  static const String _fileManagerLogCategory = 'serverMultiDir';

  /// Getter for the configuration manager
  final MixinServerLocalVersFileConfig<D> Function() _configManagerGetter;

  /// The configuration of all the server local directories
  late final ServerLocalDirConfig<D> _localDirConfig;

  /// Manager logs helper
  late final LogsHelper _logsHelper;

  /// This is an access to [_logsHelper] for the derived classes
  @protected
  LogsHelper get logsHelper => _logsHelper;

  /// Class constructor
  AbsServerLocalVersFileManager({
    required MixinServerLocalVersFileConfig<D> Function() configManagerGetter,
  })  : _configManagerGetter = configManagerGetter,
        super();

  /// Initialize the manager
  @override
  @mustCallSuper
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    _logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: _fileManagerLogCategory,
    );

    _localDirConfig = await _parseServerConfig(
      configManager: _configManagerGetter(),
    );
  }

  /// Get a localized [fileName] within [dirType] folder.
  ///
  /// {@macro act_server_local_vers_file_manager.LocalizedFileUtility.serverRequirements}
  ///
  /// That is, find first [dirType]/$locale/[fileName] based on sorted [locales], options.locales
  /// or result of [_getLocalesToUse] with $locale in "en_us" format (underscore, lowercase).
  ///
  /// Result can be cached or not by storage using [useCache] or options.cacheFile,
  /// defaulting to true when choice is left null.
  Future<
      ({
        StorageRequestResult result,
        ({Locale locale, String filePath, File file})? data,
      })> getLocalizedFile({
    required D dirType,
    required String fileName,
    List<Locale>? locales,
    bool? useCache,
  }) async =>
      _getDefaultConfig(
        dirType: dirType,
        configGetter: (options) async => LocalizedFileUtility.getLocalizedFile(
          storage: getStorageManager(dirType),
          dirId: dirType.dirId,
          fileName: fileName,
          locales: locales ?? options?.locales ?? await _getLocalesToUse(),
          useCache: useCache ?? options?.cacheFile ?? true,
          logsHelper: _logsHelper,
        ),
      );

  /// Get a versioned file within [dirType] folder.
  ///
  /// {@macro act_server_local_vers_file_manager.VersionedFileUtility.serverRequirements}
  ///
  /// Name of the file to find is computed from its version using [versionToFileName], otherwise
  /// options.versionToFileName, otherwise file name is expected to exactly match version.
  ///
  /// {@macro act_server_local_vers_file_manager.VersionedFileUtility.versionOverride}
  ///
  /// Intermediate and result can be cached or not by storage using [cacheVersion] and [cacheFile],
  /// or options.cacheVersion and options.cacheFile, defaulting to false for [cacheVersion] and true
  /// for [cacheFile] when choice is left null.
  Future<
      ({
        StorageRequestResult result,
        ({String version, String filePath, File file})? data,
      })> getVersionedFile({
    required D dirType,
    String Function(String)? versionToFileName,
    String? versionOverride,
    bool? cacheVersion,
    bool? cacheFile,
  }) async =>
      _getDefaultConfig(
        dirType: dirType,
        configGetter: (options) => VersionedFileUtility.getVersionedFile(
          storage: getStorageManager(dirType),
          dirId: dirType.dirId,
          versionToFileName:
              versionToFileName ?? options?.versionToFileName ?? (version) => version,
          cacheVersion: cacheVersion ?? options?.cacheVersion ?? false,
          cacheFile: cacheFile ?? options?.cacheFile ?? true,
          versionOverride: versionOverride,
          logsHelper: _logsHelper,
        ),
      );

  /// Fetch current version of a versioned file within [dirType] folder.
  ///
  /// {@macro act_server_local_vers_file_manager.VersionedFileUtility.serverRequirements}
  ///
  /// That is, read "version" file within [storage] [dirType] folder, optionally caching result
  /// using [cacheVersion] or options.cacheVersion, defaulting to false for [cacheVersion] when
  /// choice is left null.
  Future<
      ({
        StorageRequestResult requestResult,
        String? version,
      })> getFileCurrentVersion({
    required D dirType,
    String? versionOverride,
    bool? cacheVersion,
  }) async =>
      _getDefaultConfig(
        dirType: dirType,
        configGetter: (options) => VersionedFileUtility.getFileCurrentVersion(
          storage: getStorageManager(dirType),
          dirId: dirType.dirId,
          cacheVersion: cacheVersion ?? options?.cacheVersion ?? false,
          logsHelper: logsHelper,
        ),
      );

  /// Get a localized and versioned file within [dirType] folder.
  ///
  /// {@macro act_server_local_vers_file_manager.LocalizedVersionedFileUtility.serverRequirements}
  ///
  /// That is:
  ///
  /// - find first localized "current" file within [dirType]
  ///    (first "$locale/current" file based on sorted [locales], options.locales
  ///    or result of [_getLocalesToUse] with $locale in "en_us" format, underscore, lowercase),
  /// - find sibling versioned file, from [explicitVersion] or from "current" version
  ///
  /// Sibling file name is computed from version to fetch using [versionToFileName],
  /// or options.versionToFileName, defaulting to version itself.
  ///
  /// Intermediate and result can be cached or not by storage using [cacheVersion] and [cacheFile],
  /// or options.cacheVersion and options.cacheFile, defaulting to false for [cacheVersion] and true
  /// for [cacheFile] when choice is left null.
  Future<
      ({
        StorageRequestResult result,
        ({Locale locale, String version, String filePath, File file})? data,
      })> getLocalizedVersionedFile({
    required D dirType,
    String Function(String)? versionToFileName,
    List<Locale>? locales,
    String? explicitVersion,
    bool? cacheVersion,
    bool? cacheFile,
  }) async =>
      _getDefaultConfig(
        dirType: dirType,
        configGetter: (options) async => LocalizedVersionedFileUtility.getLocalizedVersionedFile(
          storage: getStorageManager(dirType),
          dirId: dirType.dirId,
          versionToFileName:
              versionToFileName ?? options?.versionToFileName ?? (version) => version,
          locales: locales ?? options?.locales ?? await _getLocalesToUse(),
          explicitVersion: explicitVersion,
          cacheVersion: cacheVersion ?? options?.cacheVersion ?? false,
          cacheFile: cacheFile ?? options?.cacheFile ?? true,
          logsHelper: _logsHelper,
        ),
      );

  /// Get the current localized version of a file within [dirType] folder.
  ///
  /// {@macro act_server_local_vers_file_manager.LocalizedVersionedFileUtility.serverRequirements}
  ///
  /// Find first localized "current" file within [dirType] (first "$locale/current" file based on
  /// sorted [locales], options.locales or result of [_getLocalesToUse] with $locale in "en_us"
  /// format, underscore, lowercase).
  ///
  /// That is, read "version" file within [storage] [dirType] folder, optionally caching result
  /// using [cacheVersion] or options.cacheVersion, defaulting to false for [cacheVersion] when
  /// choice is left null.
  Future<
      ({
        StorageRequestResult result,
        ({Locale locale, String version})? data,
      })> getFileLocalizedCurrentVersion({
    required D dirType,
    List<Locale>? locales,
    bool? cacheVersion,
  }) async =>
      _getDefaultConfig(
          dirType: dirType,
          configGetter: (options) async =>
              LocalizedVersionedFileUtility.getFileLocalizedCurrentVersion(
                storage: getStorageManager(dirType),
                dirId: dirType.dirId,
                locales: locales ?? options?.locales ?? await _getLocalesToUse(),
                cacheVersion: cacheVersion ?? options?.cacheVersion ?? false,
                logsHelper: logsHelper,
              ));

  /// {@template act_server_local_vers_file_manager.AbsServerLocalVersFileManager.getOptionsOverrides}
  /// This method allows to override the options got from the config manager, but also to give a
  /// default VersionToFileNameParser for a given dir type.
  /// {@endtemplate}
  @protected
  Future<Map<D, ServerLocalDirOptions>> getOptionsOverrides() async => {};

  /// {@template act_server_local_vers_file_manager.AbsServerLocalVersFileManager.getDefaultLocale}
  /// Get the default app locale to use for the localized files. This locale is the one used when
  /// the current locale isn't supported by the app.
  /// {@endtemplate}
  @protected
  Future<Locale> getDefaultLocale();

  /// {@template act_server_local_vers_file_manager.AbsServerLocalVersFileManager.getCurrentLocale}
  /// Get the current app locale to use for the localized files.
  /// {@endtemplate}
  @protected
  Future<Locale> getCurrentLocale();

  /// {@template act_server_local_vers_file_manager.AbsServerLocalVersFileManager.getStorageManager}
  /// Get the storage manager for a given [dirType].
  /// {@endtemplate}
  @protected
  AbsServerStorageManager getStorageManager(D dirType);

  /// Get the default configuration for a given [dirType] and call the provided [configGetter] with
  /// the options got.
  Future<T> _getDefaultConfig<T>({
    required D dirType,
    required Future<T> Function(ServerLocalDirOptions? options) configGetter,
  }) async =>
      configGetter(_localDirConfig.options[dirType]);

  /// Parse the server configuration and return a [ServerLocalDirConfig] instance.
  Future<ServerLocalDirConfig<D>> _parseServerConfig({
    required MixinServerLocalVersFileConfig<D> configManager,
  }) async {
    final tmpConfig = configManager.serverLocalVersFileConfig.load();
    final tmpConfigsOptions = tmpConfig != null
        ? Map<D, ServerLocalDirOptions>.from(tmpConfig.options)
        : <D, ServerLocalDirOptions>{};

    final overriddenOptions = await getOptionsOverrides();
    for (final entry in overriddenOptions.entries) {
      var tmpOptions = tmpConfigsOptions[entry.key];
      if (tmpOptions != null) {
        tmpOptions = tmpOptions.copyWith(
          locales: entry.value.locales,
          versionToFileName: entry.value.versionToFileName,
          cacheVersion: entry.value.cacheVersion,
          cacheFile: entry.value.cacheFile,
        );
      } else {
        tmpOptions = entry.value;
      }

      tmpConfigsOptions[entry.key] = tmpOptions;
    }

    return ServerLocalDirConfig<D>(
      options: tmpConfigsOptions,
    );
  }

  /// Get the list of locales to use for localized files.
  Future<List<Locale>> _getLocalesToUse() => Future.wait([
        getCurrentLocale(),
        getDefaultLocale(),
      ]);
}
