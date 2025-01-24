// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_server_storage_ui/src/image/storage_manager_image_provider.dart';
import 'package:act_server_storage_ui/src/mixins/mixin_image_cache_service.dart';
import 'package:flutter/material.dart';

/// This displays an image from the [MixinImageCacheService] storage manager.
///
/// While the image is loading: [placeholderBuilder] (if not null) may display a loading widget.
/// If an error occurred in the loading, [errorBuilder] is called (if not null).
class StorageManagerImage<S extends MixinImageCacheService> extends StatelessWidget {
  /// The image file id to display
  final String fileId;

  /// True to use the server storage cache
  final bool useCache;

  /// This is the width to apply to the image
  final double? width;

  /// This is the height to apply to the image
  final double? height;

  /// This is the box fit to use when displaying the image in the given size
  final BoxFit? fit;

  /// If not null, this is called when the image failed to load, in order to display an error
  /// widget.
  final ImageErrorWidgetBuilder? errorBuilder;

  /// If not null, this is called to display a temporary widget when the image is loading
  final Widget Function(BuildContext context)? placeholderBuilder;

  /// Class constructor
  const StorageManagerImage({
    super.key,
    required this.fileId,
    this.width,
    this.height,
    this.fit,
    this.errorBuilder,
    this.placeholderBuilder,
    this.useCache = true,
  });

  /// Build the image
  @override
  Widget build(BuildContext context) => Image(
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        frameBuilder: placeholderBuilder != null
            ? (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) {
                  return child;
                }

                RawImage? image;
                // If the image is not excluded from semantics the child is a Semantics
                if (child is Semantics && child.child != null && child.child is RawImage) {
                  image = child.child! as RawImage;
                }
                // If the image is excluded from semantics the child is a RawImage
                else if (child is RawImage) {
                  image = child;
                }

                if (image != null && image.image != null) {
                  return child;
                }

                return placeholderBuilder!(context);
              }
            : null,
        image: StorageManagerImageProvider<S>(
          fileId: fileId,
          maxWidth: width,
          maxHeight: height,
          devicePixelRatio: MediaQuery.maybeOf(context)?.devicePixelRatio,
        ),
        errorBuilder: errorBuilder,
      );
}
