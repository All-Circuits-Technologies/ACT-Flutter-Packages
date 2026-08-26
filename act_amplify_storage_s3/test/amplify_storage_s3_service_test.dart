// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_amplify_storage_s3/act_amplify_storage_s3.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_storage.dart';

/// An error the bucket fails with which is none of the ones the service tells apart.
class _AFailure implements Exception {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStoragePlugin bucket;
  late FakeExternalLogger logs;
  late Directory directory;

  setUp(() async {
    bucket = await FakeStoragePlugin.install();
    logs = FakeExternalLogger();
    directory = await Directory.systemTemp.createTemp("act_amplify_storage_s3_test");
    FakeDirectories.install(cachePath: directory.path);
  });

  tearDown(() async {
    await Amplify.Storage.reset();
    await directory.delete(recursive: true);
  });

  /// Builds the storage service of an application and initializes it.
  Future<AmplifyStorageS3Service> aService() async {
    final service = AmplifyStorageS3Service();
    await service.initLifeCycle(parentLogsHelper: logs.buildHelper(category: "amplify"));
    addTearDown(service.disposeLifeCycle);

    return service;
  }

  group("AmplifyStorageS3Service.getLinkedPluginsList", () {
    test("brings the S3 plugin of Amplify along", () async {
      final service = await aService();

      expect(await service.getLinkedPluginsList(), [isA<AmplifyStorageS3>()]);
    });
  });

  group("AmplifyStorageS3Service.listFiles", () {
    test("lists the objects under the path it is given", () async {
      final service = await aService();

      await service.listFiles("aFolder/");

      expect(bucket.listCalls.single.path, "aFolder/");
    });

    test("hands back the objects the bucket holds", () async {
      final service = await aService();
      bucket.items = [
        StorageItem(
          path: "aFolder/anObject",
          size: 12,
          lastModified: DateTime.utc(2026),
          eTag: "anETag",
        ),
      ];

      final page = (await service.listFiles("aFolder/")).page;

      expect(page?.items, [
        StorageFile(
          path: "aFolder/anObject",
          size: 12,
          lastModified: DateTime.utc(2026),
          eTag: "anETag",
        ),
      ]);
    });

    test("hands back the token of the page which comes next", () async {
      final service = await aService();
      bucket.nextToken = "aToken";
      bucket.hasNextPage = true;

      final page = (await service.listFiles("aFolder/")).page;

      expect(page?.nextPageToken, "aToken");
      expect(page?.hasNextPage, isTrue);
    });

    test("asks the bucket for as many objects as a page holds", () async {
      final service = await aService();

      await service.listFiles("aFolder/");

      expect(bucket.listCalls.single.options?.pageSize, MixinStorageService.defaultPageSize);
    });

    test("asks the bucket for the page size it is given", () async {
      final service = await aService();

      await service.listFiles("aFolder/", pageSize: 3);

      expect(bucket.listCalls.single.options?.pageSize, 3);
    });

    test("asks the bucket for the page which follows the token it is given", () async {
      final service = await aService();

      await service.listFiles("aFolder/", nextToken: "aToken");

      expect(bucket.listCalls.single.options?.nextToken, "aToken");
    });

    test("leaves out what is under the folders unless the search goes through them", () async {
      final service = await aService();

      await service.listFiles("aFolder/");

      final options = bucket.listCalls.single.options?.pluginOptions;
      expect((options as S3ListPluginOptions?)?.excludeSubPaths, isTrue);
    });

    test("goes through the folders of the path when the search is recursive", () async {
      final service = await aService();

      await service.listFiles("aFolder/", recursiveSearch: true);

      final options = bucket.listCalls.single.options?.pluginOptions;
      expect((options as S3ListPluginOptions?)?.excludeSubPaths, isFalse);
    });

    test("says the request went through when the bucket answered", () async {
      final service = await aService();

      expect((await service.listFiles("aFolder/")).result, StorageRequestResult.success);
    });

    test("hands back no page when the bucket refused the request", () async {
      final service = await aService();
      bucket.error = _AFailure();

      expect((await service.listFiles("aFolder/")).page, isNull);
    });

    test("logs the listing which failed under the logs of the manager", () async {
      final service = await aService();
      bucket.error = _AFailure();

      await service.listFiles("aFolder/");

      expect(logs.recordsAtLevel(LogsLevel.error).single.categories, ["amplify", "storages3"]);
    });
  });

