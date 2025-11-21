// SPDX-FileCopyrightText: 2025 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_minio_manager/src/mixins/mixin_minio_config.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';

/// Configuration model for MinIO connection
class MinioConfigModel extends Equatable {
  /// Default port for MinIO connections
  static const _defaultPort = 9000;

  /// Default region
  static const _defaultRegion = 'us-east-1';

  /// Default SSL setting
  static const _defaultUseSSL = true;

  /// The MinIO server endpoint
  final String endpoint;

  /// The MinIO server port
  final int port;

  /// The MinIO access key
  final String accessKey;

  /// The MinIO secret key
  final String secretKey;

  /// The default bucket name
  final String bucket;

  /// Whether to use SSL for connections
  final bool useSSL;

  /// The MinIO region
  final String region;

  /// Class constructor
  const MinioConfigModel._({
    required this.endpoint,
    required this.port,
    required this.accessKey,
    required this.secretKey,
    required this.bucket,
    required this.useSSL,
    required this.region,
  });

  /// Get the MinIO configuration from the ConfigManager
  ///
  /// Returns null if any required configuration is missing
  static MinioConfigModel? get<ConfigManager extends MixinMinioConfig>() {
    final configManager = globalGetIt().get<ConfigManager>();

    final endpoint = configManager.minioEndpoint.load();
    if (endpoint == null) {
      Logger()
          .f('MinioConfigModel: The endpoint is not set in the configuration');
      return null;
    }

    final accessKey = configManager.minioAccessKey.load();
    if (accessKey == null) {
      Logger()
          .f('MinioConfigModel: The accessKey is not set in the configuration');
      return null;
    }

    final secretKey = configManager.minioSecretKey.load();
    if (secretKey == null) {
      Logger()
          .f('MinioConfigModel: The secretKey is not set in the configuration');
      return null;
    }

    final bucket = configManager.minioBucket.load();
    if (bucket == null) {
      Logger()
          .f('MinioConfigModel: The bucket is not set in the configuration');
      return null;
    }

    final port = configManager.minioPort.load() ?? _defaultPort;
    final useSSL = configManager.minioUseSSL.load() ?? _defaultUseSSL;
    final region = configManager.minioRegion.load() ?? _defaultRegion;

    return MinioConfigModel._(
      endpoint: endpoint,
      port: port,
      accessKey: accessKey,
      secretKey: secretKey,
      bucket: bucket,
      useSSL: useSSL,
      region: region,
    );
  }

  /// Properties of the model
  @override
  List<Object?> get props => [
        endpoint,
        port,
        accessKey,
        secretKey,
        bucket,
        useSSL,
        region,
      ];
}
