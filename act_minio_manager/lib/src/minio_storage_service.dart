// SPDX-FileCopyrightText: 2025 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';
import 'dart:typed_data';

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
      _logsHelper.d(
          'Listing files in path: $searchPath (recursive: $recursiveSearch)');

      // Use listAllObjects to get all objects at once
      // MinIO's listObjects returns Stream<ListObjectsResult> where each result contains List<Object>
      final result = await _minioClient.listAllObjects(
        config.bucket,
        prefix: searchPath,
        recursive: recursiveSearch,
      );

      // Convert MinIO Object instances to StorageFile objects
      final storageFiles = result.objects
          .map((obj) => StorageFile(
                path: obj.key ?? '',
                lastModified: obj.lastModified,
                size: obj.size ?? 0,
                eTag: obj.eTag,
              ))
          .toList();

      // Note: MinIO doesn't have built-in pagination like S3 with continuation tokens
      // For large buckets, consider using the streaming listObjects method instead
      final storagePage = StoragePage(
        items: storageFiles,
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
      final intermediateDirectory =
          filepath.substring(0, filepath.lastIndexOf('/'));

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
      _logsHelper
          .e('MinIO error while getting download URL for file $fileId: $e');
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

  /// Upload a file to MinIO storage
  ///
  /// Returns the ETag of the uploaded object on success
  Future<({StorageRequestResult result, String? etag})> putFile(
    String objectPath,
    File file, {
    Map<String, String>? metadata,
    void Function(TransferProgress)? onProgress,
  }) async {
    try {
      _logsHelper.d('Uploading file to: $objectPath');

      final fileSize = await file.length();
      final stream = file.openRead().cast<Uint8List>();

      var bytesTransferred = 0;
      var trackedStream = stream;

      if (onProgress != null) {
        trackedStream = stream.map((chunk) {
          bytesTransferred += chunk.length;
          onProgress(TransferProgress(
            totalBytes: fileSize,
            bytesTransferred: bytesTransferred,
            transferStatus: TransferStatus.inProgress,
          ));
          return chunk;
        });
      }

      final etag = await _minioClient.putObject(
        config.bucket,
        objectPath,
        trackedStream,
        size: fileSize,
        metadata: metadata,
      );

      if (onProgress != null) {
        onProgress(TransferProgress(
          totalBytes: fileSize,
          bytesTransferred: fileSize,
          transferStatus: TransferStatus.success,
        ));
      }

      _logsHelper.d('Successfully uploaded file to: $objectPath');

      return (result: StorageRequestResult.success, etag: etag);
    } on MinioError catch (e) {
      _logsHelper.e('MinIO error while uploading file to $objectPath: $e');
      return (result: _parseMinioError(e), etag: null);
    } on Exception catch (e) {
      _logsHelper.e('Error while uploading file to $objectPath: $e');
      return (result: StorageRequestResult.genericError, etag: null);
    }
  }

  /// Delete an object from MinIO storage
  Future<StorageRequestResult> removeObject(String objectPath) async {
    try {
      _logsHelper.d('Removing object: $objectPath');

      await _minioClient.removeObject(config.bucket, objectPath);

      _logsHelper.d('Successfully removed object: $objectPath');

      return StorageRequestResult.success;
    } on MinioError catch (e) {
      _logsHelper.e('MinIO error while removing object $objectPath: $e');
      return _parseMinioError(e);
    } on Exception catch (e) {
      _logsHelper.e('Error while removing object $objectPath: $e');
      return StorageRequestResult.genericError;
    }
  }

  /// Delete multiple objects from MinIO storage
  Future<StorageRequestResult> removeObjects(List<String> objectPaths) async {
    try {
      _logsHelper.d('Removing ${objectPaths.length} objects');

      await _minioClient.removeObjects(config.bucket, objectPaths);

      _logsHelper.d('Successfully removed ${objectPaths.length} objects');

      return StorageRequestResult.success;
    } on MinioError catch (e) {
      _logsHelper.e('MinIO error while removing objects: $e');
      return _parseMinioError(e);
    } on Exception catch (e) {
      _logsHelper.e('Error while removing objects: $e');
      return StorageRequestResult.genericError;
    }
  }

  /// Parse MinIO errors and convert them to StorageRequestResult
  StorageRequestResult _parseMinioError(MinioError error) {
    // Check for common MinIO error codes
    if (error.message?.contains('NoSuchKey') == true ||
        error.message?.contains('NoSuchBucket') == true) {
      // Map not found to ioError as there's no notFound in the enum
      return StorageRequestResult.ioError;
    }

    if (error.message?.contains('AccessDenied') == true ||
        error.message?.contains('InvalidAccessKeyId') == true ||
        error.message?.contains('SignatureDoesNotMatch') == true) {
      return StorageRequestResult.accessDenied;
    }

    // Network errors are mapped to genericError
    return StorageRequestResult.genericError;
  }

  /// {@macro act_abstract_manager.AbsWithLifeCycle.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    _logsHelper.d('Disposing MinIO storage service...');
    await super.disposeLifeCycle();
  }
}
