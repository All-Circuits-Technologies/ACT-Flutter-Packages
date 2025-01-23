// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_storage_manager/src/models/cache_storage_config.dart';
import 'package:act_server_storage_manager/src/services/cache_with_images_manager.dart';
import 'package:act_server_storage_manager/src/services/mixin_storage_service.dart';
import 'package:act_server_storage_manager/src/services/storage_http_file_service.dart';

import 'package:act_server_storage_manager/src/types/storage_request_result.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache service to handle the caching of files. It uses the [CacheWithImagesManager] to handle the
/// logic of caching files. The [CacheService] is a wrapper around the [CacheWithImagesManager] to
/// provide an httpFileService that will use the method implemented in our storageService.
///
/// The [CacheWithImagesManager] only adds methods and no properties. Therefore, its ok to add it,
/// even if we don't use the cache service for images.
class CacheService extends AbstractService {
  /// This is the log category linked to the cache service
  static const _logsCategory = "cache";

  /// Instance of [CacheWithImagesManager] to handle the logic of caching files.
  final CacheWithImagesManager _cacheManager;

  /// This is the logs helper linked to the cache service
  final LogsHelper _logsHelper;

  /// Factory method to create a [CacheService].
  factory CacheService({
    required CacheStorageConfig cacheConfig,
    required MixinStorageService storageService,
    required LogsHelper parentLogger,
  }) {
    final logsHelper = parentLogger.createASubLogsHelper(_logsCategory);

    // Create a the httpFileService that will use the method implemented in the storageService.
    final httpFileService = StorageHttpFileService(
      storageService: storageService,
    );

    // Create the actual cache manager with the provided parameters and the httpFileService.
    final cacheManager = CacheWithImagesManager(
      Config(
        cacheConfig.key,
        stalePeriod: cacheConfig.stalePeriod,
        maxNrOfCacheObjects: cacheConfig.maxNbOfCachedObjects,
        fileService: httpFileService,
      ),
    );

    return CacheService._(
      cacheManager: cacheManager,
      logsHelper: logsHelper,
    );
  }

  /// Constructor for [CacheService].
  CacheService._({
    required CacheWithImagesManager cacheManager,
    required LogsHelper logsHelper,
  })  : _cacheManager = cacheManager,
        _logsHelper = logsHelper,
        super();

  /// Init the service
  @override
  Future<void> initService() async {
    _logsHelper.i('Using cache service.');
  }

  /// Get a file based on a [fileId] from the cache or download it if it is not present. If the
  /// [result] is [StorageRequestResult.success], the [file] will be the downloaded file.
  Future<({StorageRequestResult result, File? file})> getFile(String fileId) async {
    try {
      final file = await _cacheManager.getSingleFile(fileId);
      return (result: StorageRequestResult.success, file: file);
    } catch (e) {
      return (result: StorageRequestResult.genericError, file: null);
    }
  }

  /// Get an image file based on a [fileId] from the cache or download it if it is not present.
  /// If the [result] is [StorageRequestResult.success], the [file] will be the downloaded file.
  ///
  /// {@template act_server_storage_manager.CacheService.getImageFile.size}
  /// In case we use the cache and [maxWidth] and [maxHeight] are not null, the image file is
  /// retrieved from the distant server and stored with its default size and the size asked.
  /// Therefore:
  ///
  /// - if you ask again the same size, it will return the image with the right size
  /// - if you ask a new size, because you already retrieved the default size, it will use it and
  ///   store in cache the new size before returning it.
  ///
  /// The [maxWidth] and [maxHeight] values given must have been multiplied with the device pixel
  /// ratio or you will get blurry images.
  /// {@endtemplate}
  Future<({StorageRequestResult result, File? file})> getImageFile(
    String fileId, {
    int? maxWidth,
    int? maxHeight,
  }) async {
    FileResponse fileResponse;
    try {
      fileResponse = await _cacheManager
          .getImageFile(
            fileId,
            maxHeight: maxHeight,
            maxWidth: maxWidth,
          )
          .last;
    } catch (e) {
      return (result: StorageRequestResult.genericError, file: null);
    }

    if (fileResponse is! FileInfo) {
      _logsHelper.w("The image file response retrieved for: $fileId, is not a FileInfo");
      return (result: StorageRequestResult.genericError, file: null);
    }

    return (result: StorageRequestResult.success, file: fileResponse.file);
  }

  /// Clear the file [fileId] from cache
  Future<void> clearFileFromCache(String fileId) async {
    try {
      await _cacheManager.removeFile(fileId);
    } catch (error) {
      _logsHelper.e("A problem occurred when tried to remove the file: $fileId, from cache");
    }
  }

  /// Dispose the [_cacheManager].
  @override
  Future<void> dispose() async {
    await _cacheManager.dispose();
    return super.dispose();
  }
}
