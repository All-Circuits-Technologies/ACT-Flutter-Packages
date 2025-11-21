<!--
SPDX-FileCopyrightText: 2025 Théo Magne <theo.magne@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT MinIO Manager

This package provides a manager and service to interact with MinIO object storage.

## Features

- **MinIO Manager**: Manages the MinIO client lifecycle and configuration
- **MinIO Storage Service**: Implements the `MixinStorageService` interface for storage operations
- **Configuration Integration**: Uses `act_config_manager` for MinIO credentials and endpoint configuration
- **File Operations**:
  - List files with recursive search support
  - Download files with progress tracking
  - Upload files with progress tracking
  - Generate presigned download URLs (5-minute expiry)
  - Delete single or multiple objects
- **Error Handling**: Proper error mapping to `StorageRequestResult` enum values

## Usage

### Configuration

The package uses the `act_config_manager` to retrieve MinIO configuration. Add the following configuration variables to your config:

| Key                    | Type     | Description                                      |
| ---------------------- | -------- | ------------------------------------------------ |
| `minio.endpoint`       | `string` | MinIO server endpoint (e.g., "play.min.io")      |
| `minio.port`           | `int`    | MinIO server port (default: 9000)                |
| `minio.accessKey`      | `string` | MinIO access key                                 |
| `minio.secretKey`      | `string` | MinIO secret key                                 |
| `minio.bucket`         | `string` | Default bucket name                              |
| `minio.useSSL`         | `bool`   | Use SSL for connections (default: true)          |

### Manager Setup

Create a concrete implementation of `MinioManager`:

```dart
class MyMinioManager extends MinioManager<MyConfigManager> {
  MyMinioManager();
}

// Register in your app
final minioBuilder = MinioBuilder<MyMinioManager, MyConfigManager>(
  () => MyMinioManager(),
);
```

### Using the Storage Service

The `MinioStorageService` can be used with the `AbsRemoteStorageManager`:

```dart
// Get the service from the manager
final storageService = globalGetIt().get<MyMinioManager>().storageService;

// List files in a bucket path
final result = await storageService.listFiles(
  'my-folder/',
  recursiveSearch: true,
);

if (result.result == StorageRequestResult.success) {
  final files = result.page?.items ?? [];
  print('Found ${files.length} files');
}

// Download a file
final downloadResult = await storageService.getFile(
  'my-folder/my-file.pdf',
  onProgress: (progress) {
    print('Progress: ${progress.bytesTransferred}/${progress.totalBytes}');
  },
);

if (downloadResult.result == StorageRequestResult.success) {
  print('Downloaded to: ${downloadResult.file?.path}');
}

// Upload a file
final uploadResult = await storageService.putFile(
  'my-folder/uploaded-file.pdf',
  File('/path/to/local/file.pdf'),
  metadata: {'content-type': 'application/pdf'},
  onProgress: (progress) {
    print('Upload progress: ${progress.bytesTransferred}/${progress.totalBytes}');
  },
);

if (uploadResult.result == StorageRequestResult.success) {
  print('Uploaded with ETag: ${uploadResult.etag}');
}

// Get a presigned download URL (valid for 5 minutes)
final urlResult = await storageService.getDownloadUrl(
  'my-folder/my-file.pdf',
);

if (urlResult.result == StorageRequestResult.success) {
  print('Download URL: ${urlResult.downloadUrl}');
}

// Delete a single object
final deleteResult = await storageService.removeObject(
  'my-folder/file-to-delete.pdf',
);

// Delete multiple objects
final bulkDeleteResult = await storageService.removeObjects([
  'my-folder/file1.pdf',
  'my-folder/file2.pdf',
  'my-folder/file3.pdf',
]);
```

## Dependencies

- `minio`: MinIO client library
- `act_abstract_manager`: Base manager structure
- `act_config_manager`: Configuration management
- `act_remote_storage_manager`: Storage service interface
