// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(FakeGlobalManager.install);

  /// Builds a service which serves the files of [root].
  Future<HttpStorageService> aService(String root) async {
    final service = HttpStorageService(httpRoot: Uri.parse(root));
    await service.initLifeCycle();

    return service;
  }

  group("HttpStorageService.getDownloadUrl", () {
    test("builds the url of a file under the root of the server", () async {
      final service = await aService("https://files.example/root");

      expect(
        await service.getDownloadUrl("a/file.txt"),
        (result: StorageRequestResult.success, downloadUrl: "https://files.example/root/a/file.txt"),
      );
    });

    test("builds the url of a file whose identifier starts with a separator", () async {
      final service = await aService("https://files.example/root");

      expect(
        (await service.getDownloadUrl("/a/file.txt")).downloadUrl,
        "https://files.example/root/a/file.txt",
      );
    });

    test("accepts a root which already ends with a separator", () async {
      final service = await aService("https://files.example/root/");

      expect(
        (await service.getDownloadUrl("a/file.txt")).downloadUrl,
        "https://files.example/root/a/file.txt",
      );
    });

    test("refuses a file which would climb out of the root of the server", () async {
      final service = await aService("https://files.example/root");

      expect(
        await service.getDownloadUrl("../elsewhere/file.txt"),
        (result: StorageRequestResult.genericError, downloadUrl: null),
      );
    });

    test("refuses a file which is the root itself", () async {
      final service = await aService("https://files.example/root");

      expect((await service.getDownloadUrl("")).downloadUrl, isNull);
    });
  });

  group("HttpStorageService.listFiles", () {
    test("refuses to list the files, which the protocol cannot do", () async {
      final service = await aService("https://files.example/root");

      expect(() => service.listFiles("a/path"), throwsUnsupportedError);
    });
  });

  group("HttpStorageService.headers", () {
    test("sends no header unless the application gives some", () async {
      expect((await aService("https://files.example/root")).headers, isNull);
    });

    test("sends the headers the application gives", () async {
      final service = HttpStorageService(
        httpRoot: Uri.parse("https://files.example/root"),
        headers: const {"Authorization": "Bearer aToken"},
      );
      await service.initLifeCycle();

      expect(service.headers, const {"Authorization": "Bearer aToken"});
    });
  });
}
