// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';
import 'dart:ui';

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_remote_local_vers_file_manager/act_remote_local_vers_file_manager.dart';
import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';

/// The folders an application under test reads its files from.
enum FakeDirType with MixinRemoteLocalVersFileType {
  /// The folder of the terms the user agrees to.
  terms("terms"),

  /// The folder of the notes of a release.
  releaseNotes("release_notes");

  /// {@macro act_remote_local_vers_file_manager.MixinRemoteLocalVersFileType.dirId}
  @override
  final String dirId;

  /// Enum constructor
  const FakeDirType(this.dirId);
}

/// The configuration of the storage of the application under test.
class FakeStorageConfig extends AbstractConfigManager with MixinStorageConfig {
  /// Class constructor
  FakeStorageConfig() : super(logger: const SilentLogger());
}

/// The configuration of the application under test.
class FakeDirConfig extends AbstractConfigManager
    with MixinRemoteLocalVersFileConfig<FakeDirType> {
  /// Class constructor
  FakeDirConfig() : super(logger: const SilentLogger());

  /// {@macro act_remote_local_vers_file_manager.MixinRemoteLocalVersFileConfig.getMultiDirTypes}
  @override
  List<FakeDirType> getMultiDirTypes() => FakeDirType.values;
}

/// A remote storage which serves the files the test wrote, and records what it was asked.
///
/// The utilities of this package read the files they get, so the storage answers with real files,
/// written in a folder of the machine which is forgotten once the test is over.
class FakeStorage extends AbsRemoteStorageManager<FakeStorageConfig> {
  /// The folder the files of the test are written in.
  final Directory root;

  /// The content of the files the storage holds, one per path.
  final Map<String, String> files;

  /// The paths the storage was asked for, and whether the cache was allowed each time.
  final List<({String path, bool useCache})> requests = [];

  /// The answer of a storage which does not hold the file it was asked for.
  StorageRequestResult missingFileResult = StorageRequestResult.ioError;

  /// Class constructor
  FakeStorage({required this.root, Map<String, String> files = const {}})
    : files = Map<String, String>.from(files);

  /// The paths the storage was asked for, in the order it was asked.
  List<String> get askedPaths => requests.map((request) => request.path).toList();

  /// {@macro act_remote_storage_manager.AbsRemoteStorageManager.getPathSeparator}
  @override
  String getPathSeparator() => "/";

  /// {@macro act_remote_storage_manager.AbsRemoteStorageManager.getFile}
  @override
  Future<({StorageRequestResult result, File? file})> getFile(
    String fileId, {
    bool useCache = true,
  }) async {
    requests.add((path: fileId, useCache: useCache));

    final content = files[fileId];
    if (content == null) {
      return (result: missingFileResult, file: null);
    }

    final file = File("${root.path}/${fileId.replaceAll("/", "_")}");
    await file.writeAsString(content);

    return (result: StorageRequestResult.success, file: file);
  }

  /// {@macro act_remote_storage_manager.AbsRemoteStorageManager.getStorageService}
  @override
  Future<MixinStorageService> getStorageService() =>
      throw UnimplementedError("The storage of a test answers the files itself");
}

/// The manager of an application which reads files from its remote storage.
class FakeDirManager extends AbsRemoteLocalVersFileManager<FakeDirType> {
  /// The storage the application reads its files from.
  final FakeStorage storage;

  /// The locale the application is shown in.
  final Locale currentLocale;

  /// The locale the application falls back to.
  final Locale defaultLocale;

  /// The options the application overrides the ones of its configuration with.
  final Map<FakeDirType, RemoteLocalDirOptions> overrides;

  /// Class constructor
  FakeDirManager({
    required this.storage,
    required super.configManagerGetter,
    this.currentLocale = const Locale("fr", "FR"),
    this.defaultLocale = const Locale("en", "GB"),
    this.overrides = const {},
  });

  /// {@macro act_remote_local_vers_file_manager.AbsRemoteLocalVersFileManager.getStorageManager}
  @override
  AbsRemoteStorageManager getStorageManager(FakeDirType dirType) => storage;

  /// {@macro act_remote_local_vers_file_manager.AbsRemoteLocalVersFileManager.getCurrentLocale}
  @override
  Future<Locale> getCurrentLocale() async => currentLocale;

  /// {@macro act_remote_local_vers_file_manager.AbsRemoteLocalVersFileManager.getDefaultLocale}
  @override
  Future<Locale> getDefaultLocale() async => defaultLocale;

  /// {@macro act_remote_local_vers_file_manager.AbsRemoteLocalVersFileManager.getOptionsOverrides}
  @override
  Future<Map<FakeDirType, RemoteLocalDirOptions>> getOptionsOverrides() async => overrides;
}

/// The builder of the manager of an application which reads files from its remote storage.
class FakeDirBuilder
    extends
        AbsRemoteLocalVersFileBuilder<FakeDirType, MixinRemoteLocalVersFileConfig<FakeDirType>,
            FakeDirManager> {
  /// Class constructor
  FakeDirBuilder(super.factory);
}
