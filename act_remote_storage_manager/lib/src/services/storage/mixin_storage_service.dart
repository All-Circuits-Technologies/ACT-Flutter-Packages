// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_remote_storage_manager/src/models/storage_page.dart';
import 'package:act_remote_storage_manager/src/models/transfer_progress.dart';
import 'package:act_remote_storage_manager/src/types/storage_request_result.dart';
import 'package:path_provider/path_provider.dart';

/// Callback for the progress of a transfer.
typedef OnProgressCallback = void Function(TransferProgress progress);

/// Abstract class for a storage service. Note that in this file, a file is identified by a
/// `fileId`.
/// The exact meaning depends on the implementation, it can be a path, an url, an id, etc.
mixin MixinStorageService on AbsWithLifeCycle {
  /// Default page size
  static const int defaultPageSize = 50;

  /// Provide a cache directory to store downloaded files. Can be used by the implementation when
  /// `directory` is not provided in below methods.
  ///
  /// Note that the cache directory is not guaranteed to be persistent and might be deleted by
  /// the system.
  ///
  /// Note that the [getApplicationCacheDirectory] might raise a [MissingPlatformDirectoryException]
  /// See [https://pub.dev/documentation/path_provider/latest/path_provider/MissingPlatformDirectoryException-class.html]
  static Future<Directory> getDownloadsDirectory() async => getApplicationCacheDirectory();

  /// Headers to be used in requests. This can be overridden by the implementation.
  Map<String, String>? get headers => null;

  /// Get the download url of a file based on a [fileId].
  Future<({StorageRequestResult result, String? downloadUrl})> getDownloadUrl(
    String fileId,
  );

  /// Download a file based on a [fileId] in a [directory].
  Future<({StorageRequestResult result, File? file})> getFile(
    String fileId, {
    Directory? directory,
    OnProgressCallback? onProgress,
  });

  /// Get a [StoragePage] of files in a [searchPath] with a [pageSize] and a [nextToken].
  Future<({StorageRequestResult result, StoragePage? page})> listFiles(
    String searchPath, {
    int? pageSize,
    String? nextToken,
    bool recursiveSearch,
  });
}
