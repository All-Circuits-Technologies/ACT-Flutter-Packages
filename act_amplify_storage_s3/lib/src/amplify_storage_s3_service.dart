// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:io';

import 'package:act_amplify_core/act_amplify_core.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_storage_manager/act_server_storage_manager.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:path_provider/path_provider.dart';

/// This service manages the Amplify Storage S3 part of Amplify
///
/// This Storage regroups multiple method to interact with S3 storage. It implements the
/// [MixinStorageService] therefore it can be used with the [AbsServerStorageManager] which provides
/// an optional cache system.
class AmplifyStorageS3Service extends AbsAmplifyService with MixinStorageService {
  /// Logs category for the amplify storage s3 service
  static const _logsCategory = "storages3";

  /// The service logs helper
  late final LogsHelper _logsHelper;

  /// Class constructor
  AmplifyStorageS3Service() : super();

  /// Initialize the service by creating the logs helper
  @override
  Future<void> initService({LogsHelper? parentLogsHelper}) async {
    _logsHelper = AbsAmplifyService.createLogsHelper(
      logCategory: _logsCategory,
      parentLogsHelper: parentLogsHelper,
    );
  }

  /// List all files in a given path
  @override
  Future<(StorageRequestResult, StoragePage?)> listFiles(
    String searchPath, {
    int? pageSize,
    String? nextToken,
    bool recursiveSearch = false,
  }) async {
    StorageListResult<StorageItem> listResult;

    // Try to call the list method from the Amplify Storage plugin
    try {
      // List the files in the path
      listResult = await Amplify.Storage.list(
        path: StoragePath.fromString(searchPath),
        options: StorageListOptions(
          pageSize: pageSize ?? MixinStorageService.defaultPageSize,
          nextToken: nextToken,
          pluginOptions: S3ListPluginOptions(
            excludeSubPaths: !recursiveSearch,
          ),
        ),
      ).result;
    } on Exception catch (e) {
      _logsHelper.e('Error while listing files in path $searchPath: $e');
      return (_parseException(e), null);
    }

    // Create a list of StorageFile from the list of StorageItem
    final storageFiles = listResult.items
        .map((item) => StorageFile(
              path: item.path,
              lastModified: item.lastModified,
              size: item.size,
              eTag: item.eTag,
            ))
        .toList();

    final storagePage = StoragePage(
      items: storageFiles,
      nextPageToken: listResult.nextToken,
      hasNextPage: listResult.hasNextPage,
    );

    return (StorageRequestResult.success, storagePage);
  }

  /// Download a file from a given path and save it in the specified directory.
  /// The [path] of the file must be given from the root of the bucket and the [onProgress] callback
  /// can be passed to track the download progress.
  @override
  Future<(StorageRequestResult, File?)> getFile(
    String path, {
    Directory? directory,
    void Function(TransferProgress)? onProgress,
  }) async {
    StorageDownloadFileResult<StorageItem> dlResult;

    try {
      // getDownloadsDirectory might raise a MissingPlatformDirectoryException
      directory ??= await MixinStorageService.getDownloadsDirectory();

      // Create the file path
      final filepath = '${directory.path}/$path';
      final intermediateDirectory = filepath.substring(0, filepath.lastIndexOf('/'));

      // Create the intermediate directory if needed
      await Directory(intermediateDirectory).create(recursive: true);

      // Create the local file that will be used by Amplify to download the file
      final localFile = AWSFile.fromPath(filepath);

      // Create a callback to adapt the amplify progress cb to the act one
      final amplifyOnProgress = onProgress == null
          ? null
          : (StorageTransferProgress progress) {
              onProgress(TransferProgress(
                totalBytes: progress.totalBytes,
                bytesTransferred: progress.transferredBytes,
                transferStatus: _adaptTransferState(progress.state),
              ));
            };

      // Download the file
      dlResult = await Amplify.Storage.downloadFile(
        localFile: localFile,
        path: StoragePath.fromString(path),
        onProgress: amplifyOnProgress,
      ).result;
    } on Exception catch (e) {
      _logsHelper.e('Error while downloading file $path to directory $directory: $e');
      return (_parseException(e), null);
    }

    _logsHelper.d('Download file $path to directory $directory: $dlResult');

    return (StorageRequestResult.success, File(dlResult.localFile.path!));
  }

  /// Get a download URL for a file. The path of the file must be given from the root
  /// of the bucket.
  @override
  Future<(StorageRequestResult, String?)> getDownloadUrl(
    String fileId,
  ) async {
    StorageGetUrlResult urlResult;

    try {
      urlResult = await Amplify.Storage.getUrl(
          path: StoragePath.fromString(fileId),
          options: const StorageGetUrlOptions(
            pluginOptions: S3GetUrlPluginOptions(
              expiresIn: Duration(minutes: 5),
              validateObjectExistence: true,
            ),
          )).result;
    } on Exception catch (e) {
      _logsHelper.e('Error while getting a download URL for file $fileId: $e');
      return (_parseException(e), null);
    }

    _logsHelper.d('Get a download URL for file $fileId: $urlResult');

    final downloadUrl = urlResult.url.toString();

    return (StorageRequestResult.success, downloadUrl);
  }

  /// Adapt an amplify [StorageTransferState] to an act storage [TransferStatus]
  static TransferStatus _adaptTransferState(StorageTransferState state) {
    switch (state) {
      case StorageTransferState.inProgress:
        return TransferStatus.inProgress;
      case StorageTransferState.canceled:
        return TransferStatus.canceled;
      case StorageTransferState.failure:
        return TransferStatus.failure;
      case StorageTransferState.success:
        return TransferStatus.success;
      case StorageTransferState.paused:
        return TransferStatus.paused;
    }
  }

  /// Parse the exception to return the right result
  static StorageRequestResult _parseException(Exception e) {
    if (e is MissingPlatformDirectoryException) {
      return StorageRequestResult.ioError;
    }

    if (e is StorageAccessDeniedException) {
      return StorageRequestResult.accessDenied;
    }

    if (e is SessionExpiredException) {
      return StorageRequestResult.accessDenied;
    }

    return StorageRequestResult.genericError;
  }

  /// Most of the time, we don't need to pass particular configuration to the plugin (all is done on
  /// the server). But, if needed, this method can be overridden by a derived class in the project
  /// if needed to set a particular configuration to the plugin.
  @override
  Future<List<AmplifyPluginInterface>> getLinkedPluginsList() async => [
        AmplifyStorageS3(),
      ];
}