  group("AmplifyStorageS3Service.getFile", () {
    test("downloads the object of the path it is given", () async {
      final service = await aService();

      await service.getFile("aFolder/anObject", directory: directory);

      expect(bucket.downloadedPaths.single, "aFolder/anObject");
    });

    test("keeps the object under the directory it is given", () async {
      final service = await aService();

      final file = (await service.getFile("aFolder/anObject", directory: directory)).file;

      expect(file?.path, "${directory.path}/aFolder/anObject");
    });

    test("creates the folders of the path the object is kept under", () async {
      final service = await aService();

      await service.getFile("aFolder/anObject", directory: directory);

      expect(Directory("${directory.path}/aFolder").existsSync(), isTrue);
    });

    test("says the request went through when the bucket answered", () async {
      final service = await aService();

      final result = (await service.getFile("aFolder/anObject", directory: directory)).result;

      expect(result, StorageRequestResult.success);
    });

    test("reports how far the download went", () async {
      final service = await aService();
      bucket.progresses = const [
        StorageTransferProgress(
          transferredBytes: 6,
          totalBytes: 12,
          state: StorageTransferState.inProgress,
        ),
      ];
      final reported = <TransferProgress>[];

      await service.getFile("aFolder/anObject", directory: directory, onProgress: reported.add);

      expect(reported, [
        const TransferProgress(
          totalBytes: 12,
          bytesTransferred: 6,
          transferStatus: TransferStatus.inProgress,
        ),
      ]);
    });

    test("reports every state a download goes through", () async {
      final service = await aService();
      bucket.progresses = StorageTransferState.values
          .map((state) => StorageTransferProgress(transferredBytes: 0, totalBytes: 0, state: state))
          .toList();
      final reported = <TransferProgress>[];

      await service.getFile("aFolder/anObject", directory: directory, onProgress: reported.add);

      expect(reported.map((progress) => progress.transferStatus), [
        TransferStatus.inProgress,
        TransferStatus.paused,
        TransferStatus.canceled,
        TransferStatus.success,
        TransferStatus.failure,
      ]);
    });

    test("hands back no file when the bucket refused the request", () async {
      final service = await aService();
      bucket.error = _AFailure();

      final file = (await service.getFile("aFolder/anObject", directory: directory)).file;

      expect(file, isNull);
    });

    test(
      "keeps the object under the cache of the application when it is given no directory",
      () async {
        final service = await aService();

        final file = (await service.getFile("aFolder/anObject")).file;

        expect(file?.path, "${directory.path}/aFolder/anObject");
      },
    );

    test("blames the device when it holds no directory to download to", () async {
      final service = await aService();
      FakeDirectories.install();

      final result = (await service.getFile("aFolder/anObject")).result;

      expect(result, StorageRequestResult.ioError);
    });
  });

  group("AmplifyStorageS3Service.getDownloadUrl", () {
    test("asks the bucket for a link to the object of the path it is given", () async {
      final service = await aService();

      await service.getDownloadUrl("aFolder/anObject");

      expect(bucket.urlPaths.single, "aFolder/anObject");
    });

    test("hands back the link the bucket answered with", () async {
      final service = await aService();
      bucket.url = Uri.parse("https://a.bucket/aFolder/anObject?signature=aSignature");

      final url = (await service.getDownloadUrl("aFolder/anObject")).downloadUrl;

      expect(url, "https://a.bucket/aFolder/anObject?signature=aSignature");
    });

    test("says the request went through when the bucket answered", () async {
      final service = await aService();

      expect(
        (await service.getDownloadUrl("aFolder/anObject")).result,
        StorageRequestResult.success,
      );
    });

    test("hands back no link when the bucket refused the request", () async {
      final service = await aService();
      bucket.error = _AFailure();

      expect((await service.getDownloadUrl("aFolder/anObject")).downloadUrl, isNull);
    });
  });

  group("AmplifyStorageS3Service failures", () {
    test("blames the credentials when the bucket refused the access", () async {
      final service = await aService();
      bucket.error = const StorageAccessDeniedException("the access was refused");

      expect((await service.getDownloadUrl("anObject")).result, StorageRequestResult.accessDenied);
    });

    test("blames the credentials when the session of the user is over", () async {
      final service = await aService();
      bucket.error = const SessionExpiredException("the session is over");

      expect((await service.getDownloadUrl("anObject")).result, StorageRequestResult.accessDenied);
    });

    test("blames nothing in particular for a failure it does not tell apart", () async {
      final service = await aService();
      bucket.error = _AFailure();

      expect((await service.getDownloadUrl("anObject")).result, StorageRequestResult.genericError);
    });
  });
}
