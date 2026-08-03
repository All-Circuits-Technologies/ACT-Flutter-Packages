// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';
import 'dart:ui' as ui;

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:act_remote_storage_ui/act_remote_storage_ui.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/widgets.dart';

/// The asset key of the configuration file the tests serve.
const _configKey = "assets/config/default.yaml";

/// The configuration of an application which keeps no copy of what it downloads.
///
/// The cache writes on the device, through a database and a folder a test has no access to, so the
/// applications of the tests use none.
class FakeImageStorageConfig extends AbstractConfigManager with MixinStorageConfig {
  /// Class constructor
  FakeImageStorageConfig() : super(logger: const SilentLogger());

  /// Serves the configuration of the application and returns the manager which reads it.
  ///
  /// The caller has to stop serving the assets and to dispose the manager once the test is over.
  static Future<FakeImageStorageConfig> build() async {
    FakeAssets.serve({_configKey: "storage:\n  cache:\n    use: false"});

    final config = FakeImageStorageConfig();
    await config.initLifeCycle();

    return config;
  }
}

/// A remote storage which answers what the test asks it to.
class FakeImageStorageService extends AbsWithLifeCycle with MixinStorageService {
  /// The identifiers a file was asked for, in the order they were asked.
  final List<String> askedFiles = [];

  /// The file the storage answers with.
  File? file;

  /// The result the storage answers a request for a file with.
  StorageRequestResult fileResult = StorageRequestResult.success;

  @override
  Future<({StorageRequestResult result, String? downloadUrl})> getDownloadUrl(
    String fileId,
  ) async => (result: StorageRequestResult.success, downloadUrl: "https://a.storage/$fileId");

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
  }) async => (result: StorageRequestResult.success, page: StoragePage(items: const []));
}

/// The storage manager of an application which displays the images it downloads.
class FakeImageStorageManager extends AbsRemoteStorageManager<FakeImageStorageConfig>
    with MixinImageCacheService<FakeImageStorageConfig> {
  /// The storage the manager talks to.
  final FakeImageStorageService service;

  /// Class constructor
  FakeImageStorageManager(this.service);

  /// {@macro act_remote_storage_manager.AbsRemoteStorageManager.getStorageService}
  @override
  Future<MixinStorageService> getStorageService() async => service;
}

/// Writes a real green image of [size] pixels a side under [directory] and returns the file it was
/// written to.
///
/// The provider under test hands the file to Flutter, which decodes it, so the tests need an image
/// Flutter accepts rather than a file of any bytes.
Future<File> anImageFile(Directory directory, {String name = "anImage.png", int size = 1}) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(const Color(0xFF00FF00), BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();

  final file = File("${directory.path}/$name");
  await file.writeAsBytes(bytes!.buffer.asUint8List());

  return file;
}
