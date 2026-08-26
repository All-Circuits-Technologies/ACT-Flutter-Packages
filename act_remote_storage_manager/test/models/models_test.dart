// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("StorageFile", () {
    test("knows nothing but its path unless the storage says more", () {
      const file = StorageFile(path: "a/file");

      expect(file.size, isNull);
      expect(file.lastModified, isNull);
      expect(file.eTag, isNull);
    });

    test("equals another file which carries the same path and the same details", () {
      expect(
        const StorageFile(path: "a/file", size: 42),
        const StorageFile(path: "a/file", size: 42),
      );
    });

    test("differs from a file of another size", () {
      expect(
        const StorageFile(path: "a/file", size: 42),
        isNot(const StorageFile(path: "a/file", size: 43)),
      );
    });
  });

  group("StoragePage", () {
    test("has no next page unless the storage says so", () {
      final page = StoragePage(items: const []);

      expect(page.hasNextPage, isFalse);
      expect(page.nextPageToken, isNull);
    });

    test("keeps the files it is given", () {
      final page = StoragePage(items: const [StorageFile(path: "a/file")]);

      expect(page.items, const [StorageFile(path: "a/file")]);
    });

    test("copies the files it is given, so the caller cannot add to them", () {
      final items = [const StorageFile(path: "a/file")];
      final page = StoragePage(items: items);

      items.add(const StorageFile(path: "another/file"));

      expect(page.items.length, 1);
    });
  });

  group("StoragePage.prependPreviousPage", () {
    test("puts the files of the previous page before its own", () {
      final previous = StoragePage(items: const [StorageFile(path: "first")]);
      final page = StoragePage(items: const [StorageFile(path: "second")]);

      expect(page.prependPreviousPage(previous).items.map((file) => file.path), [
        "first",
        "second",
      ]);
    });

    test("keeps its own token and its own answer about a next page", () {
      final previous = StoragePage(
        items: const [StorageFile(path: "first")],
        nextPageToken: "the token of the previous page",
        hasNextPage: true,
      );
      final page = StoragePage(items: const [], nextPageToken: "its own token");

      final merged = page.prependPreviousPage(previous);

      expect(merged.nextPageToken, "its own token");
      expect(merged.hasNextPage, isFalse);
    });

    test("returns itself when there is no previous page", () {
      final page = StoragePage(items: const []);

      expect(page.prependPreviousPage(null), same(page));
    });
  });

  group("TransferProgress", () {
    test("returns the share of the bytes which have been transferred", () {
      const progress = TransferProgress(
        totalBytes: 200,
        bytesTransferred: 50,
        transferStatus: TransferStatus.inProgress,
      );

      expect(progress.progress, 0.25);
    });

    test("returns no progress when the size of the transfer is unknown", () {
      const progress = TransferProgress(
        totalBytes: -1,
        bytesTransferred: 50,
        transferStatus: TransferStatus.inProgress,
      );

      expect(progress.progress, 0);
    });

    test("returns no progress for a transfer of nothing", () {
      const progress = TransferProgress(
        totalBytes: 0,
        bytesTransferred: 0,
        transferStatus: TransferStatus.success,
      );

      expect(progress.progress, 0);
    });
  });

  group("TransferStatus", () {
    test("says a transfer which succeeded or failed is over", () {
      expect(TransferStatus.success.isCompleted, isTrue);
      expect(TransferStatus.failure.isCompleted, isTrue);
    });

    test("says a transfer which is running, paused or cancelled is not over", () {
      expect(TransferStatus.inProgress.isCompleted, isFalse);
      expect(TransferStatus.paused.isCompleted, isFalse);
      expect(TransferStatus.canceled.isCompleted, isFalse);
    });
  });

  group("CacheStorageConfig", () {
    test("equals another configuration which carries the same values", () {
      expect(
        const CacheStorageConfig(
          key: "aKey",
          stalePeriod: Duration(days: 14),
          maxNbOfCachedObjects: 100,
        ),
        const CacheStorageConfig(
          key: "aKey",
          stalePeriod: Duration(days: 14),
          maxNbOfCachedObjects: 100,
        ),
      );
    });

    test("differs from a configuration which keeps the files for another while", () {
      expect(
        const CacheStorageConfig(
          key: "aKey",
          stalePeriod: Duration(days: 14),
          maxNbOfCachedObjects: 100,
        ),
        isNot(
          const CacheStorageConfig(
            key: "aKey",
            stalePeriod: Duration(days: 7),
            maxNbOfCachedObjects: 100,
          ),
        ),
      );
    });
  });
}
