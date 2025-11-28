// SPDX-FileCopyrightText: 2025 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_minio_manager/src/minio_storage_service.dart';
import 'package:act_minio_manager/src/mixins/mixin_minio_config.dart';
import 'package:act_minio_manager/src/models/minio_config_model.dart';
import 'package:flutter/foundation.dart';

/// Builder class to create a [AbsMinioManager] instance.
///
/// The [ConfigManager] type must extend [MixinMinioConfig] to provide
/// the necessary MinIO configuration variables.
abstract class AbsMinioBuilder<T extends AbsMinioManager,
    ConfigManager extends MixinMinioConfig> extends AbsManagerBuilder<T> {
  /// Class constructor
  AbsMinioBuilder(super.factory);

  @override
  @mustCallSuper
  Iterable<Type> dependsOn() => [
        LoggerManager,
        ConfigManager,
      ];
}

/// Abstract class to manage MinIO storage service in an application.
///
/// This manager handles the lifecycle of the MinIO storage service and
/// provides access to it for storage operations.
abstract class AbsMinioManager extends AbsWithLifeCycle {
  /// Class logger category
  static const String _minioManagerLogCategory = 'minio';

  /// Logs helper
  @protected
  late final LogsHelper logsHelper;

  /// MinIO storage service instance
  late final MinioStorageService storageService;

  /// Class constructor
  AbsMinioManager();

  /// Initialize the MinIO manager and storage service
  @override
  @mustCallSuper
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: _minioManagerLogCategory,
    );

    // Get the MinIO configuration from the config manager
    final configManager = getConfigManager();
    final config = MinioConfigModel.getFromConfigManager(
      configManager: configManager,
      logsHelper: logsHelper,
    );
    if (config == null) {
      throw Exception('Missing mandatory configuration for the MinioManager');
    }

    // Create the MinIO storage service
    storageService = MinioStorageService(
      config: config,
      parentLogsHelper: logsHelper,
    );

    // Initialize the storage service
    await storageService.initLifeCycle();

    logsHelper.i('MinIO manager started successfully');
  }

  /// Get the configuration manager instance
  @protected
  MixinMinioConfig getConfigManager();

  /// Dispose the MinIO storage service
  @override
  @mustCallSuper
  Future<void> disposeLifeCycle() async {
    logsHelper.d('Disposing MinIO manager...');
    await storageService.disposeLifeCycle();
    await super.disposeLifeCycle();
  }
}
