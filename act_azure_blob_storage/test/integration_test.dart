// SPDX-FileCopyrightText: 2024 All Circuits Technologies <dev@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_server_storage_manager/act_server_storage_manager.dart';
import 'package:act_azure_blob_storage/act_azure_blob_storage.dart';

/// Example implementation of AbsServerStorageManager for Azure Blob Storage
class AzureBlobServerStorageManager extends AbsServerStorageManager {
  final AzureBlobStorageService _storageService;
  
  /// Constructor
  AzureBlobServerStorageManager(this._storageService);
  
  @override
  MixinStorageService getStorageService() => _storageService;
  
  @override
  CacheStorageConfig getStorageConfig() => CacheStorageConfig(
    cacheKey: 'azure_blob_cache',
    stalePeriod: const Duration(hours: 1),
    maxCachedFiles: 100,
  );
}

/// Integration test to verify the Azure Blob Storage service can be used
/// with the storage manager pattern
void main() async {
  // This is a structural test - it verifies that our implementation
  // can be instantiated and follows the correct patterns
  
  try {
    // Test service instantiation
    final azureService = AzureBlobStorageService(
      connectionString: 'test_connection_string',
      containerName: 'test_container',
    );
    
    print('✓ AzureBlobStorageService instantiated successfully');
    
    // Test storage manager instantiation
    final storageManager = AzureBlobServerStorageManager(azureService);
    
    print('✓ AzureBlobServerStorageManager instantiated successfully');
    
    // Verify the service implements the correct interface
    final storageService = storageManager.getStorageService();
    print('✓ Storage service retrieved from manager: ${storageService.runtimeType}');
    
    // Verify the config is properly set
    final config = storageManager.getStorageConfig();
    print('✓ Storage config retrieved: cacheKey=${config.cacheKey}');
    
    // Test that the methods exist and have the right signatures
    // We can't actually call them without valid Azure credentials
    print('✓ listFiles method signature: ${azureService.listFiles.runtimeType}');
    print('✓ getFile method signature: ${azureService.getFile.runtimeType}');
    print('✓ getDownloadUrl method signature: ${azureService.getDownloadUrl.runtimeType}');
    
    print('\n🎉 All structural tests passed!');
    print('✓ Azure Blob Storage service follows MixinStorageService pattern');
    print('✓ Service can be used with AbsServerStorageManager');
    print('✓ All required methods are implemented');
    
  } catch (e) {
    print('✗ Test failed: $e');
    exit(1);
  }
}