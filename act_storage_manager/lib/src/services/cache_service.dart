// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_storage_manager/act_storage_manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache service to handle the caching of files. It uses the [CacheManager] to handle the logic of
/// caching files. The [CacheService] is a wrapper around the [CacheManager] to provide an
/// httpFileService that will use the method implemented in our storageService.
class CacheService extends AbstractService {
  /// Instance of [CacheManager] to handle the logic of caching files.
  final CacheManager _cacheManager;

  /// Factory method to create a [CacheService].
  factory CacheService({
    required CacheStorageConfig cacheConfig,
    required MixinStorageService storageService,
  }) {
    // Create a the httpFileService that will use the method implemented in the storageService.
    final httpFileService = StorageHttpFileService(
      storageService: storageService,
    );

    // Create the actual cache manager with the provided parameters and the httpFileService.
    final cacheManager = CacheManager(
      Config(
        cacheConfig.cacheKey,
        stalePeriod: cacheConfig.stalePeriod,
        maxNrOfCacheObjects: cacheConfig.maxNbOfCacheObjects,
        fileService: httpFileService,
      ),
    );

    return CacheService._(
      cacheManager: cacheManager,
    );
  }

  /// Constructor for [CacheService].
  CacheService._({
    required CacheManager cacheManager,
  })  : _cacheManager = cacheManager,
        super();

  /// Get a file based on a [fileId] from the cache or download it if it is not present. If the
  /// [result] is [StorageRequestResult.success], the [file] will be the downloaded file.
  Future<(StorageRequestResult result, File? file)> getFile(String fileId) async {
    try {
      final file = await _cacheManager.getSingleFile(fileId);
      return (StorageRequestResult.success, file);
    } catch (e) {
      return (StorageRequestResult.genericError, null);
    }
  }

  @override
  Future<void> initService() async {}

  /// Dispose the [_cacheManager].
  @override
  Future<void> dispose() async {
    await _cacheManager.dispose();
    return super.dispose();
  }
}
