// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_remote_storage_manager/src/services/storage/mixin_storage_service.dart';
import 'package:act_remote_storage_manager/src/types/storage_request_result.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// [HttpFileService] that uses a [MixinStorageService] to get the download url of a file
/// based on an "url".
class StorageHttpFileService extends HttpFileService {
  /// [MixinStorageService] instance to use to get the download url of a file based on an "url".
  /// Note that the `url` might just be a id or relative path as long as it matches the
  /// format expected by the [MixinStorageService].
  final MixinStorageService _storageService;

  /// Constructor for [StorageHttpFileService].
  StorageHttpFileService({
    required MixinStorageService storageService,
  })  : _storageService = storageService,
        super();

  /// Download a file from the given [url] and return a [FileServiceResponse].
  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    /// Get the download url
    final urlResult = await _storageService.getDownloadUrl(url);

    if (urlResult.result != StorageRequestResult.success) {
      throw Exception('Error while getting download url for $url: $urlResult');
    }

    return super.get(
      urlResult.downloadUrl!,
      headers: _storageService.headers,
    );
  }
}
