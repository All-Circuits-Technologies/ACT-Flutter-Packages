// SPDX-FileCopyrightText: 2024 All Circuits Technologies <dev@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_storage_manager/act_server_storage_manager.dart';
import 'package:azblob/azblob.dart';
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
  late final AzureStorage _azureStorage;

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
    _azureStorage = AzureStorage.parse(connectionString);
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
      // Normalize the search path - ensure it starts with container name
      String fullPath = '/$containerName';
      if (searchPath.isNotEmpty) {
        String normalizedPath = searchPath.trim();
        if (normalizedPath.startsWith('/')) {
          normalizedPath = normalizedPath.substring(1);
        }
        if (!normalizedPath.endsWith('/') && normalizedPath.isNotEmpty) {
          normalizedPath = '$normalizedPath/';
        }
        fullPath = '$fullPath/$normalizedPath';
      }

      // Call Azure Blob Storage list API
      final response = await _azureStorage.listBlobsRaw(fullPath);
      
      if (response.statusCode != 200) {
        final errorMessage = await response.stream.bytesToString();
        _logsHelper.e('Error listing blobs: ${response.statusCode} - $errorMessage');
        return (result: _parseHttpStatusCode(response.statusCode), page: null);
      }

      // Parse XML response
      final xmlContent = await response.stream.bytesToString();
      final storageFiles = _parseListBlobsXml(xmlContent, searchPath, recursiveSearch);

      // Apply pagination manually since Azure API doesn't directly support our pagination model
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
  /// The [filePath] of the file must be given from the root of the container and the [onProgress] 
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

      // Normalize the file path - ensure it starts with container name
      String fullPath = '/$containerName';
      if (filePath.isNotEmpty) {
        String normalizedPath = filePath.trim();
        if (normalizedPath.startsWith('/')) {
          normalizedPath = normalizedPath.substring(1);
        }
        fullPath = '$fullPath/$normalizedPath';
      }

      // Create the local file path
      final fileName = path.basename(filePath);
      final localFilePath = path.join(directory.path, fileName);
      final intermediateDirectory = path.dirname(localFilePath);

      // Create the intermediate directory if needed
      await Directory(intermediateDirectory).create(recursive: true);

      // Download the blob
      final response = await _azureStorage.getBlob(fullPath);
      
      if (response.statusCode != 200) {
        final errorMessage = await response.stream.bytesToString();
        _logsHelper.e('Error downloading blob: ${response.statusCode} - $errorMessage');
        
        onProgress?.call(TransferProgress(
          bytesTransferred: 0,
          totalBytes: -1,
          transferStatus: TransferStatus.failure,
        ));
        
        return (result: _parseHttpStatusCode(response.statusCode), file: null);
      }

      final localFile = File(localFilePath);
      final sink = localFile.openWrite();

      // Get content length from headers for progress tracking
      final contentLengthHeader = response.headers['content-length'];
      final int? totalBytes = contentLengthHeader != null ? int.tryParse(contentLengthHeader) : null;
      
      int bytesTransferred = 0;
      
      onProgress?.call(TransferProgress(
        bytesTransferred: 0,
        totalBytes: totalBytes ?? -1,
        transferStatus: TransferStatus.inProgress,
      ));

      await for (final chunk in response.stream) {
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
      // Normalize the file path - ensure it starts with container name
      String fullPath = '/$containerName';
      if (fileId.isNotEmpty) {
        String normalizedPath = fileId.trim();
        if (normalizedPath.startsWith('/')) {
          normalizedPath = normalizedPath.substring(1);
        }
        fullPath = '$fullPath/$normalizedPath';
      }

      // Generate a SAS URL with read permissions valid for 1 hour
      final sasUri = await _azureStorage.getBlobLink(
        fullPath,
        expiry: DateTime.now().add(const Duration(hours: 1)),
      );

      _logsHelper.d('Generated download URL for file $fileId: $sasUri');

      return (result: StorageRequestResult.success, downloadUrl: sasUri.toString());
    } on Exception catch (e) {
      _logsHelper.e('Error while getting a download URL for file $fileId: $e');
      return (result: _parseException(e), downloadUrl: null);
    }
  }

  /// Parse the list blobs XML response to extract file information
  List<StorageFile> _parseListBlobsXml(String xmlContent, String searchPath, bool recursiveSearch) {
    final List<StorageFile> storageFiles = [];
    
    // Basic XML parsing - in a production environment, you'd want to use a proper XML parser
    final blobRegex = RegExp(r'<Blob>.*?</Blob>', dotAll: true);
    final nameRegex = RegExp(r'<Name>(.*?)</Name>');
    final lastModifiedRegex = RegExp(r'<Last-Modified>(.*?)</Last-Modified>');
    final contentLengthRegex = RegExp(r'<Content-Length>(\d+)</Content-Length>');
    final eTagRegex = RegExp(r'<Etag>(.*?)</Etag>');

    final blobMatches = blobRegex.allMatches(xmlContent);
    
    for (final match in blobMatches) {
      final blobXml = match.group(0)!;
      
      final nameMatch = nameRegex.firstMatch(blobXml);
      if (nameMatch == null) continue;
      
      String blobName = nameMatch.group(1)!;
      
      // Remove container prefix if present
      if (blobName.startsWith('$containerName/')) {
        blobName = blobName.substring(containerName.length + 1);
      }
      
      // Filter based on search path and recursive search
      if (searchPath.isNotEmpty) {
        String normalizedSearchPath = searchPath.trim();
        if (normalizedSearchPath.startsWith('/')) {
          normalizedSearchPath = normalizedSearchPath.substring(1);
        }
        if (!normalizedSearchPath.endsWith('/') && normalizedSearchPath.isNotEmpty) {
          normalizedSearchPath = '$normalizedSearchPath/';
        }
        
        if (!blobName.startsWith(normalizedSearchPath)) {
          continue;
        }
        
        // If not recursive search, skip files in subdirectories
        if (!recursiveSearch) {
          final relativePath = blobName.substring(normalizedSearchPath.length);
          if (relativePath.contains('/')) {
            continue;
          }
        }
      }

      final lastModifiedMatch = lastModifiedRegex.firstMatch(blobXml);
      final contentLengthMatch = contentLengthRegex.firstMatch(blobXml);
      final eTagMatch = eTagRegex.firstMatch(blobXml);

      storageFiles.add(StorageFile(
        path: blobName,
        lastModified: lastModifiedMatch != null ? DateTime.tryParse(lastModifiedMatch.group(1)!) : null,
        size: contentLengthMatch != null ? int.tryParse(contentLengthMatch.group(1)!) : null,
        eTag: eTagMatch?.group(1),
      ));
    }

    return storageFiles;
  }

  /// Parse HTTP status code to storage request result
  static StorageRequestResult _parseHttpStatusCode(int statusCode) {
    switch (statusCode) {
      case 401:
      case 403:
        return StorageRequestResult.accessDenied;
      case 404:
        return StorageRequestResult.ioError;
      default:
        return StorageRequestResult.genericError;
    }
  }

  /// Parse the exception to return the right result
  static StorageRequestResult _parseException(Exception e) {
    if (e is MissingPlatformDirectoryException) {
      return StorageRequestResult.ioError;
    }

    // Azure-specific exceptions
    if (e is AzureStorageException) {
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