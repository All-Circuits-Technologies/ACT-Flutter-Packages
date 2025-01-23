// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_server_storage_manager/act_server_storage_manager.dart';
import 'package:flutter/widgets.dart';

/// This mixin is used to add more features linked to the image cache service to the
/// [AbsServerStorageManager]
mixin MixinImageCacheService<C extends MixinStorageConfig> on AbsServerStorageManager<C> {
  final Map<String, List<Object>> _paintingImagesKeys = {};

  Future<({File? file, StorageRequestResult result})> getImageFile(
    String fileId, {
    int? maxWidth,
    int? maxHeight,
    bool useCache = true,
    Object? flutterPaintingImageKey,
  }) async {
    final imageResult = await _getImageFileProcess(
      fileId,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      useCache: useCache,
    );

    if (imageResult.result != StorageRequestResult.success) {
      return imageResult;
    }

    _registerPaintingImagePath(
      fileId: fileId,
      paintingImageFileKey: flutterPaintingImageKey ??
          createKey(
            fileId: fileId,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
    );

    return imageResult;
  }

  /// {@template act_server_storage_manager.AbsServerStorageManager.clearImageFileFromCache}
  /// Clear an image file from cache
  ///
  /// This method adds the cleaning of the image in the flutter painting cache
  ///
  /// This is only relevant if you use the cache service (if not, nothing is done).
  /// {@endtemplate}
  Future<void> clearImageFileFromCache(
    String fileId, {
    bool clearPaintingCache = true,
  }) async {
    await super.clearFileFromCache(fileId);

    final keys = _paintingImagesKeys[fileId];
    if (!clearPaintingCache || keys == null) {
      // Nothing to clear;
      return;
    }

    for (final key in keys) {
      try {
        PaintingBinding.instance.imageCache.evict(key);
      } catch (error) {
        logsHelper.e("An error occurred when tried to evict the files linked to: $fileId, and "
            "the key: $key, from the painting image cache");
      }
    }

    _paintingImagesKeys.remove(fileId);
  }

  /// Get an image file based on a [fileId]. Set [useCache] to true to use the cache if available.
  ///
  /// {@macro act_server_storage_manager.CacheService.getImageFile.size}
  Future<({StorageRequestResult result, File? file})> _getImageFileProcess(
    String fileId, {
    int? maxWidth,
    int? maxHeight,
    bool useCache = true,
  }) async {
    if (useCache && cacheService != null) {
      return cacheService!.getImageFile(
        fileId,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    }

    if (useCache && cacheService == null) {
      logsHelper.w('Trying to use cache to get image file but no cache service is available, '
          'ignoring cache.');
    }

    if (maxWidth != null || maxHeight != null) {
      logsHelper.i("You try to get the image file: $fileId, from the storage service and not the "
          "cache service. The maxWidth and maxHeight parameters won't be used to get the image "
          "file");
    }
    return storageService.getFile(fileId);
  }

  void _registerPaintingImagePath({
    required String fileId,
    required Object paintingImageFileKey,
  }) {
    final files = _paintingImagesKeys.putIfAbsent(fileId, () => []);
    if (!files.contains(paintingImageFileKey)) {
      files.add(paintingImageFileKey);
    }
  }

  static String createKeyFromDouble({
    required String fileId,
    required double? maxWidth,
    required double? maxHeight,
  }) =>
      createKey(
        fileId: fileId,
        maxWidth: maxWidth != null && maxWidth.isFinite ? maxWidth.ceil() : null,
        maxHeight: maxHeight != null && maxHeight.isFinite ? maxHeight.ceil() : null,
      );

  static String createKey({
    required String fileId,
    required int? maxWidth,
    required int? maxHeight,
  }) {
    var key = fileId;
    if (maxHeight != null) {
      key = "${maxHeight}_$key";
    }
    if (maxWidth != null) {
      key = "${maxWidth}_$key";
    }
    return key;
  }
}
