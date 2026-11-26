// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';

/// The folder the configuration of the application under test is read from.
const configPath = "assets/config/";

/// The configuration of the application under test.
class FakeStorageConfig extends AbstractConfigManager with MixinStorageConfig {
  /// Class constructor
  FakeStorageConfig({super.logger = const SilentLogger()});

  /// Builds the configuration of an application from the [storage] section given.
  static Future<FakeStorageConfig> build([String storage = "logs:\n  level: warning"]) async {
    FakeAssets.serve({"${configPath}default.yaml": storage});

    final config = FakeStorageConfig();
    await config.initLifeCycle();

    return config;
  }
}

/// A remote storage which answers what the test asks it to.
class FakeStorageService extends AbsWithLifeCycle with MixinStorageService {
  /// The download url the storage answers with.
  String? downloadUrl = "https://storage.example/aFile";

  /// The result the storage answers a request for a download url with.
  StorageRequestResult downloadUrlResult = StorageRequestResult.success;

  /// The file the storage answers with.
  File? file;

  /// The result the storage answers a request for a file with.
  StorageRequestResult fileResult = StorageRequestResult.success;

  /// The pages the storage answers with, one per call, in order.
  final List<({StorageRequestResult result, StoragePage? page})> pages = [];

  /// The paths the storage has been asked to list, and the token each call carried.
  final List<({String searchPath, String? nextToken, bool recursiveSearch})> listedPaths = [];

  /// The identifiers the storage has been asked for a file for.
  final List<String> askedFiles = [];

  /// {@macro act_remote_storage_manager.MixinStorageService.headers}
  @override
  Map<String, String>? headers;

  @override
  Future<({StorageRequestResult result, String? downloadUrl})> getDownloadUrl(
    String fileId,
  ) async => (result: downloadUrlResult, downloadUrl: downloadUrl);

  @override
  Future<({StorageRequestResult result, File? file})> getFile(
    String fileId, {
    Directory? directory,
    OnProgressCallback? onProgress,
  }) async {
    askedFiles.add(fileId);

    return (result: fileResult, file: file);
  }

  @override
  Future<({StorageRequestResult result, StoragePage? page})> listFiles(
    String searchPath, {
    int? pageSize,
    String? nextToken,
    bool recursiveSearch = false,
  }) async {
    listedPaths.add((
      searchPath: searchPath,
      nextToken: nextToken,
      recursiveSearch: recursiveSearch,
    ));

    if (pages.isEmpty) {
      return (result: StorageRequestResult.success, page: StoragePage(items: const []));
    }

    return pages.removeAt(0);
  }
}

/// The storage manager of the application under test.
class FakeStorageManager extends AbsRemoteStorageManager<FakeStorageConfig> {
  /// The storage the manager talks to.
  final FakeStorageService service;

  /// Class constructor
  FakeStorageManager(this.service);

  /// {@macro act_remote_storage_manager.AbsRemoteStorageManager.getStorageService}
  @override
  Future<MixinStorageService> getStorageService() async => service;
}

/// The builder of the storage manager of the application under test.
class FakeStorageBuilder extends AbsRemoteStorageBuilder<FakeStorageManager> {
  /// Class constructor
  FakeStorageBuilder(super.factory);
}
