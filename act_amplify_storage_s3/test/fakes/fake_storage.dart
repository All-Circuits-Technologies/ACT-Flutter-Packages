// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The result of listing the objects of the bucket.
typedef ListResult = StorageListResult<StorageItem>;

/// The result of downloading one object of the bucket.
typedef DownloadResult = StorageDownloadFileResult<StorageItem>;

/// One call of a test which listed the objects of the bucket.
typedef ListCall = ({String path, StorageListOptions? options});

/// A download the test drives, in place of the one a device runs.
class _FakeDownloadOperation
    extends StorageDownloadFileOperation<StorageDownloadFileRequest, DownloadResult> {
  /// Class constructor
  _FakeDownloadOperation({required super.request, required super.result});

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> cancel() async {}
}

/// The storage of a bucket, answered by the test.
///
/// It records what it was asked for and answers with what the test gave it, or fails with the error
/// the test gave it instead of answering.
class FakeStoragePlugin extends StoragePluginInterface {
  /// The paths the objects of the bucket were listed under, in the order they were listed.
  final List<ListCall> listCalls = [];

  /// The paths which were downloaded, in the order they were downloaded.
  final List<String> downloadedPaths = [];

  /// The paths a link was asked for, in the order they were asked.
  final List<String> urlPaths = [];

  /// The objects the bucket answers with.
  List<StorageItem> items = const [];

  /// The token of the page which comes after the one the bucket answers with.
  String? nextToken;

  /// Whether the bucket holds a page after the one it answers with.
  bool hasNextPage = false;

  /// The link the bucket answers with.
  Uri url = Uri.parse("https://a.bucket/anObject");

  /// The steps a download goes through, which the bucket reports as it goes.
  List<StorageTransferProgress> progresses = const [];

  /// The error the bucket fails with instead of answering, when the test gave one.
  Exception? error;

  /// Adds the plugin to the storage of the cloud, in place of the one of Amplify.
  ///
  /// The categories of Amplify are shared by the whole test file, so the caller has to forget the
  /// plugins of the storage once the test is over.
  static Future<FakeStoragePlugin> install() async {
    final plugin = FakeStoragePlugin();
    await Amplify.Storage.addPlugin(plugin, authProviderRepo: AmplifyAuthProviderRepository());

    return plugin;
  }

  @override
  StorageListOperation list({required StoragePath path, StorageListOptions? options}) {
    listCalls.add((path: _pathOf(path), options: options));

    return StorageListOperation(
      request: StorageListRequest(path: path, options: options),
      result: _answer(ListResult(items, hasNextPage: hasNextPage, nextToken: nextToken)),
    );
  }

  @override
  StorageDownloadFileOperation downloadFile({
    required StoragePath path,
    required AWSFile localFile,
    void Function(StorageTransferProgress)? onProgress,
    StorageDownloadFileOptions? options,
  }) {
    downloadedPaths.add(_pathOf(path));
    if (onProgress != null) {
      progresses.forEach(onProgress);
    }

    return _FakeDownloadOperation(
      request: StorageDownloadFileRequest(path: path, localFile: localFile, options: options),
      result: _answer(
        DownloadResult(
          localFile: localFile,
          downloadedItem: StorageItem(path: _pathOf(path)),
        ),
      ),
    );
  }

  @override
  StorageGetUrlOperation getUrl({required StoragePath path, StorageGetUrlOptions? options}) {
    urlPaths.add(_pathOf(path));

    return StorageGetUrlOperation(
      request: StorageGetUrlRequest(path: path, options: options),
      result: _answer(StorageGetUrlResult(url: url)),
    );
  }

  /// The path [path] as the text the service was given.
  static String _pathOf(StoragePath path) =>
      // Amplify keeps the way of reading a path to itself, and a test has no other way of telling
      // which object of the bucket was asked for
      // ignore: invalid_use_of_internal_member
      path.resolvePath();

  /// The answer of the bucket, which is [result] unless the test asked it to fail.
  Future<T> _answer<T>(T result) {
    final error = this.error;

    return error != null ? Future.error(error) : Future.value(result);
  }
}

/// The directories of a device, answered by the test.
///
/// The service asks the device for the directory it downloads to when it is given none, and a test
/// runs on no device: without this, that question fails with a missing plugin rather than with the
/// answer of a device which holds no such directory.
class FakeDirectories extends PathProviderPlatform with MockPlatformInterfaceMixin {
  /// The path of the cache of the application, which is nothing when the device holds none.
  final String? cachePath;

  /// Class constructor
  FakeDirectories({this.cachePath});

  /// Answers for the directories of the device under test.
  static void install({String? cachePath}) =>
      PathProviderPlatform.instance = FakeDirectories(cachePath: cachePath);

  @override
  Future<String?> getApplicationCachePath() async => cachePath;
}
