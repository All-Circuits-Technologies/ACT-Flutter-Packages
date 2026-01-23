// SPDX-FileCopyrightText: 2025 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';

/// Mixin to add MinIO configuration variables to the ConfigManager
mixin MixinMinioConfig on AbstractConfigManager {
  /// The MinIO server endpoint (e.g., "play.min.io")
  final minioEndpoint = const ConfigVar<String>(
    "minio.endpoint",
  );

  /// The MinIO server port (default: 9000)
  final minioPort = const ConfigVar<int>(
    "minio.port",
  );

  /// The MinIO access key for authentication
  final minioAccessKey = const ConfigVar<String>(
    "minio.accessKey",
  );

  /// The MinIO secret key for authentication
  final minioSecretKey = const ConfigVar<String>(
    "minio.secretKey",
  );

  /// The default bucket name to use
  final minioBucket = const ConfigVar<String>(
    "minio.bucket",
  );

  /// Whether to use SSL for connections (default: true)
  final minioUseSSL = const ConfigVar<bool>(
    "minio.useSSL",
  );
}
