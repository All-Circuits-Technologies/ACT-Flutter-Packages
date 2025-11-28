// SPDX-FileCopyrightText: 2025 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_minio_manager/src/models/minio_config_model.dart';

/// Mixin to add MinIO configuration variables to the ConfigManager
mixin MixinMinioConfig on AbstractConfigManager {
  /// MinIO configuration parsed from a Map structure
  ///
  /// Expected configuration structure:
  /// ```yaml
  /// minio:
  ///   endpoint: "play.min.io"      # required
  ///   port: 9000                   # optional, defaults to 9000
  ///   accessKey: "your-access-key" # required
  ///   secretKey: "your-secret-key" # required
  ///   bucket: "your-bucket"        # required
  ///   useSSL: true                 # optional, defaults to true
  /// ```
  final minioConfig = const NotNullParserConfigVar<MinioConfigModel,
      Map<String, dynamic>>.crashIfNull(
    "minio",
    parser: _parseMinioConfig,
  );

  /// Parser function for MinIO configuration
  static MinioConfigModel? _parseMinioConfig(Map<String, dynamic> map) =>
      MinioConfigModel.fromMap(map);
}
