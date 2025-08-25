<!--
SPDX-FileCopyrightText: 2024 All Circuits Technologies <dev@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# Act Azure Blob Storage <!-- omit from toc -->

This package provides a simple way to interact with the Azure Blob Storage
service. It implements the `MixinStorageService` interface from the
`act_server_storage_manager` package.

## Table of contents <!-- omit from toc -->

- [Features](#features)
- [Documentation](#documentation)
- [Setup](#setup)
- [Usage](#usage)

## Features

The features of this package are the ones described in the `act_server_storage_manager` since
this package is an implementation of the `MixinStorageService` interface.

In summary, it provides basic methods to list, download and get download URLs for files from an
Azure Blob Storage container.

## Documentation

Here is a class diagram of the package:

```
┌─────────────────────────────────┐
│        AbsWithLifeCycle         │
└─────────────┬───────────────────┘
              │
              │ extends
              │
┌─────────────▼───────────────────┐    ┌─────────────────────────────────┐
│   AzureBlobStorageService       │◄───┤       MixinStorageService       │
│                                 │    │                                 │
│ - connectionString: String      │    │ + getDownloadUrl(): Future      │
│ - containerName: String         │    │ + getFile(): Future             │
│ - _blobServiceClient: Client    │    │ + listFiles(): Future           │
│                                 │    └─────────────────────────────────┘
│ + listFiles(): Future           │
│ + getFile(): Future             │
│ + getDownloadUrl(): Future      │
└─────────────────────────────────┘
```

The `AzureBlobStorageService` class extends `AbsWithLifeCycle` and mixes in `MixinStorageService`
to provide Azure Blob Storage functionality. It uses the Azure Storage Blobs SDK to interact
with Azure Storage.

## Setup

To use this package, you need:

1. An Azure Storage Account
2. A Blob Container in your storage account
3. Connection string or access keys for your storage account

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  act_azure_blob_storage:
    path: ../act_azure_blob_storage
```

## Usage

### Basic Setup

```dart
import 'package:act_azure_blob_storage/act_azure_blob_storage.dart';

// Create the service
final azureService = AzureBlobStorageService(
  connectionString: 'your_azure_storage_connection_string',
  containerName: 'your_container_name',
);

// Initialize the service
await azureService.initLifeCycle();
```

### Using with ServerStorageManager

This service is designed to work with the `AbsServerStorageManager`:

```dart
import 'package:act_server_storage_manager/act_server_storage_manager.dart';
import 'package:act_azure_blob_storage/act_azure_blob_storage.dart';

// Create your storage manager implementation
class MyServerStorageManager extends AbsServerStorageManager {
  final AzureBlobStorageService _storageService;
  
  MyServerStorageManager(this._storageService);
  
  @override
  MixinStorageService getStorageService() => _storageService;
  
  @override
  CacheStorageConfig getStorageConfig() => CacheStorageConfig(
    cacheKey: 'azure_cache',
    stalePeriod: const Duration(hours: 1),
    maxCachedFiles: 100,
  );
}

// Usage
final azureService = AzureBlobStorageService(
  connectionString: 'your_connection_string',
  containerName: 'your_container',
);

final storageManager = MyServerStorageManager(azureService);
await storageManager.initLifeCycle();

// Now you can use the storage manager with caching capabilities
final result = await storageManager.getFile('path/to/file.txt');
```

### Direct Usage Examples

#### List Files

```dart
final result = await azureService.listFiles(
  'folder/path',
  pageSize: 20,
  recursiveSearch: true,
);

if (result.result == StorageRequestResult.success) {
  final page = result.page!;
  for (final file in page.items) {
    print('File: ${file.path}, Size: ${file.size}');
  }
}
```

#### Download File

```dart
final result = await azureService.getFile(
  'path/to/file.txt',
  onProgress: (progress) {
    print('Downloaded: ${(progress.progress * 100).toStringAsFixed(1)}%');
  },
);

if (result.result == StorageRequestResult.success) {
  final file = result.file!;
  print('File downloaded to: ${file.path}');
}
```

#### Get Download URL

```dart
final result = await azureService.getDownloadUrl('path/to/file.txt');

if (result.result == StorageRequestResult.success) {
  final url = result.downloadUrl!;
  print('Download URL: $url');
  // URL is valid for 1 hour by default
}
```

### Configuration

The service requires:

- **connectionString**: Azure Storage Account connection string
- **containerName**: Name of the blob container to access

The connection string can be found in your Azure Portal under Storage Account > Access keys.

### Error Handling

The service maps Azure-specific errors to the standard `StorageRequestResult` enum:

- `StorageRequestResult.success`: Operation completed successfully
- `StorageRequestResult.accessDenied`: Authentication or authorization failed (401, 403)
- `StorageRequestResult.ioError`: File not found (404) or local I/O issues
- `StorageRequestResult.genericError`: Other errors

### Logging

The service uses the ACT logging framework with the category "azureblob". Make sure to initialize
the logger manager in your application.