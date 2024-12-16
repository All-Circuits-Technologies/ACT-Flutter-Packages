// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui' as ui;

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_server_storage_manager/act_server_storage_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// This is an [ImageProvider] to load an image from the [AbsServerStorageManager]
///
/// The image is loaded from the [fileId] given.
class StorageManagerImageProvider<S extends AbsServerStorageManager> extends ImageProvider<String> {
  /// The server storage manager
  final S _storageManager;

  /// The image file id to display
  final String fileId;

  /// True to use the server storage cache
  final bool useCache;

  /// Class constructor
  StorageManagerImageProvider({
    required this.fileId,
    this.useCache = true,
  }) : _storageManager = globalGetIt().get<S>();

  /// This method returns the key to load the image thanks to the given [configuration]
  @override
  Future<String> obtainKey(ImageConfiguration configuration) async => fileId;

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

  /// This get the image from the [_storageManager]
  ///
  /// If an error occurred, this returns a [Future.error].
  Future<ImageInfo> _getImage(String key, ImageDecoderCallback decode) async {
    final (result, file) = await _storageManager.getFile(
      fileId,
      useCache: useCache,
    );

    if (result != StorageRequestResult.success || file == null) {
      return Future.error("A problem occurred when tried to load the image from file: $file");
    }

    ui.FrameInfo frameInfo;
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(file.readAsBytesSync());
      final codec = await decode(buffer);
      frameInfo = await codec.getNextFrame();
    } catch (error) {
      return Future.error("The following file: $file, isn't an image");
    }

    return ImageInfo(
      image: frameInfo.image,
    );
  }
}
