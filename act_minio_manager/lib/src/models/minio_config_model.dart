// SPDX-FileCopyrightText: 2025 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_minio_manager/src/mixins/mixin_minio_config.dart';
import 'package:equatable/equatable.dart';

/// Configuration model for MinIO connection
class MinioConfigModel extends Equatable {
  /// Default port for MinIO connections
  static const _defaultPort = 9000;

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

  /// Class constructor
  const MinioConfigModel._({
    required this.endpoint,
    required this.port,
    required this.accessKey,
    required this.secretKey,
    required this.bucket,
    required this.useSSL,
  });

  /// Parse MinIO configuration from a Map
  ///
  /// Expected map structure:
  /// ```dart
  /// {
  ///   'endpoint': 'play.min.io',      // required
  ///   'port': 9000,                   // optional, defaults to 9000
  ///   'accessKey': 'your-access-key', // required
  ///   'secretKey': 'your-secret-key', // required
  ///   'bucket': 'your-bucket',        // required
  ///   'useSSL': true,                 // optional, defaults to true
  /// }
  /// ```
  ///
  /// Returns null if any required field is missing or has an invalid type
  static MinioConfigModel? fromMap(Map<String, dynamic> map) {
    try {
      final endpoint = map['endpoint'] as String?;
      if (endpoint == null) {
        return null;
      }

      final accessKey = map['accessKey'] as String?;
      if (accessKey == null) {
        return null;
      }

      final secretKey = map['secretKey'] as String?;
      if (secretKey == null) {
        return null;
      }

      final bucket = map['bucket'] as String?;
      if (bucket == null) {
        return null;
      }

      final port = map['port'] as int? ?? _defaultPort;
      final useSSL = map['useSSL'] as bool? ?? _defaultUseSSL;

      return MinioConfigModel._(
        endpoint: endpoint,
        port: port,
        accessKey: accessKey,
        secretKey: secretKey,
        bucket: bucket,
        useSSL: useSSL,
      );
    } catch (e) {
      // Type casting error or other parsing error
      return null;
    }
  }

  /// Get the MinIO configuration from the ConfigManager
  ///
  /// Returns null if any required configuration is missing
  static MinioConfigModel? getFromConfigManager(
      {required MixinMinioConfig configManager, LogsHelper? logsHelper}) {
    try {
      return configManager.minioConfig.load();
    } catch (e) {
      logsHelper?.f('MinioConfigModel: Failed to load configuration: $e');
      return null;
    }
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
      ];
}
