// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:flutter/widgets.dart';

/// This mixin is used to add more features linked to the image cache service to the
/// [AbsRemoteStorageManager]
///
/// Flutter has a cache of images to not get them from network, assets, etc. each time we want to
/// display them.
/// Therefore, even if the image is updated in the cache manager it couldn't be updated in the
/// views. To do it, we register the image keys and clear the flutter cache when calling
/// [clearImageFileFromCache] method. The right image will be displayed at the next view reload.
///
/// It keeps a list [_paintingImagesKeys] of all the images retrieved with different size.
/// This list is used to clear, if needed, the flutter painting image cache [ImageCache].
mixin MixinImageCacheService<C extends MixinStorageConfig> on AbsRemoteStorageManager<C> {
  /// Keeps the flutter painting image cache [ImageCache] keys for each file retrieved. This is
  /// useful when you call [getImageFile] with different size.
  final Map<String, List<Object>> _paintingImagesKeys = {};

  /// {@macro act_remote_storage_ui.MixinImageCacheService._getImageFileProcess}
  ///
  /// If no problem occurred, the image file key is stored in [_paintingImagesKeys].
  ///
  /// If [flutterPaintingImageKey] is not null, it will be used as key to fill
  /// [_paintingImagesKeys].
  /// If [flutterPaintingImageKey] is null, the method [createKey] is used to generate the key.
  ///
  /// {@macro act_remote_storage_manager.CacheService.getImageFile.size}
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

  /// {@template act_remote_storage_ui.MixinImageCacheService.clearImageFileFromCache}
  /// Clear an image file from cache but also from the flutter painting cache [ImageCache].
  /// It uses [_paintingImagesKeys] to know what keys to evict from the [ImageCache].
  ///
  /// This is relevant to call even if you don't use the cache service because it will evict the
  /// images from [ImageCache].
  ///
  /// This clears [ImageCache] elements but doesn't reload the view. Try to call this method before
  /// reloading the views.
  ///
  /// If [clearPaintingCache] is equals to false, it's like calling [clearFileFromCache].
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

  /// {@template act_remote_storage_ui.MixinImageCacheService._getImageFileProcess}
  /// Get an image file based on a [fileId]. Set [useCache] to true to use the cache if available.
  /// If the `result` is [StorageRequestResult.success], the `file` will be the downloaded file.
  /// {@endtemplate}
  ///
  /// {@macro act_remote_storage_manager.CacheService.getImageFile.size}
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

  /// Register the [paintingImageFileKey] linked to the given [fileId] in the [_paintingImagesKeys].
  void _registerPaintingImagePath({
    required String fileId,
    required Object paintingImageFileKey,
  }) {
    final files = _paintingImagesKeys.putIfAbsent(fileId, () => []);
    if (!files.contains(paintingImageFileKey)) {
      files.add(paintingImageFileKey);
    }
  }

  /// {@macro act_remote_storage_ui.MixinImageCacheService.createKey}
  ///
  /// If [maxWidth] or [maxHeight] aren't finite, their values are not added in the key.
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

  /// {@template act_remote_storage_ui.MixinImageCacheService.createKey}
  /// Create an image key with the [maxWidth] and [maxHeight] in the key. This is useful, to have an
  /// image key which differentiates the images by their size.
  ///
  /// If [maxWidth] or [maxHeight] are null, their values are not added in the key.
  /// {@endtemplate}
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
