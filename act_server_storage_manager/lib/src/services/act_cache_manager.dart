// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Extends the [CacheManager] with the [ImageCacheManager] mixin
///
/// Which allow to manage images in cache
class ActCacheManager extends CacheManager with ImageCacheManager {
  /// Class constructor
  ActCacheManager(super.config);
}
