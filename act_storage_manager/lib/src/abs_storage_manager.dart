// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_storage_manager/act_storage_manager.dart';
import 'package:flutter/material.dart';

/// Abstract class for a storage manager builder. It specifies the other managers that the storage
/// manager depends on.
abstract class AbsStorageBuilder<T extends AbsStorageManager> extends ManagerBuilder<T> {
  /// Class constructor
  AbsStorageBuilder(super.factory);

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
abstract class AbsStorageManager extends AbstractManager {
  /// logs helper category
  static const String _storageManagerLogCategory = 'storage';

  /// Instance of the [MixinStorageService] to use to operate on the storage.
  /// We are not in charge of this service therefore we don t call the init/dispose methods, we just
  /// use it.
  late final MixinStorageService _storageService;

  /// Instance of the [CacheService] to use a cache mechanism. Null when no cache is used.
  late final CacheService? _cacheService;

  /// Logs helper
  late final LogsHelper _logsHelper;

  /// Constructor for [AbsStorageManager].
  AbsStorageManager() : super();

  /// Initialize the manager by initializing the [_storageService] and the [_cacheService] if
  /// needed.
  @override
  Future<void> initManager() async {
    _logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: _storageManagerLogCategory,
    );

    // Get the storage service from the derived class.
    _storageService = await getStorageService();

    // Get the cache config from the derived class and initialize the cache service if a config
    // is available.
    final cacheConfig = await getCacheConfig();
    if (cacheConfig != null) {
      _cacheService = CacheService(
        storageService: _storageService,
        cacheConfig: cacheConfig,
      );
    }

    await _cacheService?.initService();
  }

  /// Get a file based on a [fileId]. Set [useCache] to true to use the cache if available.
  Future<(StorageRequestResult result, File? file)> getFile(
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

  /// List all the files in a given [directory].
  Future<(StorageRequestResult result, StoragePage? page)> listFiles(
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

  /// This method is used by the [AbsStorageManager] to get the [CacheService] instance to use. It
  /// must be implemented by the concrete class.
  @protected
  Future<MixinStorageService> getStorageService();

  /// Get the [CacheStorageConfig] to use for the cache. If you don't want to use a cache mechanism,
  /// you can implement this method to return null.
  @protected
  Future<CacheStorageConfig?> getCacheConfig();

  /// Dispose the manager by disposing the [_storageService] and the [_cacheService] if needed.
  @override
  Future<void> dispose() async {
    await _cacheService?.dispose();
    return super.dispose();
  }
}
