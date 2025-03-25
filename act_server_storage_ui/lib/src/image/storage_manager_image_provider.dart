// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:ui' as ui;

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_server_storage_manager/act_server_storage_manager.dart';
import 'package:act_server_storage_ui/src/mixins/mixin_image_cache_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// This is an [ImageProvider] to load an image from the [AbsServerStorageManager]
///
/// The image is loaded from the [fileId] given.
///
/// If [devicePixelRatio] and [maxWidth] or [maxHeight] are given, the image provider will be
/// resized at the right size.
class StorageManagerImageProvider<S extends MixinImageCacheService> extends ImageProvider<String> {
  /// The server storage manager
  final S _storageManager;

  /// The image file id to display
  final String fileId;

  /// True to use the server storage cache
  final bool useCache;

  /// This is the max width to use for displaying the image.
  final double? maxWidth;

  /// This is the max height to use for displaying the image.
  final double? maxHeight;

  /// This is the current device pixel ratio
  final double? devicePixelRatio;

  /// Class constructor
  StorageManagerImageProvider({
    required this.fileId,
    this.useCache = true,
    this.maxWidth,
    this.maxHeight,
    this.devicePixelRatio,
  })  : _storageManager = globalGetIt().get<S>(),
        assert(maxWidth == null && maxHeight == null || devicePixelRatio != null,
            "When using maxWidth or maxHeight, the devicePixelRatio must be given");

  /// This method returns the key to load the image thanks to the given [configuration]
  @override
  Future<String> obtainKey(ImageConfiguration configuration) async =>
      MixinImageCacheService.createKey(
        fileId: fileId,
        // We use the pixel size because the images keys are stored in the cache manager with their
        // pixel size.
        maxWidth: _getDevicePixelSize(maxWidth),
        maxHeight: _getDevicePixelSize(maxHeight),
      );

  /// This load an image thanks to the given key
  @override
  ImageStreamCompleter loadImage(String key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(
          // Here, we get the future return as a value and pass it to the class
          // ignore: discarded_futures
          _getImage(key, decode),
          informationCollector: () => <DiagnosticsNode>[
                DiagnosticsProperty<ImageProvider>('Image provider', this),
                DiagnosticsProperty<String>('fileId', fileId),
              ]);

  /// Get the right device pixel size
  int? _getDevicePixelSize(double? size) {
    if (size == null || !size.isFinite) {
      return null;
    }

    var tmpSize = size;
    if (devicePixelRatio != null) {
      tmpSize *= devicePixelRatio!;
    }

    return tmpSize.ceil();
  }

  /// This get the image from the [_storageManager]
  ///
  /// If an error occurred, this returns a [Future.error].
  Future<ImageInfo> _getImage(String key, ImageDecoderCallback decode) async {
    final tmpHeight = _getDevicePixelSize(maxHeight);
    final tmpWidth = _getDevicePixelSize(maxWidth);
    final fileResult = await _storageManager.getImageFile(
      fileId,
      maxHeight: tmpHeight,
      maxWidth: tmpWidth,
      useCache: useCache,
    );

    if (fileResult.result != StorageRequestResult.success || fileResult.file == null) {
      return Future.error("A problem occurred when tried to load the image from file: $fileId");
    }

    final fileImage = FileImage(fileResult.file!);
    final tmpImage = (tmpWidth != null || tmpHeight != null)
        ? ResizeImage(
            fileImage,
            width: tmpWidth,
            height: tmpHeight,
            policy: ResizeImagePolicy.fit,
          )
        : fileImage as ImageProvider;
    final completer = Completer<ui.Image>();
    tmpImage.resolve(ImageConfiguration.empty).addListener(ImageStreamListener((info, _) {
      completer.complete(info.image);
      tmpImage.evict();
    }));
    final image = await completer.future;
    return ImageInfo(image: image);
  }
}
