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
| `minio.region`         | `string` | MinIO region (optional, default: "us-east-1")    |

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
  pageSize: 50,
  recursiveSearch: true,
);

// Download a file
final downloadResult = await storageService.getFile(
  'my-folder/my-file.pdf',
  onProgress: (progress) {
    print('Progress: ${progress.bytesTransferred}/${progress.totalBytes}');
  },
);

// Get a presigned download URL
final urlResult = await storageService.getDownloadUrl(
  'my-folder/my-file.pdf',
);
```

## Dependencies

- `minio`: MinIO client library
- `act_abstract_manager`: Base manager structure
- `act_config_manager`: Configuration management
- `act_remote_storage_manager`: Storage service interface
