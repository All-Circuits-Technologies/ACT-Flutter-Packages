// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_manager/src/abstract_halo_manager.dart';

/// Defines the abstract for all HALO features
abstract class AbstractHaloFeature<MaterialType> {
  /// The expected HALO manager config
  final HaloManagerConfig<MaterialType> haloManagerConfig;

  /// Class constructor
  AbstractHaloFeature({required this.haloManagerConfig});
}
