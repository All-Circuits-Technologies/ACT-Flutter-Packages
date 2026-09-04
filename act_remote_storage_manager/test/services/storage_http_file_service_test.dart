// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStorageService service;

  setUp(() {
    FakeGlobalManager.install();
    service = FakeStorageService();
  });

  group("StorageHttpFileService.get", () {
    test("gives up when the storage cannot say where the file is", () async {
      service
        ..downloadUrlResult = StorageRequestResult.accessDenied
        ..downloadUrl = null;
      final fileService = StorageHttpFileService(storageService: service);

      expect(
        () => fileService.get("aFile"),
        throwsA(isA<ActStorageDownloadUrlException>()),
      );
    });

    test("says which file it could not find the address of", () async {
      service.downloadUrlResult = StorageRequestResult.genericError;
      final fileService = StorageHttpFileService(storageService: service);

      expect(
        () => fileService.get("aFile"),
        throwsA(
          isA<ActStorageDownloadUrlException>().having(
            (error) => error.toString(),
            "message",
            contains("aFile"),
          ),
        ),
      );
    });
  });
}
