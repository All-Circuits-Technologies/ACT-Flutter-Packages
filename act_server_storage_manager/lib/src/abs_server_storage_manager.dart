// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_storage_manager/src/mixins/mixin_storage_config.dart';
import 'package:act_server_storage_manager/src/models/cache_storage_config.dart';
import 'package:act_server_storage_manager/src/models/storage_file.dart';
import 'package:act_server_storage_manager/src/models/storage_page.dart';
import 'package:act_server_storage_manager/src/services/cache_service.dart';
import 'package:act_server_storage_manager/src/services/mixin_storage_service.dart';
import 'package:act_server_storage_manager/src/types/storage_request_result.dart';
import 'package:flutter/material.dart';

/// Abstract class for a storage manager builder. It specifies the other managers that the storage
/// manager depends on.
abstract class AbsServerStorageBuilder<T extends AbsServerStorageManager>
    extends AbsManagerBuilder<T> {
  /// Class constructor
  AbsServerStorageBuilder(super.factory);

  /// List of managers that the storage manager depends on. Make sure to add the manager in charge
  /// of the service that implements the [MixinStorageService] interface so it can be used by the
  /// storage manager.
  @override
  @mustCallSuper
  Iterable<Type> dependsOn() => [
        LoggerManager,
      ];
}

/// Abstract class for a storage manager. It provides a set of methods to interact with a storage
/// service and a cache service.
abstract class AbsServerStorageManager<C extends MixinStorageConfig> extends AbsWithLifeCycle {
  /// logs helper category
  static const String _storageManagerLogCategory = 'storage';

  /// Instance of the [MixinStorageService] to use to operate on the storage.
  /// We are not in charge of this service therefore we don t call the init/dispose methods, we just
  /// use it.
  late final MixinStorageService _storageService;

  /// This is an access to [_storageService] for the derived classes
  @protected
  MixinStorageService get storageService => _storageService;

  /// Instance of the [CacheService] to use a cache mechanism. Null when no cache is used.
  late final CacheService? _cacheService;

  /// This is an access to [_cacheService] for the derived classes
  @protected
  CacheService? get cacheService => _cacheService;

  /// Manager logs helper
  late final LogsHelper _logsHelper;

  /// This is an access to [_logsHelper] for the derived classes
  @protected
  LogsHelper get logsHelper => _logsHelper;

  /// Constructor for [AbsServerStorageManager].
  AbsServerStorageManager() : super();

  /// Initialize the manager by initializing the [_storageService] and the [_cacheService] if
  /// needed.
  @override
  @mustCallSuper
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    _logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: _storageManagerLogCategory,
    );

    // Get the storage service from the derived class.
    _storageService = await getStorageService();

    // Get the config manager to get the cache config.
    final configManager = globalGetIt().get<C>();

    // Create a cache service if needed.
    final useCacheService = configManager.storageCacheUseConf.load();
    if (useCacheService) {
      _cacheService = CacheService(
        parentLogger: _logsHelper,
        storageService: _storageService,
        cacheConfig: CacheStorageConfig(
          key: configManager.storageCacheKeyConf.load(),
          stalePeriod: configManager.storageCacheStalePeriodConf.load(),
          maxNbOfCachedObjects: configManager.storageCacheNumberOfObjectsCached.load(),
        ),
      );
    }

    await _cacheService?.initLifeCycle();
  }

  /// Get a file based on a [fileId]. Set [useCache] to true to use the cache if available.
  Future<({StorageRequestResult result, File? file})> getFile(
    String fileId, {
    bool useCache = true,
  }) async {
    if (useCache && _cacheService != null) {
      return _cacheService.getFile(fileId);
    }

    if (useCache && _cacheService == null) {
      _logsHelper.w('Trying to use cache but no cache service is available, ignoring cache.');
    }

    return _storageService.getFile(fileId);
  }

  /// {@template act_server_storage_manager.AbsServerStorageManager.clearFileFromCache}
  /// Clear a file from cache
  ///
  /// This is only relevant if you use the cache service (if not, nothing is done).
  /// {@endtemplate}
  Future<void> clearFileFromCache(String fileId) async => _cacheService?.clearFileFromCache(fileId);

  /// List all the files in a given [searchPath].
  Future<({StorageRequestResult result, StoragePage? page})> listFiles(
    String searchPath, {
    int? pageSize,
    String? nextToken,
    bool recursiveSearch = false,
  }) async =>
      _storageService.listFiles(
        searchPath,
        pageSize: pageSize,
        nextToken: nextToken,
        recursiveSearch: recursiveSearch,
      );

  /// List all the files in a given [searchPath].
  ///
  /// The method tried to get the files until it matches the expected conditions.
  /// The `page` returned contains all the files retrieved.
  ///
  /// If [matchUntil] and [matchUntilWithAll] are null, the method tries to get all.
  ///
  /// [matchUntil] is called with what the method has last retrieved (not all the elements already
  /// retrieved).
  /// If [matchUntil] is not null and returned true, the method stops here and returned all the
  /// elements already retrieved.
  ///
  /// [matchUntilWithAll] is called with all the elements already retrieved.
  /// If [matchUntilWithAll] is not null and it returned true, the method stops here and returned all
  /// the elements already retrieved.
  ///
  /// [matchUntil] and [matchUntilWithAll] can be both not null, in that case, [matchUntil] is
  /// called first.
  Future<({StorageRequestResult result, StoragePage? page})> listFilesUntil(
    String searchPath, {
    bool Function(List<StorageFile> lastItemsRetrieved)? matchUntil,
    bool Function(List<StorageFile> items)? matchUntilWithAll,
    int? pageSize,
    String? nextToken,
    bool recursiveSearch = false,
  }) async {
    // Result of the request and the page of files
    StoragePage? page;
    do {
      // Get the list of files in the directory
      final filesResult = await _storageService.listFiles(
        searchPath,
        pageSize: pageSize,
        nextToken: page?.nextPageToken,
        recursiveSearch: recursiveSearch,
      );

      // Check if the result is valid and if the page is not null
      if (filesResult.result != StorageRequestResult.success || filesResult.page == null) {
        return (result: filesResult.result, page: null);
      }

      page = filesResult.page!.prependPreviousPage(page);

      if (matchUntil != null && matchUntil(filesResult.page!.items)) {
        // We have match what we wanted, we can return
        return (result: StorageRequestResult.success, page: page);
      }

      if (matchUntilWithAll != null && matchUntilWithAll(page.items)) {
        // We have match what we wanted, we can return
        return (result: StorageRequestResult.success, page: page);
      }

      // Check if there are more files to get
    } while (page.hasNextPage);

    // Return the list of files in the directory
    return (result: StorageRequestResult.success, page: page);
  }

  /// This method is used by the [AbsServerStorageManager] to get the [CacheService] instance to
  /// use. It must be implemented by the concrete class.
  @protected
  Future<MixinStorageService> getStorageService();

  /// Dispose the manager by disposing the [_storageService] and the [_cacheService] if needed.
  @override
  Future<void> disposeLifeCycle() async {
    await _cacheService?.disposeLifeCycle();
    return super.disposeLifeCycle();
  }
}
