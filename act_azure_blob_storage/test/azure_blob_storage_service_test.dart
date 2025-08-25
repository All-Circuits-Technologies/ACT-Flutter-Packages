// SPDX-FileCopyrightText: 2024 All Circuits Technologies <dev@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';
import 'package:test/test.dart';
import 'package:act_server_storage_manager/act_server_storage_manager.dart';
import 'package:act_azure_blob_storage/act_azure_blob_storage.dart';

void main() {
  group('AzureBlobStorageService', () {
    test('service can be instantiated with required parameters', () {
      expect(() => AzureBlobStorageService(
        connectionString: 'DefaultEndpointsProtocol=https;AccountName=test;AccountKey=dGVzdA==;EndpointSuffix=core.windows.net',
        containerName: 'test-container',
      ), returnsNormally);
    });

    test('service implements MixinStorageService interface', () {
      final service = AzureBlobStorageService(
        connectionString: 'DefaultEndpointsProtocol=https;AccountName=test;AccountKey=dGVzdA==;EndpointSuffix=core.windows.net',
        containerName: 'test-container',
      );
      
      expect(service, isA<MixinStorageService>());
    });

    test('service extends AbsWithLifeCycle', () {
      final service = AzureBlobStorageService(
        connectionString: 'DefaultEndpointsProtocol=https;AccountName=test;AccountKey=dGVzdA==;EndpointSuffix=core.windows.net',
        containerName: 'test-container',
      );
      
      expect(service.initLifeCycle, isA<Function>());
      expect(service.disposeLifeCycle, isA<Function>());
    });

    test('parseException handles different exception types correctly', () {
      expect(
        AzureBlobStorageService._parseException(FileSystemException('test')),
        StorageRequestResult.ioError
      );
      
      expect(
        AzureBlobStorageService._parseException(SocketException('test')),
        StorageRequestResult.ioError
      );
      
      expect(
        AzureBlobStorageService._parseException(Exception('generic')),
        StorageRequestResult.genericError
      );
    });

    test('parseHttpStatusCode maps status codes correctly', () {
      expect(
        AzureBlobStorageService._parseHttpStatusCode(401),
        StorageRequestResult.accessDenied
      );
      
      expect(
        AzureBlobStorageService._parseHttpStatusCode(403),
        StorageRequestResult.accessDenied
      );
      
      expect(
        AzureBlobStorageService._parseHttpStatusCode(404),
        StorageRequestResult.ioError
      );
      
      expect(
        AzureBlobStorageService._parseHttpStatusCode(500),
        StorageRequestResult.genericError
      );
    });
  });
}