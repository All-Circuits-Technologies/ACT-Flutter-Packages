// SPDX-FileCopyrightText: 2024 All Circuits Technologies <dev@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_storage_manager/act_server_storage_manager.dart';
import 'package:azure_storage_blobs/azure_storage_blobs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// This service manages the Azure Blob Storage
///
/// This Storage regroups multiple method to interact with Azure Blob storage. It implements the
/// [MixinStorageService] therefore it can be used with the [AbsServerStorageManager] which provides
/// an optional cache system.
class AzureBlobStorageService extends AbsWithLifeCycle with MixinStorageService {
  /// Logs category for the azure blob storage service
  static const _logsCategory = "azureblob";

  /// The service logs helper
  late final LogsHelper _logsHelper;

  /// Azure Blob Storage client
  late final BlobServiceClient _blobServiceClient;

  /// The name of the container to use
  final String containerName;

  /// The connection string for Azure Storage Account
  final String connectionString;

  /// Class constructor
  AzureBlobStorageService({
    required this.connectionString,
    required this.containerName,
  }) : super();

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    _logsHelper = LogsHelper(appLogger(), _logsCategory);
    
    // Initialize Azure Blob Storage client
    _blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);
  }

  /// List all files in a given path
  @override
  Future<({StorageRequestResult result, StoragePage? page})> listFiles(
    String searchPath, {
    int? pageSize,
    String? nextToken,
    bool recursiveSearch = false,
  }) async {
    try {
      final containerClient = _blobServiceClient.getBlobContainerClient(containerName);
      
      // Normalize the search path - remove leading/trailing slashes and ensure it ends with /
      String prefix = searchPath.trim();
      if (prefix.startsWith('/')) {
        prefix = prefix.substring(1);
      }
      if (prefix.isNotEmpty && !prefix.endsWith('/')) {
        prefix = '$prefix/';
      }

      final List<StorageFile> storageFiles = [];
      
      // List blobs with the given prefix
      await for (final blobItem in containerClient.listBlobs(prefix: prefix)) {
        // If not recursive search, skip files in subdirectories
        if (!recursiveSearch && prefix.isNotEmpty) {
          final relativePath = blobItem.name.substring(prefix.length);
          if (relativePath.contains('/')) {
            continue;
          }
        }

        storageFiles.add(StorageFile(
          path: blobItem.name,
          lastModified: blobItem.properties.lastModified,
          size: blobItem.properties.contentLength?.toInt(),
          eTag: blobItem.properties.eTag,
        ));
      }

      // Apply pagination manually since Azure SDK doesn't directly support limit
      final int actualPageSize = pageSize ?? MixinStorageService.defaultPageSize;
      final int startIndex = nextToken != null ? int.tryParse(nextToken) ?? 0 : 0;
      final int endIndex = (startIndex + actualPageSize).clamp(0, storageFiles.length);
      
      final pageItems = storageFiles.sublist(startIndex, endIndex);
      final bool hasNextPage = endIndex < storageFiles.length;
      final String? nextPageToken = hasNextPage ? endIndex.toString() : null;

      final storagePage = StoragePage(
        items: pageItems,
        nextPageToken: nextPageToken,
        hasNextPage: hasNextPage,
      );

      return (result: StorageRequestResult.success, page: storagePage);
    } on Exception catch (e) {
      _logsHelper.e('Error while listing files in path $searchPath: $e');
      return (result: _parseException(e), page: null);
    }
  }

  /// Download a file from a given path and save it in the specified directory.
  /// The [path] of the file must be given from the root of the container and the [onProgress] 
  /// callback can be passed to track the download progress.
  @override
  Future<({StorageRequestResult result, File? file})> getFile(
    String filePath, {
    Directory? directory,
    void Function(TransferProgress)? onProgress,
  }) async {
    try {
      // getDownloadsDirectory might raise a MissingPlatformDirectoryException
      directory ??= await MixinStorageService.getDownloadsDirectory();

      // Normalize the file path - remove leading slash
      String normalizedPath = filePath.trim();
      if (normalizedPath.startsWith('/')) {
        normalizedPath = normalizedPath.substring(1);
      }

      final containerClient = _blobServiceClient.getBlobContainerClient(containerName);
      final blobClient = containerClient.getBlobClient(normalizedPath);

      // Create the local file path
      final fileName = path.basename(normalizedPath);
      final localFilePath = path.join(directory.path, fileName);
      final intermediateDirectory = path.dirname(localFilePath);

      // Create the intermediate directory if needed
      await Directory(intermediateDirectory).create(recursive: true);

      // Get blob properties to get the size for progress tracking
      final blobProperties = await blobClient.getProperties();
      final int? totalBytes = blobProperties.contentLength?.toInt();

      // Download the blob
      final downloadResponse = await blobClient.download();
      final localFile = File(localFilePath);
      final sink = localFile.openWrite();

      int bytesTransferred = 0;
      
      onProgress?.call(TransferProgress(
        bytesTransferred: 0,
        totalBytes: totalBytes ?? -1,
        transferStatus: TransferStatus.inProgress,
      ));

      await for (final chunk in downloadResponse) {
        sink.add(chunk);
        bytesTransferred += chunk.length;
        
        onProgress?.call(TransferProgress(
          bytesTransferred: bytesTransferred,
          totalBytes: totalBytes ?? -1,
          transferStatus: TransferStatus.inProgress,
        ));
      }

      await sink.close();

      onProgress?.call(TransferProgress(
        bytesTransferred: bytesTransferred,
        totalBytes: totalBytes ?? -1,
        transferStatus: TransferStatus.success,
      ));

      _logsHelper.d('Downloaded file $filePath to ${localFile.path}');

      return (result: StorageRequestResult.success, file: localFile);
    } on Exception catch (e) {
      _logsHelper.e('Error while downloading file $filePath to directory $directory: $e');
      
      // Call progress callback with failure status if provided
      onProgress?.call(TransferProgress(
        bytesTransferred: 0,
        totalBytes: -1,
        transferStatus: TransferStatus.failure,
      ));

      return (result: _parseException(e), file: null);
    }
  }

  /// Get a download URL for a file. The path of the file must be given from the root
  /// of the container.
  @override
  Future<({StorageRequestResult result, String? downloadUrl})> getDownloadUrl(
    String fileId,
  ) async {
    try {
      // Normalize the file path - remove leading slash
      String normalizedPath = fileId.trim();
      if (normalizedPath.startsWith('/')) {
        normalizedPath = normalizedPath.substring(1);
      }

      final containerClient = _blobServiceClient.getBlobContainerClient(containerName);
      final blobClient = containerClient.getBlobClient(normalizedPath);

      // Generate a SAS URL with read permissions valid for 1 hour
      final sasUri = blobClient.generateSasUri(
        permissions: BlobSasPermissions()..read = true,
        expiresOn: DateTime.now().add(const Duration(hours: 1)),
      );

      _logsHelper.d('Generated download URL for file $fileId: $sasUri');

      return (result: StorageRequestResult.success, downloadUrl: sasUri.toString());
    } on Exception catch (e) {
      _logsHelper.e('Error while getting a download URL for file $fileId: $e');
      return (result: _parseException(e), downloadUrl: null);
    }
  }

  /// Parse the exception to return the right result
  static StorageRequestResult _parseException(Exception e) {
    if (e is MissingPlatformDirectoryException) {
      return StorageRequestResult.ioError;
    }

    // Azure-specific exceptions
    if (e is BlobStorageException) {
      switch (e.statusCode) {
        case 401:
        case 403:
          return StorageRequestResult.accessDenied;
        case 404:
          return StorageRequestResult.ioError;
        default:
          return StorageRequestResult.genericError;
      }
    }

    if (e is SocketException || e is FileSystemException) {
      return StorageRequestResult.ioError;
    }

    return StorageRequestResult.genericError;
  }
}