// SPDX-FileCopyrightText: 2025 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

// ignore_for_file: avoid_print, unused_local_variable: Example code for demonstration purposes

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_minio_manager/act_minio_manager.dart';
import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';

/// Example configuration manager that includes MinIO configuration
class ExampleConfigManager extends AbstractConfigManager
    with MixinMinioConfig, MixinLoggerConfig {
  // Add other configuration as needed
}

/// Builder for ExampleConfigManager
class ExampleConfigBuilder extends AbstractConfigBuilder<ExampleConfigManager> {
  ExampleConfigBuilder() : super(ExampleConfigManager.new);
}

/// Example MinIO manager implementation
class ExampleMinioManager extends MinioManager<ExampleConfigManager> {
  ExampleMinioManager();
}

/// Example global manager
class ExampleGlobalManager extends GlobalManager {
  static ExampleGlobalManager get instance {
    if (GlobalManager.instance == null) {
      GlobalManager.setInstance = ExampleGlobalManager._create();
      GlobalManager.instance!.init();
    }
    return GlobalManager.instance! as ExampleGlobalManager;
  }

  ExampleGlobalManager._create() : super.create();

  @override
  void init() {
    // Register managers in dependency order
    registerManagerAsync<ExampleConfigManager>(
      ExampleConfigBuilder(),
    );
    registerManagerAsync<LoggerManager>(
      const LoggerBuilder<ExampleConfigManager>(),
    );
    registerManagerAsync<ExampleMinioManager>(
      MinioBuilder<ExampleMinioManager, ExampleConfigManager>(
        ExampleMinioManager.new,
      ),
    );
  }
}

/// Main example function demonstrating MinIO operations
Future<void> main() async {
  // Initialize the global manager
  await ExampleGlobalManager.instance.allReadyBeforeView();

  // Get the MinIO storage service
  final minioManager = globalGetIt().get<ExampleMinioManager>();
  final storageService = minioManager.storageService;

  print('=== MinIO Storage Service Example ===\n');

  // Example 1: List files
  print('1. Listing files in "documents/" folder:');
  final listResult = await storageService.listFiles('documents/');

  if (listResult.result == StorageRequestResult.success) {
    final files = listResult.page?.items ?? [];
    print('   Found ${files.length} files:');
    for (final file in files.take(5)) {
      print('   - ${file.path} (${file.size} bytes)');
    }
  } else {
    print('   Failed to list files: ${listResult.result}');
  }

  print('');

  // Example 2: Upload a file
  print('2. Uploading a file:');
  // Note: In real usage, provide an actual file path
  // final fileToUpload = File('/path/to/local/document.pdf');
  // if (await fileToUpload.exists()) {
  //   final uploadResult = await storageService.putFile(
  // Note: In real usage, provide an actual file path
  // final fileToUpload = File('/path/to/local/document.pdf');
  // if (await fileToUpload.exists()) {
  //   final uploadResult = await storageService.putFile(
  //     'documents/uploaded-document.pdf',
  //     fileToUpload,
  //     metadata: {
  //       'content-type': 'application/pdf',
  //       'uploaded-by': 'example-user',
  //     },
  //     onProgress: (progress) {
  //       final percent = (progress.bytesTransferred / progress.totalBytes * 100).toStringAsFixed(1);
  //       print('   Upload progress: $percent%');
  //     },
  //   );
  //
  //   if (uploadResult.result == StorageRequestResult.success) {
  //     print('   ✓ Upload successful! ETag: ${uploadResult.etag}');
  //   } else {
  //     print('   ✗ Upload failed: ${uploadResult.result}');
  //   }
  // } else {
  //   print('   Skipping upload - file does not exist');
  // }
  print('   Skipping upload example (no file provided)');

  print('');

  // Example 3: Download a file
  print('3. Downloading a file:');
  final downloadResult = await storageService.getFile(
    'documents/example-document.pdf',
    onProgress: (progress) {
      if (progress.transferStatus == TransferStatus.inProgress) {
        final percent = (progress.bytesTransferred / progress.totalBytes * 100)
            .toStringAsFixed(1);
        print('   Download progress: $percent%');
      }
    },
  );

  if (downloadResult.result == StorageRequestResult.success) {
    print('   ✓ Downloaded to: ${downloadResult.file?.path}');
  } else {
    print('   ✗ Download failed: ${downloadResult.result}');
  }

  print('');

  // Example 4: Get a presigned download URL
  print('4. Getting presigned download URL:');
  final urlResult = await storageService.getDownloadUrl(
    'documents/example-document.pdf',
  );

  if (urlResult.result == StorageRequestResult.success) {
    print('   ✓ URL: ${urlResult.downloadUrl}');
    print('   (Valid for 5 minutes)');
  } else {
    print('   ✗ Failed to get URL: ${urlResult.result}');
  }

  print('');

  // Example 5: Delete a single file
  print('5. Deleting a single file:');
  final deleteResult = await storageService.removeObject(
    'documents/file-to-delete.pdf',
  );

  if (deleteResult == StorageRequestResult.success) {
    print('   ✓ File deleted successfully');
  } else {
    print('   ✗ Delete failed: $deleteResult');
  }

  print('');

  // Example 6: Delete multiple files
  print('6. Deleting multiple files:');
  final bulkDeleteResult = await storageService.removeObjects([
    'documents/temp-file1.pdf',
    'documents/temp-file2.pdf',
    'documents/temp-file3.pdf',
  ]);

  if (bulkDeleteResult == StorageRequestResult.success) {
    print('   ✓ All files deleted successfully');
  } else {
    print('   ✗ Bulk delete failed: $bulkDeleteResult');
  }

  print('\n=== Example Complete ===');
}
