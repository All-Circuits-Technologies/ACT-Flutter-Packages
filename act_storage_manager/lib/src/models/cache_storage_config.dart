// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// Configuration for the cache storage.
class CacheStorageConfig extends Equatable {
  /// Default cache key for the cache. You must provide a cache key when you want to use
  /// multiple caches at the same time
  static const String defaultCache = 'act_cache_manager';

  /// Default stale period for the cache.
  static const Duration defaultStalePeriod = Duration(days: 14);

  /// Default maximum number of objects to store in the cache.
  static const int defaultMaxNbOfCacheObjects = 100;

  /// Key to identify the cache, required to identify which cache to use.
  final String cacheKey;

  /// Duration after which the cached element is considered stale.
  final Duration stalePeriod;

  /// Maximum number of objects to store in the cache.
  final int maxNbOfCacheObjects;

  /// Constructor for [CacheStorageConfig].
  const CacheStorageConfig({
    this.cacheKey = defaultCache,
    this.stalePeriod = defaultStalePeriod,
    this.maxNbOfCacheObjects = defaultMaxNbOfCacheObjects,
  });

  /// Get the properties of the object.
  @override
  List<Object?> get props => [
        cacheKey,
        stalePeriod,
        maxNbOfCacheObjects,
      ];
}
