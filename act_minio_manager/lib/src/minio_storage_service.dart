// SPDX-FileCopyrightText: 2025 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_minio_manager/src/models/minio_config_model.dart';
import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:minio/minio.dart';

/// Service that provides MinIO storage operations
///
/// This service implements the [MixinStorageService] interface and can be used
/// with the [AbsRemoteStorageManager] to provide caching capabilities.
class MinioStorageService extends AbsWithLifeCycle with MixinStorageService {
  /// Logs category for the MinIO storage service
  static const _logsCategory = "minio_storage";

  /// Default presigned URL expiry duration (5 minutes)
  static const _defaultUrlExpiry = Duration(minutes: 5);

  /// The service logs helper
  late final LogsHelper _logsHelper;

  /// The MinIO client instance
  late final Minio _minioClient;

  /// The configuration for this service
  final MinioConfigModel config;

  /// Class constructor
  MinioStorageService({
    required this.config,
    required LogsHelper parentLogsHelper,
  }) {
    _logsHelper = parentLogsHelper.createASubLogsHelper(_logsCategory);
  }

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _logsHelper.d('Initializing MinIO storage service...');

    // Create the MinIO client
    _minioClient = Minio(
      endPoint: config.endpoint,
      port: config.port,
      accessKey: config.accessKey,
      secretKey: config.secretKey,
      useSSL: config.useSSL,
      region: config.region,
    );

    _logsHelper.i('MinIO storage service initialized successfully');
  }

  /// {@macro act_remote_storage_manager.MixinStorageService.listFiles}
  @override
  Future<({StorageRequestResult result, StoragePage? page})> listFiles(
    String searchPath, {
    int? pageSize,
    String? nextToken,
    bool recursiveSearch = false,
  }) async {
    try {
      _logsHelper.d('Listing files in path: $searchPath (recursive: $recursiveSearch)');

      // MinIO's listObjects method doesn't support pagination in the same way,
      // so we'll list all objects and handle pagination manually if needed
      final objects = await _minioClient
          .listObjects(
            config.bucket,
            prefix: searchPath,
            recursive: recursiveSearch,
          )
          .toList();

      // Convert MinIO objects to StorageFile objects
      final storageFiles = objects
          .map((obj) => StorageFile(
                path: obj.key ?? '',
                lastModified: obj.lastModified,
                size: obj.size ?? 0,
                eTag: obj.eTag,
              ))
          .toList();

      // For simplicity, we're not implementing pagination with MinIO
      // as it doesn't have built-in pagination support like S3
      final storagePage = StoragePage(
        items: storageFiles,
        nextPageToken: null,
        hasNextPage: false,
      );

      _logsHelper.d('Listed ${storageFiles.length} files in path: $searchPath');

      return (result: StorageRequestResult.success, page: storagePage);
    } on MinioError catch (e) {
      _logsHelper.e('MinIO error while listing files in path $searchPath: $e');
      return (result: _parseMinioError(e), page: null);
    } on Exception catch (e) {
      _logsHelper.e('Error while listing files in path $searchPath: $e');
      return (result: StorageRequestResult.genericError, page: null);
    }
  }

  /// {@macro act_remote_storage_manager.MixinStorageService.getFile}
  @override
  Future<({StorageRequestResult result, File? file})> getFile(
    String path, {
    Directory? directory,
    void Function(TransferProgress)? onProgress,
  }) async {
    try {
      _logsHelper.d('Downloading file: $path');

      // Get the download directory
      directory ??= await MixinStorageService.getDownloadsDirectory();

      // Create the file path
      final filepath = '${directory.path}/$path';
      final intermediateDirectory = filepath.substring(0, filepath.lastIndexOf('/'));

      // Create the intermediate directory if needed
      await Directory(intermediateDirectory).create(recursive: true);

      // Download the object from MinIO
      final stream = await _minioClient.getObject(
        config.bucket,
        path,
      );

      // Create the local file
      final file = File(filepath);
      final sink = file.openWrite();

      // Track progress if callback is provided
      var bytesTransferred = 0;
      final totalBytes = await _getObjectSize(path);

      await for (final data in stream) {
        sink.add(data);
        bytesTransferred += data.length;

        if (onProgress != null && totalBytes != null) {
          onProgress(TransferProgress(
            totalBytes: totalBytes,
            bytesTransferred: bytesTransferred,
            transferStatus: TransferStatus.inProgress,
          ));
        }
      }

      await sink.close();

      if (onProgress != null && totalBytes != null) {
        onProgress(TransferProgress(
          totalBytes: totalBytes,
          bytesTransferred: bytesTransferred,
          transferStatus: TransferStatus.success,
        ));
      }

      _logsHelper.d('Successfully downloaded file: $path');

      return (result: StorageRequestResult.success, file: file);
    } on MinioError catch (e) {
      _logsHelper.e('MinIO error while downloading file $path: $e');
      return (result: _parseMinioError(e), file: null);
    } on Exception catch (e) {
      _logsHelper.e('Error while downloading file $path: $e');
      return (result: StorageRequestResult.genericError, file: null);
    }
  }

  /// {@macro act_remote_storage_manager.MixinStorageService.getDownloadUrl}
  @override
  Future<({StorageRequestResult result, String? downloadUrl})> getDownloadUrl(
    String fileId,
  ) async {
    try {
      _logsHelper.d('Getting download URL for file: $fileId');

      // Generate a presigned URL for the object
      final url = await _minioClient.presignedGetObject(
        config.bucket,
        fileId,
        expires: _defaultUrlExpiry.inSeconds,
      );

      _logsHelper.d('Successfully generated download URL for file: $fileId');

      return (result: StorageRequestResult.success, downloadUrl: url);
    } on MinioError catch (e) {
      _logsHelper.e('MinIO error while getting download URL for file $fileId: $e');
      return (result: _parseMinioError(e), downloadUrl: null);
    } on Exception catch (e) {
      _logsHelper.e('Error while getting download URL for file $fileId: $e');
      return (result: StorageRequestResult.genericError, downloadUrl: null);
    }
  }

  /// Get the size of an object from MinIO
  Future<int?> _getObjectSize(String objectName) async {
    try {
      final stat = await _minioClient.statObject(config.bucket, objectName);
      return stat.size;
    } on Exception catch (e) {
      _logsHelper.w('Could not get object size for $objectName: $e');
      return null;
    }
  }

  /// Parse MinIO errors and convert them to StorageRequestResult
  StorageRequestResult _parseMinioError(MinioError error) {
    // Check for common MinIO error codes
    if (error.message?.contains('NoSuchKey') == true ||
        error.message?.contains('NoSuchBucket') == true) {
      return StorageRequestResult.notFound;
    }

    if (error.message?.contains('AccessDenied') == true ||
        error.message?.contains('InvalidAccessKeyId') == true ||
        error.message?.contains('SignatureDoesNotMatch') == true) {
      return StorageRequestResult.accessDenied;
    }

    if (error.message?.contains('Network') == true ||
        error.message?.contains('Connection') == true) {
      return StorageRequestResult.networkError;
    }

    return StorageRequestResult.genericError;
  }

  /// {@macro act_abstract_manager.AbsWithLifeCycle.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    _logsHelper.d('Disposing MinIO storage service...');
    await super.disposeLifeCycle();
  }
}
