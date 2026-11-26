// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';

/// This mixin has to be applied in the ConfigManager of the main app and provides configuration
/// for the storage manager.
mixin MixinStorageConfig on AbstractConfigManager {
  /// Allows to override the storage manager cache size
  final storageCacheNumberOfObjectsCached = const NotNullableConfigVar<int>(
    'storage.cache.numberOfObjectsCached',
    defaultValue: 100,
  );

  /// Allows to override the storage manager default path separator
  final storagePathSeparator = const NotNullableConfigVar<String>(
    "storage.pathSeparator",
    defaultValue: UriUtility.pathSeparator,
  );

  /// Allows to override the storage manager stale period
  final storageCacheStalePeriodConf = const NotNullParserConfigVar<Duration, int>(
    'storage.cache.stalePeriod',
    defaultValue: Duration(days: 14),
    parser: _parseDuration,
  );

  /// This is the parse method for the cache duration
  static Duration _parseDuration(int days) => Duration(days: days);

  /// Allows to override the storage manager cache key
  final storageCacheKeyConf = const NotNullableConfigVar<String>(
    'storage.cache.key',
    defaultValue: 'act_cache_manager',
  );

  /// Allows to set if the storage manager should use the cache
  final storageCacheUseConf = const NotNullableConfigVar<bool>(
    'storage.cache.use',
    defaultValue: false,
  );
}
